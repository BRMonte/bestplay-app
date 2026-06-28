# Bestplay App

Rails 8 API-only app. One job: receive a device check, run security rules, return `ban_status`.

## What the spec asks for

`POST /v1/user/check_status` accepts `idfa` + `rooted_device` and returns `{ "ban_status": "banned" | "not_banned" }`.

Three checks, in order:

1. **Country** — `CF-IPCountry` header must be in the Redis whitelist
2. **Root** — `rooted_device: true` → ban
3. **VPN/Tor** — calls [VPNAPI](https://vpnapi.io/api-documentation); 24h Redis cache; if the API fails, the check **passes**

Persistence rules:

- New user → create; existing user → update
- Already `banned` → skip checks, return `banned`
- `not_banned` → re-run checks on every request
- `IntegrityLog` only when a user is created **or** `ban_status` changes

## Flow

```
POST /v1/user/check_status
        │
        ▼
CheckStatusController          ← validates params, resolves IP/country
        │
        ▼
CheckStatusService             ← orchestrates lookup, checks, persist, log
        │
        ├─ User (PG)            ← early exit if already banned
        │
        ├─ Checks::CountryWhitelist   ← Redis SET
        ├─ Checks::RootedDevice
        └─ Checks::VpnTor             ← VpnApiClient → VPNAPI / Redis cache
        │
        ├─ User upsert (PG, transaction)
        └─ IntegrityLogger → DatabaseIntegrityLogSink → IntegrityLog
```

**How the pieces fit**

| Piece | Role |
|---|---|
| `CheckStatusParams` | Validates body; 422 on invalid input |
| `ClientIp` | Real client IP via `CF-Connecting-IP` |
| `CheckStatusService` | Service object — single entry point for business logic |
| `Checks::*` | Strategy: one class per rule, `{ banned:, ... }` interface |
| `VpnApiClient` | HTTP adapter + cache |
| `IntegrityLogger` + `DatabaseIntegrityLogSink` | Pluggable log sink (PostgreSQL today) |

## Practices in place

| Practice | Why it matters |
|---|---|
| Short-circuit (banned → skip checks) | Less I/O per request |
| Cheap checks before external HTTP | VPNAPI only when needed |
| 24h VPNAPI cache | Lower latency, fewer rate-limit hits |
| Fail-open on VPNAPI errors | Stays up when the API is down (per spec) |
| Redis connection pool | Puma threads don't share one connection |
| Shared Faraday + 2s timeout | Keep-alive; threads don't hang forever |
| Transaction (user + log) | Ban status and audit trail stay in sync |
| `find_or_create_by!` on IDFA | Concurrent creates don't 500 |
| Conditional logging | No extra DB write on every poll |

## Stack

Ruby 3.3+ · Rails 8 (API) · PostgreSQL · Redis · RSpec · FactoryBot

## Setup

Requires Ruby 3.3+ (see `.ruby-version`), Docker, and Bundler.

```bash
cp .env.example .env
docker compose up -d
bundle install
bin/rails db:create db:migrate db:seed
```

`.env.example` defaults match `docker compose` (PostgreSQL on port 5433, Redis on 6380).

Country whitelist lives in Redis (`country_whitelist` key), loaded by `db:seed`.

## VPNAPI key

Required for the VPN/Tor check. Country and rooted-device checks work without it.

1. Create a free account at [vpnapi.io](https://vpnapi.io)
2. Open the [dashboard](https://vpnapi.io/dashboard)
3. Copy your API key
4. Set it in `.env`:

```bash
VPNAPI_KEY=your_key_here
```

Free tier: ~1,000 requests/day. Responses are cached in Redis for 24h per IP.

If the API is unreachable or returns an error, the VPN/Tor check **passes** (fail-open, per spec). A missing `VPNAPI_KEY` will raise an error when that check runs.

## Run

```bash
bin/rails server
```

## Tests

```bash
bundle exec rspec
```

## Manual test

With the server on `localhost:3000`:

```bash
# pass — US whitelisted, clean device
curl -s -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: US" \
  -H "CF-Connecting-IP: 203.0.113.10" \
  -d '{"idfa":"8264148c-be95-4b2b-b260-6ee98dd53bf6","rooted_device":false}'

# ban — country not whitelisted
curl -s -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: RU" \
  -H "CF-Connecting-IP: 203.0.113.10" \
  -d '{"idfa":"8264148c-be95-4b2b-b260-6ee98dd53bf6","rooted_device":false}'

# ban — rooted device
curl -s -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: US" \
  -H "CF-Connecting-IP: 203.0.113.10" \
  -d '{"idfa":"8264148c-be95-4b2b-b260-6ee98dd53bf6","rooted_device":true}'

# ban — VPN detected (requires VPNAPI_KEY; 1.1.1.1 flagged as VPN by VPNAPI)
curl -s -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: US" \
  -H "CF-Connecting-IP: 1.1.1.1" \
  -d '{"idfa":"22222222-2222-2222-2222-222222222222","rooted_device":false}'
```

Expected response: `{ "ban_status": "not_banned" }` or `{ "ban_status": "banned" }`.

## Environment

Copy `.env.example` to `.env`. Variables used by the app:

| Variable | Required | Description |
|---|---|---|
| `DB_HOST` | yes | PostgreSQL host (`config/database.yml`) |
| `DB_PORT` | yes | PostgreSQL port |
| `DB_USERNAME` | yes | PostgreSQL user |
| `DB_PASSWORD` | yes | PostgreSQL password |
| `REDIS_URL` | yes | Redis connection URL |
| `VPNAPI_KEY` | for VPN check | API key from [vpnapi.io/dashboard](https://vpnapi.io/dashboard) |
| `DATABASE_URL` | optional | Rails merges this if set; defaults in `.env.example` match the `DB_*` vars above |

Do not commit `.env`.
