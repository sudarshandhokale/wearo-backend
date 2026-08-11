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
