# Bestplay App

Rails 8 API-only app. One job: receive a device check, run security rules, return `ban_status`.

## O que o PDF pede

`POST /v1/user/check_status` recebe `idfa` + `rooted_device` e responde `{ "ban_status": "banned" | "not_banned" }`.

Três checks, nesta ordem:

1. **País** — header `CF-IPCountry` precisa estar na whitelist (Redis)
2. **Root** — `rooted_device: true` → ban
3. **VPN/Tor** — consulta [VPNAPI](https://vpnapi.io/api-documentation); cache Redis 24h; se a API falhar, o check **passa**

Regras de persistência:

- User novo → cria; existente → atualiza
- User já `banned` → pula checks, retorna `banned`
- User `not_banned` → re-roda checks a cada request
- `IntegrityLog` só quando user é criado **ou** `ban_status` muda

## Fluxo

```
POST /v1/user/check_status
        │
        ▼
CheckStatusController          ← valida params, resolve IP/country
        │
        ▼
CheckStatusService             ← orquestra lookup, checks, persist, log
        │
        ├─ User (PG)            ← early exit se já banned
        │
        ├─ Checks::CountryWhitelist   ← Redis SET
        ├─ Checks::RootedDevice
        └─ Checks::VpnTor             ← VpnApiClient → VPNAPI / cache Redis
        │
        ├─ User upsert (PG, transaction)
        └─ IntegrityLogger → DatabaseIntegrityLogSink → IntegrityLog
```

**Como as peças se encaixam**

| Peça | Papel |
|---|---|
| `CheckStatusParams` | Valida body; 422 se inválido |
| `ClientIp` | IP real via `CF-Connecting-IP` |
| `CheckStatusService` | Service object — único entry point da lógica |
| `Checks::*` | Strategy: uma classe por regra, interface `{ banned:, ... }` |
| `VpnApiClient` | Adapter HTTP + cache |
| `IntegrityLogger` + `DatabaseIntegrityLogSink` | Log com sink trocável (hoje PG) |

## Boas práticas aplicadas

| Prática | Valor |
|---|---|
| Short-circuit (banido → skip checks) | Menos I/O por request |
| Checks baratos antes do HTTP externo | VPNAPI só quando necessário |
| Cache VPNAPI 24h | Menos latência e rate limit |
| Fail-open na VPNAPI | Disponibilidade quando API cai (spec do PDF) |
| Redis connection pool | Threads Puma não brigam por conexão |
| Faraday compartilhado + timeout 2s | Keep-alive; thread não trava |
| Transaction user + log | Ban e audit trail ficam consistentes |
| `find_or_create_by!` no IDFA | Race de create não vira 500 |
| Log condicional | Sem write desnecessário a cada poll |

## Stack

Ruby 3.3 · Rails 8 (API) · PostgreSQL · Redis · RSpec · FactoryBot

## Setup

Requisitos: Ruby 3.3+, Docker.

```bash
source activate          # usa Ruby 3.3 via rbenv (só neste projeto)
cp .env.example .env     # ajuste VPNAPI_KEY se quiser testar VPNAPI real

docker compose up -d
bundle install
bin/rails db:create db:migrate db:seed   # seed popula country whitelist
```

## Rodar

```bash
source activate
bin/rails server
```

## Testes

```bash
source activate
bundle exec rspec
```

## Teste manual

Com o server rodando (`localhost:3000`):

```bash
# passa — US na whitelist, device limpo
curl -s -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: US" \
  -H "CF-Connecting-IP: 203.0.113.10" \
  -d '{"idfa":"8264148c-be95-4b2b-b260-6ee98dd53bf6","rooted_device":false}'

# ban — país fora da whitelist
curl -s -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: RU" \
  -H "CF-Connecting-IP: 203.0.113.10" \
  -d '{"idfa":"8264148c-be95-4b2b-b260-6ee98dd53bf6","rooted_device":false}'

# ban — device rootado
curl -s -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: US" \
  -H "CF-Connecting-IP: 203.0.113.10" \
  -d '{"idfa":"8264148c-be95-4b2b-b260-6ee98dd53bf6","rooted_device":true}'
```

Resposta esperada: `{ "ban_status": "not_banned" }` ou `{ "ban_status": "banned" }`.

## Env vars

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL |
| `REDIS_URL` | Redis |
| `VPNAPI_KEY` | Chave VPNAPI ([docs](https://vpnapi.io/api-documentation)) |
