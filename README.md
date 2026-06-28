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

Ruby 3.3 · Rails 8 (API) · PostgreSQL · Redis · RSpec · FactoryBot

## Setup

Requires Ruby 3.3+ and Docker.

```bash
source activate          # Ruby 3.3 via rbenv (this project only)
cp .env.example .env     # set VPNAPI_KEY if you want real VPNAPI calls

docker compose up -d
bundle install
bin/rails db:create db:migrate db:seed   # seed loads the country whitelist
```

## Run

```bash
source activate
bin/rails server
```

## Tests

```bash
source activate
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
```

Expected response: `{ "ban_status": "not_banned" }` or `{ "ban_status": "banned" }`.

## Env vars

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL |
| `REDIS_URL` | Redis |
| `VPNAPI_KEY` | VPNAPI key ([docs](https://vpnapi.io/api-documentation)) |
