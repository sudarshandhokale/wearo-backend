# WEARO Backend

Rails API backend for WEARO, a consumer AI personal stylist application.

This repository starts as a clean Rails application and ports only generic
infrastructure patterns from SAFEGO. SAFEGO school transport domain code is not
part of this application.

## Stack

- Ruby 3.3.6
- Rails 8 API
- PostgreSQL
- Active Storage
- Private S3 storage in production
- Redis
- Sidekiq
- RSpec
- RuboCop
- Brakeman

## Local Setup

```sh
bundle install
bin/rails db:create db:migrate
bin/rails server
```

Run the test suite:

```sh
RAILS_ENV=test bin/rails db:create db:migrate
bundle exec rspec
```

Run linting and security scan:

```sh
bundle exec rubocop
bundle exec brakeman --no-pager
```

## API

Health check:

```text
GET /api/v1/health
```

Metadata:

```text
GET /api/v1/metadata
```

Returns ISO country selections and style profile option lists for clients.
`preferred_city` is free text in Phase 1.

Authentication:

```text
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
DELETE /api/v1/auth/logout
POST   /api/v1/auth/confirmations
POST   /api/v1/auth/confirmations/verify
POST   /api/v1/auth/password/forgot
POST   /api/v1/auth/password/reset
GET    /api/v1/me
PATCH  /api/v1/me
PATCH  /api/v1/me/consents
GET    /api/v1/me/export
DELETE /api/v1/me
```

Auth endpoints follow the SAFEGO-style response convention:

```json
{
  "success": true,
  "data": {},
  "meta": null
}
```

Registration requires acceptance of the current terms, privacy policy, AI
processing, and an adult-age confirmation. It sends a confirmation email but
does not issue a JWT. Email verification issues the first JWT; subsequent login
and refresh responses include the JWT in the `Authorization` response header.
Password recovery and confirmation resend responses do not reveal whether an
email is registered.

Account deletion requires the current password and the exact confirmation value
`DELETE`. It removes the account's relational data and queues private Active
Storage files for deletion.

The export endpoint downloads a JSON copy of profile, style, wardrobe metadata,
outfits, wear history, feedback, plans, recommendation history, and AI usage.
Image entries contain authenticated media URLs and can be downloaded separately.

Clothing items:

```text
GET    /api/v1/clothing_items
POST   /api/v1/clothing_items
GET    /api/v1/clothing_items/:id
PATCH  /api/v1/clothing_items/:id
DELETE /api/v1/clothing_items/:id
POST   /api/v1/clothing_items/:id/reanalyze
```

Clothing item images are attached through Active Storage. Image responses return
a signed blob id and a Rails storage proxy path. Exact duplicate image files are
rejected within a user's active wardrobe; discarded items do not block re-upload.

Image uploads and `reanalyze` requests enqueue `AnalyzeClothingItemJob`. The job
uses the OpenAI Responses API with strict structured output, normalizes the result,
and moves the item from `processing` to `ready` or `analysis_failed`.

Configure clothing analysis locally with:

```text
OPENAI_API_KEY=...
OPENAI_CLOTHING_MODEL=gpt-5.6-luna
```

Development uses the in-process Active Job async adapter. Production sends the
`clothing_analysis` queue to Sidekiq.

Outfits:

```text
GET   /api/v1/outfits
GET   /api/v1/outfits/:id
PATCH /api/v1/outfits/:id
```

Outfits persist recommendation context, score breakdown, explanation, ordered
clothing items, and optional user feedback. Feedback updates accept `status`
(`recommended`, `saved`, `worn`, or `dismissed`), `rating` from 1 to 5, and a
short `feedback_note`.

Stylist recommendations:

```text
POST /api/v1/stylist/recommendations
GET  /api/v1/recommendation_requests
GET  /api/v1/recommendation_requests/:id
GET  /api/v1/ai/usage
```

```json
{
  "prompt": "I have a casual dinner with friends tonight"
}
```

The stylist extracts context, selects only ready items from the current user's
wardrobe, builds bounded combinations, applies weighted compatibility scoring,
and sends at most 30 compact candidates to the configured OpenAI model for final
ranking. Up to three outfits are persisted and returned. When the provider is not
configured or temporarily unavailable, deterministic scoring remains available.

Each stylist call creates a user-owned recommendation request that groups its
outfits and stores the prompt, extracted context, wardrobe suggestions, ranking
source, provider/model identifiers, retry count, token usage, completion state,
and sanitized failure code. Raw provider responses are not stored.

Both clothing analysis and stylist ranking create `AiRequest` accounting records.
Calls reserve capacity before contacting the provider, retry transient `429` and
`5xx` failures up to three attempts, and release the reservation on completion.
Limits reset according to the user's local date and are configurable with:

```text
AI_DAILY_TOKEN_LIMIT=50000
AI_DAILY_REQUEST_LIMIT=100
STYLIST_DAILY_RECOMMENDATION_LIMIT=50
```

OpenAI requests use `store: false`, strict schemas, pseudonymous safety identifiers,
HTTPS-only endpoints, bounded payloads, and server-validated candidate IDs.
The stylist model never receives the raw user prompt; it receives only
server-derived occasion, formality, activity, and season values. Clothing-model
text and tags are bounded and checked before persistence, and only normalized
metadata is eligible for later ranking. Unsafe or injected explanations are
discarded and deterministic ranking is used instead.

A recommendation needs either a top and bottom or one ready one-piece garment
such as a dress, jumpsuit, or romper, or a complete set such as a co-ord, suit,
or traditional set. Shoes, outerwear, and accessories are optional. Missing
optional roles are returned as localized wardrobe suggestions without blocking
available recommendations. Taxonomy and recommendation rules are garment-driven
and do not require a gender classification on the user.

Indian traditional clothing supports both complete ensembles and individual
pieces. Complete saree, lehenga, salwar, kurta, sherwani, and anarkali ensembles
use the `set` category. Individual sarees use `drape` and combine with a blouse
or choli in `top`; kurtas combine with salwar, churidar, pajama, dhoti, palazzo,
or lehenga pieces. Dupattas, traditional footwear, and jewelry remain optional.

Global garments use universal composition categories plus open metadata. The
`garment_type` field preserves a local name such as `hanbok`, `abaya`, or `kilt`,
and `cultural_tags` preserves descriptors without requiring a country-specific
closed list. Every category includes an `other` subtype so unfamiliar garments
remain editable and usable instead of failing analysis.

## Production Deployment

Use `example.env` as the deployment configuration reference. Production boot
fails when database, Redis, host, HTTPS frontend, CORS, policy URLs, OpenAI,
private S3, SMTP, or JWT settings are missing.

For the single-instance AWS preview deployment, see
[`docs/AWS_EC2_DEPLOYMENT.md`](docs/AWS_EC2_DEPLOYMENT.md). It runs Rails,
Sidekiq, PostgreSQL, Redis, and Caddy on one EC2 host while deploying the Expo
web frontend independently through AWS Amplify Hosting.

Run separate web and worker processes:

```sh
bundle exec rails server -b 0.0.0.0
bundle exec sidekiq -C config/sidekiq.yml
```

Run database preparation during release:

```sh
bundle exec rails db:prepare
```

Schedule retention cleanup daily with the hosting provider:

```sh
bundle exec rails runner "DataRetentionCleanupJob.perform_later"
```

Health endpoints:

```text
GET /api/v1/health
GET /api/v1/health/readiness
```

Readiness checks PostgreSQL, Redis, and production storage configuration. Rack
Attack limits authentication, registration, recovery email, uploads,
recommendations, and visualizations. Enable provider-level WAF and rate limiting
at the public edge as an additional layer.
