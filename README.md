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
GET    /api/v1/me
PATCH  /api/v1/me
```

Auth endpoints follow the SAFEGO-style response convention:

```json
{
  "success": true,
  "data": {},
  "meta": null
}
```

Successful register, login, and refresh responses include the JWT in the
`Authorization` response header.

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
GET /api/v1/outfits/:id
```

Outfits persist a recommendation context, score, explanation, and ordered links
to the current user's clothing items. Outfit creation remains internal until the
recommendation endpoint is introduced in Milestone 6.

Stylist recommendations:

```text
POST /api/v1/stylist/recommendations
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
