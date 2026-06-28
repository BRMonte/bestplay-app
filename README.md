# Bestplay App

Rails 8 API-only application for user integrity checks (`POST /v1/user/check_status`).

## Stack

- Ruby on Rails 8 (API only)
- PostgreSQL
- Redis
- RSpec + FactoryBot

## Prerequisites

- Ruby 3.3+
- Docker (recommended for PostgreSQL and Redis)

## Setup

```bash
cp .env.example .env
docker compose up -d
bundle install
bin/rails db:create db:migrate
```

## Running

```bash
bin/rails server
```

## Testing

```bash
bundle exec rspec
```

## Environment Variables

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection URL |
| `REDIS_URL` | Redis connection URL |
| `VPNAPI_KEY` | API key for [VPNAPI](https://vpnapi.io/api-documentation) |

## Project Requirements (not implemented yet)

- `POST /v1/user/check_status` endpoint
- Security checks: CF-IPCountry whitelist (Redis), rooted device, VPN/Tor (VPNAPI)
- Models: `User`, `IntegrityLog`
- Integrity logger service (future-proof routing)

## Link to GitHub

```bash
git init -b main
git remote add origin https://github.com/BRMonte/bestplay-app.git
git add .
git commit -m "Initial Rails 8 API setup"
git push -u origin main
```
