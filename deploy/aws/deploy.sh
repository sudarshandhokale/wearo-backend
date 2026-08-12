#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/../.."

ENV_FILE="${ENV_FILE:-.env.production}"
COMPOSE_FILE="deploy/aws/docker-compose.yml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Create it from deploy/aws/environment.example." >&2
  exit 1
fi

if [[ "$(stat -c '%a' "$ENV_FILE")" != "600" ]]; then
  echo "$ENV_FILE must have permissions 600." >&2
  exit 1
fi

ENV_FILE="$(realpath "$ENV_FILE")"
export APP_ENV_FILE="$ENV_FILE"
compose=(docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE")

git fetch origin main
git checkout --quiet main
git pull --ff-only origin main

"${compose[@]}" config --quiet
"${compose[@]}" build --pull web
"${compose[@]}" up -d postgres redis
"${compose[@]}" run --rm web ./bin/rails db:prepare
"${compose[@]}" up -d --remove-orphans web worker caddy
"${compose[@]}" exec -T web ./bin/rails runner \
  'abort "Deployment readiness check failed" unless Rails.application.config.eager_load'
"${compose[@]}" ps

echo "Deployment complete: https://$(sed -n 's/^API_DOMAIN=//p' "$ENV_FILE" | tail -1)/api/v1/health/readiness"
