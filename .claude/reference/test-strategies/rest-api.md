# Test Strategy: REST API / Backend

## Detection Signals

The onboarding system (`/onboard`) auto-detects a REST API / backend project
when:

- **Node.js / Express / Fastify:**
  - `package.json` contains `express`, `fastify`, `koa`, `hapi`, or `@hapi/hapi`.
  - No frontend framework (`react`, `vue`, `svelte`, etc.) in dependencies,
    OR the project is structured as a monorepo with clear `server/` or `api/`
    separation.
  - Entry point (`index.js`, `server.js`, `app.js`) starts an HTTP server
    (calls `app.listen` or `server.listen`).

- **Python / FastAPI / Django / Flask:**
  - `requirements.txt`, `pyproject.toml`, or `setup.cfg` contains `fastapi`,
    `django`, `flask`, `sanic`, or `litestar`.
  - Entry point starts an ASGI/WSGI server (uvicorn, gunicorn, daphne).

- **Go / Gin / Echo / Chi:**
  - `go.mod` contains `gin-gonic/gin`, `labstack/echo`, `go-chi/chi`,
    `gorilla/mux`, or `fiber`.
  - `main.go` starts an HTTP server with `http.ListenAndServe` or framework
    equivalent.

- **Rust / Actix / Axum / Rocket:**
  - `Cargo.toml` contains `actix-web`, `axum`, `rocket`, or `warp`.
  - `main.rs` starts a server.

- **General signals:**
  - OpenAPI/Swagger spec files present (`openapi.yaml`, `swagger.json`).
  - `specs/api/` directory contains `.yaml` or `.yml` files.
  - Routes or controllers directory exists (`routes/`, `controllers/`,
    `handlers/`, `endpoints/`).

---

## Smoke Test Checklist

Smoke tests are quick sanity checks to verify the API is operational.

- [ ] Server starts without errors (exit code 0).
  - Node: `node server.js` or `npm start` binds to port.
  - Python: `uvicorn main:app` or `python manage.py runserver`.
  - Go: `go run main.go` or compiled binary.
  - Rust: `cargo run` or compiled binary.
- [ ] Health endpoint (`GET /health`, `/healthz`, or `/api/health`) returns
      HTTP 200 and body indicates healthy state (e.g., `{"status":"ok"}`).
- [ ] Core resource endpoints respond (one per major resource):
  - [ ] `GET /api/<resource>` returns HTTP 200 (list endpoint).
  - [ ] `GET /api/<resource>/{id}` returns HTTP 200 for a known valid ID.
  - [ ] `GET /api/<resource>/{id}` returns HTTP 404 for a known invalid ID.
- [ ] API documentation endpoint is accessible:
  - [ ] `/docs` or `/api/docs` (Swagger UI) loads for FastAPI/Django REST.
  - [ ] `/api-docs` or `/swagger` loads for Express/Koa.
- [ ] Authentication-protected endpoints return HTTP 401 when accessed without
      credentials.
- [ ] CORS headers are present if the API serves a web frontend.
- [ ] No unhandled exceptions or stack traces appear in server logs at startup.

---

## Unit Tests

**Approach:** Test business logic, service layer, domain models, and utility
functions in complete isolation. Mock ALL external dependencies (database,
message queue, external APIs, file system).

**Per-language tooling:**

| Language | Test Runner | Mocking | Assertions |
|---|---|---|---|
| Node.js | Vitest / Jest | jest.fn() / vi.fn() | built-in |
| Python | pytest | unittest.mock / pytest-mock | built-in |
| Go | `go test` | testify/mock, gomock | testify/assert |
| Rust | `cargo test` | mockall, mock_instant | built-in |

**Coverage Target:** 80% line coverage on business logic, service, and utility
layers. Exclude: generated code, config files, database migrations, type
definitions, route definitions (thin wiring).

**Key patterns to test:**
- Service functions with various input combinations (valid, edge, invalid).
- Business rule enforcement (e.g., "user must have role X to perform Y").
- Data transformation and validation logic.
- Error handling branches (what happens when each dependency fails).
- Pagination math, sorting logic, filtering logic (in isolation).
- Authentication and authorization decision logic.

---

## Integration Tests

**Approach:** Test API endpoints end-to-end within the service boundary, using
a test database (or testcontainers) but no external network dependencies.
Each test should be self-contained and leave no side effects.

**Per-language tooling:**

| Language | HTTP Client | Test DB Strategy |
|---|---|---|
| Node.js | supertest + express/fastify app instance | SQLite in-memory / PostgreSQL testcontainers / transaction rollback |
| Python | httpx.AsyncClient / Starlette TestClient | SQLite in-memory / pytest-alembic / transaction rollback |
| Go | httptest.Server + framework router | SQLite in-memory / testcontainers-go / begin-tx-rollback |
| Rust | actix_web::test / reqwest + mock server | SQLite in-memory / testcontainers / transaction rollback |

**Database strategy (transaction rollback):**
1. Begin a database transaction at test start.
2. Run the test (seeds, API calls, assertions).
3. Roll back the transaction at test end. Database is clean for the next test.
4. This is significantly faster than dropping/recreating the database.

**Coverage Target:** 100% of critical API endpoints (user-facing, data-mutating,
authentication-gated). Non-critical endpoints (admin internal, metrics, debug)
can be tested with unit tests only.

**Key flows to test:**
- CRUD lifecycle for each core resource (create, read, update, delete, list).
- Authentication flow (register, login, token refresh, logout).
- Authorization (role-based access: admin vs. user vs. anonymous).
- Validation errors (malformed JSON, missing required fields, type mismatches).
- Pagination and filtering parameters.
- Error responses (correct HTTP status codes, correct error body format).
- Idempotency (create with idempotency key, retry returns same result).
- Rate limiting (verify 429 response after exceeding limit).

---

## Contract Validation

**Approach:** Validate that the API implementation matches its OpenAPI
specification. Detect breaking changes that would affect API consumers.

**Tools:**
- **OpenAPI spec:** `specs/api/<change-id>.yaml` (or `.yml`) -- the contract
  first spec produced in Phase 2 by the `api-contract-first` skill.
- **openapi-spec-validator:** Validate the spec is valid OpenAPI 3.x.
- **oasdiff:** Compare current API spec against the previously committed version
  to detect breaking changes. Breaking changes include:
  - Removed endpoint or HTTP method.
  - Changed request parameter from optional to required.
  - Changed response type or removed response field.
  - Changed authentication scheme.
  - Changed rate limiting behavior.

**How `oasdiff` integrates with gates:**
1. In Phase 2, `api-contract-first` produces `specs/api/<change-id>.yaml`.
2. In Phase 4, the Contract Gate in `run_phase_gates 4` calls the pre-push
   CONTRACT check.
3. The CONTRACT check runs `oasdiff breaking specs/api/<previous>.yaml specs/api/<change-id>.yaml`.
4. If breaking changes are detected, the gate fails. The developer must either
   version the API (v2) or coordinate with consumers to accept the change.

**Install oasdiff:**
```bash
go install github.com/tufin/oasdiff/cmd/oasdiff@latest
```

---

## E2E Tests

REST APIs typically do not have traditional browser-based E2E tests (that is
the web frontend or mobile app's responsibility). Instead, run:

- **API-level E2E:** Full stack integration tests against a deployed instance
  (staging environment), using curl/httpie/httpx to exercise complete user
  scenarios that span multiple endpoints.
- **Contract-driven E2E:** Generate test cases from the OpenAPI spec using
  tools like schemathesis or Dredd.

**Tools:**
- **schemathesis:** Property-based API testing from OpenAPI specs.
- **Dredd:** Validate API implementation against API Blueprint or OpenAPI.
- **Portman:** Generate Postman collections from OpenAPI specs for manual
  or Newman-based E2E runs.

---

## Gate Integration

This test strategy integrates with `run_phase_gates 4` (Phase 4 -- Verify)
through three gates:

### Contract Gate
- Runs `oasdiff` to detect breaking changes between the current API spec and
  the previous version.
- Breaking change = Contract Gate fails. Non-breaking change = Contract Gate
  passes.
- Disable with `HOOK_CONTRACT=0` in `.githooks/config` (not recommended).

### Security Gate
- **semgrep**: SAST scan with `semgrep --config=auto`. Checks for SQL
  injection, hardcoded secrets, unsafe deserialization, path traversal,
  and authentication bypasses.
- **npm audit** (Node.js) / **pip-audit** (Python) / **cargo audit** (Rust):
  Dependency vulnerability scan.
- **Go**: `govulncheck ./...` for vulnerability scanning.
- A finding of `moderate` severity or higher blocks the Security Gate.

### Smoke Test Gate
- The smoke test checklist at the top of this document provides the pass/fail
  criteria. All items must be checked and passing.
- Automated smoke test: start server with `npm start` / `uvicorn` / `go run`,
  poll `GET /health` for HTTP 200 (with timeout and retry), verify core
  endpoints respond.
- If any smoke test item fails, the Smoke Test Gate fails and Phase 4 cannot
  advance to Phase 5.

---

## Quick Reference (for CLAUDE.md Extraction)

REST API/backend: detected by express/fastify/fastapi/django/gin/echo in deps. Smoke test: server start, health 200, core endpoints respond, auth returns 401. Unit: service/business logic, 80% coverage, mock all I/O. Integration: supertest/httpx/httptest against test DB with transaction rollback, 100% critical endpoints. Contract: oasdiff breaking change detection via OpenAPI spec in specs/api/. Security: semgrep + npm/pip/cargo audit. Gates: Contract (oasdiff), Security (SAST+SCA), Smoke Test (health+endpoints). Gated at Phase 4 run_phase_gates 4.
