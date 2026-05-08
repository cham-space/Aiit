# Test Strategy: Background Worker / Consumer

## Detection Signals

The onboarding system (`/onboard`) auto-detects a background worker project
when:

- **Message queue consumer pattern:**
  - Dependencies include a message queue client library:
    - Node.js: `amqplib`, `amqp-connection-manager`, `sqs-consumer`,
      `kafkajs`, `bullmq`, `rsmq`.
    - Python: `celery`, `arq`, `dramatiq`, `rq`, `faust`, `aiokafka`,
      `kombu`.
    - Go: `segmentio/kafka-go`, `streadway/amqp`, `nsqio/go-nsq`.
    - Rust: `lapin` (AMQP), `rdkafka`, `celery-rs`.
  - Entry point does NOT start an HTTP server (no `app.listen`, `uvicorn.run`,
    `http.ListenAndServe`).

- **Cron/scheduler setup:**
  - `crontab` files present, or `node-cron`, `node-schedule`, `apscheduler`
    in dependencies.
  - Timer-based execution, not request-driven.

- **Task queue / job processing:**
  - Dependencies include `bull` / `bullmq`, `bee-queue`, `sidekiq` (Ruby),
    `huey` (Python).
  - A `tasks/`, `jobs/`, or `workers/` directory exists.

- **Consumer / subscriber pattern:**
  - Code subscribes to a message channel or topic (not an HTTP route).
  - Uses `subscribe()`, `consume()`, or `process()` as the primary entry
    point rather than request handlers.

- **No HTTP server:**
  - The project does NOT expose an HTTP server on any port.
  - No `express`, `fastify`, `gin`, `actix-web`, `axum`, `rocket` in
    dependencies (unless used ONLY for health checks -- see mixed signal
    handling below).

- **Mixed signal handling:**
  - If the project has BOTH an HTTP server (e.g., for health checks) and a
    message consumer, classify as **worker** if the primary purpose is
    consuming/processing. The HTTP server is treated as secondary.
  - If the HTTP server is the primary purpose and the consumer is secondary,
    classify as **rest-api** and apply the rest-api strategy to the
    consumer code.

---

## Smoke Test Checklist

Smoke tests verify the worker is operational at a basic level.

- [ ] Dependencies install without errors (`npm install`, `pip install -r
      requirements.txt`, `go mod download`, `cargo build`).
- [ ] The worker process starts without crashing or panicking.
- [ ] The worker connects to the message queue/broker successfully:
  - [ ] Logs show "connected to queue" or equivalent.
  - [ ] Connection errors (wrong host/port, auth failure) produce clear
        error messages, not silent hangs.
- [ ] The worker subscribes to the correct queue/topic:
  - [ ] Logs show subscription to expected queue name(s).
  - [ ] If routing keys or topic patterns are used, they are logged at
        startup for verification.
- [ ] A test message placed on the queue is consumed and processed:
  - [ ] The message does not remain in the queue (is acknowledged).
  - [ ] The processing result (log output, database write, side effect)
        is observable.
- [ ] Malformed messages are handled gracefully:
  - [ ] An unparseable message does not crash the worker.
  - [ ] The message is either moved to a dead letter queue (DLQ) or logged
        and acknowledged (depending on the configured error strategy).
- [ ] Graceful shutdown works:
  - [ ] Sending SIGTERM/SIGINT causes the worker to stop consuming new
        messages.
  - [ ] In-flight messages are completed before the process exits.
  - [ ] The connection to the broker is closed cleanly.
- [ ] Health endpoint responds (if the worker includes one):
  - [ ] `GET /health` or `GET /healthz` returns HTTP 200.
  - [ ] The health check verifies broker connectivity, not just process
        liveness.

---

## Unit Tests

**Approach:** Test message processing logic, error handling, and business
rules in complete isolation. Mock the message queue, database, external
APIs, and any other I/O.

**Per-language tooling:**

| Language | Test Runner | Mocking Strategy |
|---|---|---|
| Node.js | Vitest / Jest | Mock queue client (amqplib, sqs-consumer, etc.). Test handler functions with synthetic message payloads. |
| Python | pytest | Mock Celery tasks with `@mock.patch`. Test task functions directly by calling them. |
| Go | `go test` | Mock queue interfaces. Test `ProcessMessage(msg Message) error` handlers directly. |
| Rust | `cargo test` | Mock queue traits with mockall. Test message handler functions. |

**Coverage Target:** 80% line coverage on message processing logic, business
rules, data transformation, and error handling. Exclude: queue connection
boilerplate, configuration, health check handlers (trivial), generated code.

**Key patterns to test:**
- Message processing logic:
  - Valid message payload: verify the handler produces the expected outcome
    (data transformed correctly, side effect triggered).
  - Invalid JSON/binary payload: verify the handler returns an error or
    handles it gracefully (no panic).
  - Missing required fields: verify the handler catches the error and logs
    or rejects the message.
- Error handling:
  - Transient error (e.g., network timeout to database): verify retry
    behavior (exponential backoff, max retries, eventual DLQ).
  - Permanent error (e.g., invalid data that cannot be fixed by retrying):
    verify the message is moved to DLQ or logged and acknowledged (not
    retried infinitely).
  - Partial failure (some side effects succeeded, some failed): verify
    idempotency or transactional rollback.
- Business rules and validation (same patterns as rest-api unit tests).
- Data transformation and serialization/deserialization.

---

## Integration Tests

**Approach:** Test the worker with a real message queue (embedded or
testcontainer) and real downstream dependencies (test database, test
HTTP mock server for external API calls). Verify the full pipeline:
publish message, worker consumes, side effects occur.

**Message queue strategies (ordered by preference):**

1. **Testcontainers (best):** Spin up a real queue instance in a Docker
   container (RabbitMQ, Redis, Kafka, SQS via LocalStack). Most realistic.
   - Requires Docker in CI.
   - Use `testcontainers/testcontainers-node`, `testcontainers-python`,
     `testcontainers-go`, or `testcontainers-rs`.

2. **Embedded/in-memory queue:** Use a library that provides an in-memory
   queue implementation.
   - Node.js: `bull` with in-memory Redis (ioredis-mock) or `better-queue`.
   - Python: `fakeredis` for `rq`/`arq`, `memory://` broker for `celery`.
   - Go: `testcontainers-go` or use `miniredis` for Redis-backed queues.
   - Rust: `mockall` or `fake` crates for queue implementations.

3. **Mock/spy queue:** Create a thin wrapper around the real queue client
   and swap in a spy implementation for tests.
   - Verify: messages were published with expected payload and routing key,
     acks were sent, nacks were sent with requeue flag.

**Per-language tooling:**

| Language | Integration Test Setup |
|---|---|
| Node.js | testcontainers (RabbitMQ/Redis) + ioredis-mock + MSW for external HTTP calls. |
| Python | pytest + testcontainers + pytest-alembic for migrations + respx/httpx-mock for external HTTP. |
| Go | testcontainers-go + sqlite in-memory + httptest.Server for external API simulation. |
| Rust | testcontainers + sqlite in-memory + wiremock for external HTTP. |

**Coverage Target:** One integration test per message type (event, command,
notification) that the worker processes. Cover at minimum the 3-5 most
common message types.

**Key flows to test:**
- Publish valid message, verify the worker:
  - Consumes the message from the queue.
  - Processes it and produces the expected result (DB row inserted, file
    created, API called with correct payload).
  - Acknowledges the message (removes from queue).
- Publish invalid message, verify the worker:
  - Consumes the message.
  - Attempts processing and fails.
  - Either moves to DLQ (after max retries) or rejects with requeue=false.
- Publish batch of messages (if batch processing is supported):
  - Verify messages are processed in batches (not one at a time if batch
    mode is configured).
  - Verify batch atomicity (all or none, if configured).
- Concurrent message processing:
  - Verify the worker handles concurrent messages according to its
    concurrency configuration (e.g., max 5 concurrent, others queued).
- Graceful shutdown mid-processing:
  - Send SIGTERM while a message is being processed.
  - Verify the worker finishes processing the current message, acks it,
    and shuts down (does not ack and lose the message, does not fail to
    shut down).

---

## Contract Validation

Background workers have different contracts from REST APIs:

### Message Schema Contract
- Each message type the worker consumes has an implicit schema (JSON
  structure, Protobuf definition, Avro schema).
- Changes to the message schema are breaking changes for the publisher
  or consumer (depending on who changed).
- **Verify with:**
  - Snapshot tests of expected message schemas.
  - Schema evolution tests: publish with old schema, verify consumer can
    still process (backward compatibility). Publish with new schema,
    verify old consumer can still process the fields it knows about
    (forward compatibility).
  - **Schema registry** (Avro/Protobuf) for Kafka-based workers: validate
    message schemas against the registry.

### Side Effect Contract
- Documented side effects (database writes, file creation, API calls,
  event emission) are a contract. Removing or changing a side effect
  is a breaking change for downstream systems.
- **Verify with:** integration tests that assert on all documented side
  effects.

---

## Gate Integration

This test strategy integrates with `run_phase_gates 4` (Phase 4 -- Verify)
through three gates:

### Contract Gate
Workers do not use `oasdiff` unless they also expose a REST API. For pure
worker projects, the Contract Gate checks:
- Message schema snapshots have no unexpected diffs.
- Documented side effects are all verified by integration tests.
- If the worker emits messages to another queue, the emitted message schema
  is stable (no breaking changes for downstream consumers).
- If Kafka + Schema Registry is used, `schema-registry validate` passes
  for evolved schemas (L3 only).

### Security Gate
- **semgrep**: SAST scan focusing on:
  - Deserialization vulnerabilities (unsafe JSON parsing, pickle, eval).
  - Command injection (if worker executes shell commands based on message
    content).
  - SQL injection (if worker writes to a database).
  - SSRF (if worker makes HTTP calls based on message content).
  - Credentials in connection strings (hardcoded broker passwords).
- **npm audit** (Node.js) / **pip-audit** (Python) / **cargo audit** (Rust) /
  **govulncheck** (Go): Dependency vulnerability scan.
- **Broker configuration:**
  - TLS for broker connection.
  - Authentication credentials for broker access.
  - Network isolation (worker and broker in same VPC/network).

### Smoke Test Gate
- The smoke test checklist at the top of this document provides the pass/fail
  criteria. All items must be checked and passing.
- Automated smoke test: start the worker, verify broker connection (health
  check or log output), publish a test message, verify the worker consumes
  and processes it, verify the result, send SIGTERM, verify graceful
  shutdown.
- If the broker is external (not locally available for testing), at minimum
  verify the worker starts and reports a clear connection error (does not
  silently hang).
- If any smoke test item fails, the Smoke Test Gate fails and Phase 4 cannot
  advance.

---

## Quick Reference (for CLAUDE.md Extraction)

Background worker: detected by message queue deps (amqplib/celery/kafka-go) + no HTTP server. Smoke test: worker starts, connects to broker, processes a test message, handles malformed messages, graceful shutdown. Unit: message processing logic + error handling, mock all I/O, 80% coverage. Integration: testcontainers (real queue) or embedded queue, verify publish-consume-process-ack pipeline, one test per message type. Contract: message schema snapshots, side effect verification, schema registry for Kafka. Security: semgrep (deserialization/injection/SSRF) + dependency audit + broker TLS/auth. Gates: Contract (schema stability), Security (worker-specific SAST), Smoke Test (start-connect-process-shutdown). Gated at Phase 4 run_phase_gates 4.
