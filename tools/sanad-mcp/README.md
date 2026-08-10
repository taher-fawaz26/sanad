# SANAD API MCP — Development Tool

Authenticated MCP server for Claude Code to access the SANAD backend API.

**Scope**: Development tool only. Never imported by Flutter. Never part of `packages/network`.

## Setup

### 1. Install dependencies

```bash
cd tools/sanad-mcp
npm install
```

### 2. Create credentials file

```bash
cp .env.example .env
# Edit .env — add real SANAD_DEV_EMAIL and SANAD_DEV_PASSWORD
```

The `.env` file is gitignored. Never commit credentials.

### 3. Start Claude Code from project root

The `.mcp.json` at the project root automatically starts the MCP server.
Claude Code picks it up at launch — no manual `node` command needed.

## How it works

```
Claude Code
    │
    ▼
SANAD MCP (tools/sanad-mcp/src/index.mjs)
    │
    ├── loads live OpenAPI spec from https://dev-api.trysanad.us/api/docs-json
    │   (no auth required — Referer header is sufficient)
    │
    └── SanadAuthProvider
            ├── reads SANAD_DEV_EMAIL / SANAD_DEV_OTP from .env
            ├── POST /auth/login → { email }
            ├── POST /auth/login/verify → { email, otp } → { accessToken, refreshToken, status }
            │   (tokens are only populated when status === "ACTIVE")
            ├── caches tokens in process memory only
            ├── refreshes before expiry (JWT exp - 60s)
            └── attaches Authorization: Bearer <accessToken> to every API call
```

## Safety controls

By default only **GET** endpoints are exposed as MCP tools (read-only mode).

To also expose mutating endpoints (POST/PUT/PATCH/DELETE):

```bash
SANAD_MCP_ALLOW_MUTATIONS=true node tools/sanad-mcp/src/index.mjs
```

Or add `"SANAD_MCP_ALLOW_MUTATIONS": "true"` to the `env` block in `.mcp.json`.

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `SANAD_DEV_EMAIL` | Yes | Dev account email (OTP login) |
| `SANAD_DEV_OTP` | No | Fixed dev/CI OTP, defaults to `055555` |
| `SANAD_MCP_ALLOW_MUTATIONS` | No | Set to `true` to expose POST/PUT/PATCH/DELETE |

## API base URL

`https://dev-api.trysanad.us/api/v1`

## OpenAPI spec

Live: `https://dev-api.trysanad.us/api/docs-json` (200 with Referer header)

## Token lifecycle

1. First call: `POST /api/v1/auth/login` then `POST /api/v1/auth/login/verify` → if `status === "ACTIVE"`, cache accessToken + refreshToken in memory
2. Subsequent calls: return cached token if not expired
3. Near expiry (JWT exp - 60s): `POST /api/v1/auth/refresh` automatically
4. On 401: attempt refresh → if fails, attempt re-login → retry original request

## Sample Claude Code prompts

```
Call GET /api/v1/branches and show me the full response.

Inspect GET /api/v1/workers?type=manager and compare the response with Flutter's BranchManagerEntity.

Show the schema for POST /api/v1/branches and compare it with CreateBranchRequest.toMap().

Call GET /api/v1/profile/availability and compare the response with BranchAvailabilityEntity.
```
