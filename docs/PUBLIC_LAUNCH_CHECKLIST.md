# WEARO Public Launch Checklist

## Application

- [x] Email confirmation before login
- [x] Generic password recovery responses and one-time reset tokens
- [x] Password changes invalidate existing JWTs
- [x] Terms, privacy, adult confirmation, and AI processing consent records
- [x] Separate consent for full-body image upload
- [x] Account data export and complete account deletion
- [x] Authenticated ownership checks for private media
- [x] API throttling and request body limit
- [x] AI request/token limits, retries, guardrails, and failure fallbacks
- [x] Abandoned account and failed visualization cleanup job
- [x] Database, Redis, storage, and worker readiness checks
- [x] Production configuration validation

## Deployment Provider

- [ ] Deploy separate web and Sidekiq worker services
- [ ] Run `rails db:prepare` as the release command
- [ ] Schedule `DataRetentionCleanupJob` daily
- [ ] Configure managed PostgreSQL with automated backups and test one restore
- [ ] Configure managed Redis with authentication and private networking
- [ ] Configure a private S3 bucket with encryption, blocked public access, and lifecycle rules
- [ ] Configure HTTPS, DNS, allowed host, and exact CORS origins
- [ ] Enable provider-level WAF and rate limiting
- [ ] Configure centralized logs, alerts, and error monitoring
- [ ] Configure uptime checks for `/api/v1/health` and `/api/v1/health/readiness`

## Email And AI

- [ ] Verify the sending domain with SPF, DKIM, and DMARC
- [ ] Test confirmation and password reset delivery outside the development domain
- [ ] Use a dedicated OpenAI project and restricted backend-only API key
- [ ] Set OpenAI project budget and usage alerts
- [ ] Confirm intended OpenAI API data controls and region for target users
- [ ] Run real-image quality and safety tests for analysis and try-on

## Legal And Product

- [ ] Publish reviewed Terms and Privacy pages at `TERMS_URL` and `PRIVACY_URL`
- [ ] Describe OpenAI processing, image retention, generated-image limitations, and deletion
- [ ] Provide a monitored privacy/support contact
- [ ] Confirm the adult-only release rule is appropriate for every launch market
- [ ] Add an AI-generated-image disclosure in the frontend
- [ ] Complete frontend flows for confirmation, recovery, consent refresh, export, and deletion
- [ ] Run the documented real-device smoke test against production

Do not announce general availability until every unchecked item has an owner and
the deployment-specific security controls have been verified in the live environment.
