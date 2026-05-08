# Test Strategy: Tauri Desktop

## Detection Signals

The onboarding system (`/onboard`) auto-detects a Tauri project when:

- `src-tauri/Cargo.toml` exists (the Tauri Rust backend).
- `src-tauri/tauri.conf.json` exists (the Tauri configuration).
- `package.json` in the project root contains `@tauri-apps/cli` or
  `@tauri-apps/api` as a dependency.
- `tauri` crate is listed in `src-tauri/Cargo.toml` dependencies.
- The project has both a Rust backend (`src-tauri/`) and a web frontend
  (typically `src/` with React, Vue, Svelte, or vanilla HTML/JS/CSS).
- The project is NOT a pure web SPA (no `src-tauri/` means it is web, not
  Tauri).

Tauri projects are hybrid: they combine a Rust backend with a web-based
frontend rendered in a native webview. The test strategy must cover both.

---

## Smoke Test Checklist

Smoke tests verify the desktop app is functional at a basic level.

- [ ] `npm install` (or `yarn` / `pnpm install`) completes without errors.
- [ ] Frontend build (`npm run build` or equivalent) compiles without errors.
- [ ] `cargo build` in `src-tauri/` compiles the Rust backend without errors.
- [ ] `npm run tauri dev` (or `cargo tauri dev`) launches the application:
  - [ ] The native window opens without crashing.
  - [ ] The webview renders the frontend content (no blank screen).
  - [ ] No panic, unhandled exception, or crash dialog appears at startup.
- [ ] IPC commands respond:
  - [ ] Invoke at least one `tauri::command` from the frontend and verify
        the Rust handler executes and returns a response.
  - [ ] Verify an error case (invoke with invalid input, handler returns
        `Result::Err`) does not crash the app.
- [ ] Window management works:
  - [ ] Window can be resized.
  - [ ] Window can be minimized and restored.
  - [ ] Window close terminates the process cleanly.
- [ ] Frontend navigation works within the webview.
- [ ] No console errors (check webview devtools) at startup.

---

## Unit Tests

### Rust Backend Unit Tests

**Approach:** Test individual Rust functions, modules, and Tauri commands
in isolation. Use Rust's built-in test framework.

**Tools:**
- `cargo test` for all unit tests in `src-tauri/src/`.
- `#[cfg(test)]` modules within each source file (Rust convention).
- Mock the Tauri runtime with `tauri::test::mock_builder()` for command
  handler tests that need app handle access.

**Coverage Target:** 80% line coverage on Rust backend code. Exclude:
generated code, tauri config bindings, build scripts, and `main.rs`
(bootstrapping only).

**Key patterns to test:**
- Pure Rust functions (input/output, edge cases).
- Tauri command handlers (valid input, invalid input, error propagation).
- State management (accessing and mutating `tauri::State<T>`).
- Event emission and handling.
- File system operations (within the app's permitted scope).
- Platform-specific code paths (Windows vs. macOS vs. Linux).

### Frontend Unit Tests

**Approach:** Test frontend components, hooks, and utilities. Same strategy
as web frontend, but mock Tauri APIs.

**Tools:**
- **Vitest** (preferred) or **Jest**.
- **React Testing Library** / **Vue Test Utils** / **Svelte Testing Library**.
- Mock `@tauri-apps/api` modules:
  - `vi.mock('@tauri-apps/api/core', () => ({ invoke: vi.fn() }))`
  - `vi.mock('@tauri-apps/api/window', () => ({ ... }))`
  - `vi.mock('@tauri-apps/api/event', () => ({ listen: vi.fn() }))`

**Coverage Target:** 80% line coverage on frontend `src/` files.

**Key patterns to test:**
- Components that invoke Tauri commands (mock the invoke, test the UI state
  transitions for loading/success/error).
- Event listeners (mock listen, emit an event, verify handler is called).
- Same patterns as **web** strategy for non-Tauri-specific frontend code.

---

## Integration Tests

### Rust Backend Integration Tests

**Approach:** Test Tauri commands end-to-end within the Rust process. Use
Tauri's test utilities to spin up a minimal app instance.

**Tools:**
- `tauri::test::mock_builder()` to create a test app with registered commands.
- Call commands programmatically and verify return values.
- Use temporary directories for file system tests (`tempfile` crate).

**Key flows to test:**
- Command registration: verify all registered commands are callable.
- State lifecycle: initialize state, invoke command that reads state, invoke
  command that mutates state, verify state was updated.
- Event round-trip: emit event from Rust, verify frontend listener is called
  (and vice versa if testing frontend-triggered events).
- Error handling: command panics should be caught, not crash the process.

### Frontend Integration Tests

**Approach:** Test frontend components that interact with (mocked) Tauri
APIs in combination. Focus on workflows that involve multiple IPC calls.

**Tools:**
- Same as frontend unit test tools (Vitest + Testing Library).
- Use MSW for any HTTP calls the frontend makes (e.g., to a bundled local
  server or an external API).

**Key flows to test:**
- Multi-step workflows that involve several IPC invocations.
- Frontend state transitions based on IPC call results (loading, success,
  error states).
- Communication between frontend components through Tauri events.

---

## E2E Tests

**Approach:** Full desktop app automation. Launch the Tauri app and interact
with it programmatically.

**Tools:**
- **Playwright** against the Tauri webview (if webview testing is enabled).
  This requires running the Tauri app and connecting Playwright to its
  embedded webview's debugging port.
- **Tauri driver** (experimental): `tauri-driver` crate for WebDriver-based
  automation of the native window and webview.
- **Manual testing** (Phase 4): Launch the app manually, run through the
  smoke test checklist.

**Webview testing (Playwright):**
1. Start the Tauri app in dev mode with remote debugging enabled.
2. Connect Playwright to the webview's CDP (Chrome DevTools Protocol) port.
3. Use standard Playwright APIs to interact with the webview content.
4. Limitations: Native features (file dialogs, system tray, notifications)
   cannot be tested via Playwright. These require manual testing or
   Tauri driver.

**Coverage Target:** Critical-path user journeys (app launch, primary feature
workflow, app close).

**Key flows to test:**
- App launch to primary feature completion.
- File open/save dialogs (manual only, unless using Tauri driver).
- System tray interaction (manual only).
- Menu bar actions (manual only).
- Window state persistence across close/reopen.

---

## Contract Validation

Tauri apps have two contract points:

### Tauri IPC Contract
- The Rust backend exposes commands (`#[tauri::command]`) with specific
  signatures. Changes to command names, parameters, or return types are
  breaking changes for the frontend.
- Verify with: compare the list of registered commands against the expected
  list. The Tauri build process binds them at compile time, so mismatches
  are caught at build time -- but runtime review of command signatures
  is valuable for documentation purposes.

### Frontend-Backend Type Contract
- If using a shared type library (e.g., TypeScript types generated from
  Rust types via `ts-rs`), verify the generated types are in sync.
- Run the type generation before building and check that the generated
  files have no unexpected changes (snapshot test the generated types).

---

## Gate Integration

This test strategy integrates with `run_phase_gates 4` (Phase 4 -- Verify)
through three gates:

### Contract Gate
Tauri apps do not use `oasdiff` unless they also expose a REST API. For
pure Tauri projects, the Contract Gate checks:
- Tauri IPC command signatures have not changed in a breaking way (compare
  `tauri::Builder::default().invoke_handler(tauri::generate_handler![...])`
  arguments).
- If `ts-rs` or similar type generation is used, generated TypeScript types
  are up-to-date with Rust types.

### Security Gate
- **Rust backend:** `cargo audit` for known vulnerabilities in Rust
  dependencies.
- **Frontend:** `npm audit --audit-level=moderate` for JavaScript dependencies.
- **semgrep**: Run on both the Rust codebase and the frontend codebase.
  - Rust: unsafe blocks, command injection, path traversal.
  - Frontend: XSS vectors, hardcoded secrets, CSP bypasses.
- **Tauri CSP:** Verify the Content Security Policy in `tauri.conf.json`
  is not overly permissive (no `unsafe-eval` without justification, no
  `*` origin for connect-src).
- **Tauri permissions:** Verify the Tauri allowlist (capabilities in v2,
  allowlist in v1) permits only the features the app actually needs.

### Smoke Test Gate
- The smoke test checklist at the top of this document provides the pass/fail
  criteria. All items must be checked and passing.
- Automated smoke test: compile Rust backend + frontend build, launch the
  app, verify the window appears and webview renders content, invoke a
  test IPC command, verify response, close the app.
- If any smoke test item fails, the Smoke Test Gate fails and Phase 4 cannot
  advance.

---

## Quick Reference (for CLAUDE.md Extraction)

Tauri desktop: detected by src-tauri/Cargo.toml + tauri.conf.json + @tauri-apps/cli. Smoke test: app launches without crash, webview renders, IPC commands respond, window can resize/close. Unit: cargo test (Rust backend, 80%), vitest/jest (frontend, 80%). Integration: tauri::test::mock_builder for command tests, frontend workflow tests with mocked Tauri APIs. E2E: Playwright against webview CDP port (critical paths), manual for native features. Contract: IPC command signature stability, ts-rs type sync. Security: cargo audit + npm audit + semgrep + CSP review. Gates: Contract (IPC signatures), Security (dual audit), Smoke Test (launch+render+IPC+close). Gated at Phase 4 run_phase_gates 4.
