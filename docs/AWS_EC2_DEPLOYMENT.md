# AWS EC2 Preview Deployment

This deployment runs Rails, Sidekiq, PostgreSQL, Redis, and Caddy on one EC2
instance. It is suitable for a controlled preview, not a highly available
production deployment. All four application services fail together if the
instance or Availability Zone fails.

## Architecture

- Caddy exposes ports 80 and 443 and provisions the API TLS certificate.
- Rails and Sidekiq use the same immutable application image.
- PostgreSQL and Redis use named Docker volumes on the EC2 EBS disk.
- PostgreSQL and Redis are not published to the internet.
- Active Storage uses a private S3 bucket.
- Amazon SES or Gmail app-password SMTP sends account email.
- Expo Web should deploy separately to AWS Amplify Hosting.

The lockfile supports both `x86_64-linux` and `aarch64-linux`. Start with
`t4g.medium` (AWS Graviton, 4 GiB RAM) for lower cost or `t3.medium` when x86 is
required. A 2 GiB instance can work for very light preview traffic, but Rails,
Sidekiq, image processing, PostgreSQL, and Redis can exhaust it together.

## 1. Create AWS Resources

1. Allocate an Elastic IP and attach it to the EC2 instance.
2. Create an Ubuntu 24.04 EC2 instance with at least 30 GiB encrypted gp3 EBS.
3. Allow inbound TCP 80 and 443 from the internet.
4. Allow inbound TCP 22 only from the administrator's fixed IP.
5. Do not open ports 3000, 5432, or 6379.
6. Point `api.example.com` to the Elastic IP with a Route 53 A record.
7. Create a private S3 bucket with Block Public Access and default encryption.
8. Attach an EC2 IAM role granting only required access to that bucket.
9. Configure email. For SES, verify the sending domain and request production
   access when needed. For Gmail, enable 2-step verification and create an app
   password for SMTP.

Set the EC2 instance metadata response hop limit to `2` so the AWS SDK inside
Docker can obtain credentials from the instance role. Keep IMDSv2 required.

The instance role needs `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, and
`s3:ListBucket` for the application bucket. Do not store long-lived AWS access
keys on EC2 when an instance role can be used.

## 2. Prepare The Instance

Copy the bootstrap script to the instance and run:

```sh
sudo bash bootstrap-ubuntu.sh
```

Sign out and back in, then clone the private backend repository. Use a read-only
GitHub deploy key on the EC2 instance:

```sh
git clone git@github.com:YOUR_ORG/wearo-backend.git /opt/wearo-backend
cd /opt/wearo-backend
cp deploy/aws/environment.example .env.production
chmod 600 .env.production
```

Fill every value in `.env.production`. Generate URL-safe secrets, for example:

```sh
openssl rand -hex 32
```

`POSTGRES_PASSWORD` must remain URL-safe because it is interpolated into
`DATABASE_URL`. `RAILS_MASTER_KEY` comes from the local backend
`config/master.key`; never commit that key.

For a small public preview, keep AI image generation limits conservative:

```text
AI_DAILY_TOKEN_LIMIT=50000
AI_DAILY_REQUEST_LIMIT=30
STYLIST_DAILY_RECOMMENDATION_LIMIT=15
VISUALIZATION_DAILY_LIMIT=3
TRY_ON_VISUALIZATION_DAILY_LIMIT=1
AUTO_FLAT_LAY_VISUALIZATION_DAILY_LIMIT=30
```

`TRY_ON_VISUALIZATION_DAILY_LIMIT` is intentionally separate because try-on is
the most expensive and privacy-sensitive visualization mode.

If you use an EC2 IAM role for S3 access, leave `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` empty in `.env.production`.

For Gmail SMTP preview email, set:

```text
MAILER_FROM=your-full-gmail-address@gmail.com
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-full-gmail-address@gmail.com
SMTP_PASSWORD=your-16-character-gmail-app-password
SMTP_DOMAIN=gmail.com
```

Use a Google app password, not your normal Google account password. The Gmail
account must have 2-step verification enabled before app passwords are
available.

## 3. Deploy

```sh
./deploy/aws/deploy.sh
```

Verify both endpoints:

```sh
curl https://api.example.com/api/v1/health
curl https://api.example.com/api/v1/health/readiness
```

The readiness endpoint must report database, Redis, S3 configuration, and a
Sidekiq process as `ok`.

## 4. Configure GitHub Deployment

Create a GitHub `production` environment with approval protection and these
repository or environment secrets:

- `AWS_EC2_HOST`: Elastic IP or API hostname.
- `AWS_EC2_USER`: usually `ubuntu`.
- `AWS_EC2_SSH_PRIVATE_KEY`: private key authorized by the EC2 deploy user.
- `AWS_EC2_KNOWN_HOSTS`: output from `ssh-keyscan -H api.example.com`, verified
  against the host fingerprint before storing it.

After `CI` succeeds on `main`, `Deploy AWS` connects over SSH and runs the
deployment script. The EC2 deploy user also needs a separate read-only GitHub
deploy key so `git pull` can access the private repository.

## 5. Deploy The Frontend Separately

Connect the separate `wearo-frontend` repository to AWS Amplify Hosting. Use:

```text
Build command: pnpm build:web
Output directory: dist
Environment: EXPO_PUBLIC_API_BASE_URL=https://api.example.com
```

The frontend repository includes `amplify.yml` with these build settings. In
Amplify, add a rewrite from `/<*>` to `/index.html` with status `200` so browser
refreshes continue to load the Expo single-page application.

Set the Amplify custom domain to `app.example.com`. Then set the backend values:

```text
FRONTEND_URL=https://app.example.com
CORS_ORIGINS=https://app.example.com
TERMS_URL=https://app.example.com/terms
PRIVACY_URL=https://app.example.com/privacy
```

Native Expo/EAS builds use the same `EXPO_PUBLIC_API_BASE_URL`. They are
distributed through TestFlight, Google Play testing, or Expo internal
distribution rather than hosted on EC2.

SES accounts begin in the sandbox. Until AWS grants production access, sender
and recipient addresses must be verified, which is sufficient only for a small
controlled preview. Gmail SMTP can be used for preview email, but use a Gmail
app password rather than the account password.

## Operations

Configure AWS Budget alerts before deployment. Enable daily EBS snapshots with
AWS Backup and regularly test PostgreSQL restore procedures. An EBS snapshot is
not a substitute for a database backup; add encrypted daily `pg_dump` backups to
a separate private S3 prefix before public launch.

Useful commands:

```sh
docker compose --env-file .env.production -f deploy/aws/docker-compose.yml ps
docker compose --env-file .env.production -f deploy/aws/docker-compose.yml logs -f web worker
docker compose --env-file .env.production -f deploy/aws/docker-compose.yml exec web bin/rails console
docker compose --env-file .env.production -f deploy/aws/docker-compose.yml exec postgres \
  pg_dump -U wearo -d wearo_production --format=custom > wearo.dump
```

Do not use `docker compose down --volumes` in production; it deletes the local
PostgreSQL and Redis volumes.
