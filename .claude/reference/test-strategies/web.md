# Test Strategy: Web Frontend / SPA

## Detection Signals

The onboarding system (`/onboard`) auto-detects a web frontend project when:

- A `package.json` file exists without a `src-tauri/` directory (excluding Tauri).
- One or more of these configuration files is present:
  - `next.config.*` (Next.js)
  - `vite.config.*` (Vite)
  - `webpack.config.*` (Webpack)
  - `astro.config.*` (Astro)
  - `svelte.config.*` (SvelteKit)
  - `remix.config.*` (Remix)
- Dependencies include a UI framework: `react`, `vue`, `svelte`, `solid-js`,
  `angular`, `@angular/core`.
- A `public/` or `static/` directory with an `index.html` exists.
- `src/` or `app/` directory contains `.tsx`, `.jsx`, `.vue`, or `.svelte` files.

If the project is detected as Tauri (`src-tauri/Cargo.toml` exists), use the
**tauri** strategy instead. If the project is detected as a REST API (no
frontend files, only server files), use the **rest-api** strategy.

---

## Smoke Test Checklist

Smoke tests are quick sanity checks to verify the app is not fundamentally
broken. Run these before any deeper testing.

- [ ] `npm install` (or `yarn` / `pnpm install`) completes without errors.
- [ ] `npm run build` (or equivalent) produces a production bundle without errors.
- [ ] `npm run dev` (or equivalent) starts the dev server and binds to the
      expected port (default: 3000 for Next.js, 5173 for Vite).
- [ ] Core pages render without JavaScript console errors:
  - [ ] Home / index page loads and displays content.
  - [ ] At least one content/detail page loads and displays data.
  - [ ] Error page (404) renders correctly.
- [ ] Critical-path user flows work:
  - [ ] Navigation: click through primary nav links, verify each page loads.
  - [ ] Forms: submit one form (login, search, or contact), verify success or
        validation feedback.
  - [ ] Data loading: verify at least one API call succeeds and renders data.
- [ ] The app does not crash on browser refresh.
- [ ] Responsive layout does not break at mobile (375px), tablet (768px), and
      desktop (1280px) viewport widths.
- [ ] No console errors, warnings, or unhandled promise rejections at startup.

---

## Unit Tests

**Approach:** Test individual components, hooks, utilities, and state
management logic in isolation. Mock external dependencies (API calls, browser
APIs, third-party libraries).

**Tools:**
- **Vitest** (preferred for Vite-based projects) or **Jest** (for CRA/legacy
  projects).
- **React Testing Library** / **Vue Test Utils** / **Svelte Testing Library**
  for component rendering and interaction testing.
- **@testing-library/jest-dom** for DOM-specific matchers.
- **MSW (Mock Service Worker)** for API mocking at the network level.

**Coverage Target:** 80% line coverage on all `src/` files (excluding config
files, type definitions, and generated code).

**Key patterns to test:**
- Pure utility functions (input/output, edge cases).
- Custom hooks (state transitions, side effects).
- Component rendering (with various props combinations).
- User interaction callbacks (click, input, submit handlers).
- Conditional rendering (loading, empty, error, edge-case states).
- State management (store actions, reducers, computed values).
- Route guards and redirects.

---

## Integration Tests

**Approach:** Test how multiple components and modules work together. Focus
on user-facing workflows that span multiple components.

**Tools:**
- Same unit test tools (Vitest/Jest + Testing Library).
- Render parent components with child components, not just isolated units.
- **MSW** to mock API responses at the network boundary -- test how components
  handle real API response shapes (success, error, pagination, empty).

**Coverage Target:** Critical user flows only (no percentage target).

**Key flows to test:**
- Form submission end-to-end within the frontend (fill form, submit, see
  success/error state).
- List-to-detail navigation (browse list, click item, see detail page with
  data).
- Authentication flow (login form, token storage, redirect to protected route,
  logout).
- Search/filter with debounced input and paginated results.
- Error boundary recovery (trigger an error, verify fallback UI, verify retry).

---

## E2E Tests

**Approach:** Full browser automation testing the complete stack (frontend +
backend + database). Run against a deployed or locally running instance.

**Tools:**
- **Playwright** (Chromium, Firefox, WebKit) -- scripts defined in `tests/e2e/`
  or executed via Playwright MCP in interactive mode.
- **Playwright MCP** -- for interactive exploration and quick verification
  during Phase 3 (use `browser_navigate`, `browser_snapshot`, `browser_click`).

**Coverage Target:** Critical-path user journeys only.

**Key flows to test:**
- Happy path: complete primary user journey from landing to goal completion.
- Authentication: full login/logout cycle with session persistence.
- Data mutation: create, read, update, delete (CRUD) for core entities.
- Error handling: network failure recovery, validation error display.
- Cross-browser: run on Chromium minimum; add Firefox and WebKit for L3.

**Playwright MCP interactive mode (Phase 3):**
```
Navigate to dev server URL
Take snapshot to verify page structure
Click through primary navigation
Fill and submit a form
Take screenshot for visual comparison
```

---

## Visual Regression Testing

**Approach:** Compare screenshots of key pages against the design spec in
`specs/design/<change-id>.md` (and Figma, if available).

**Tools:**
- **Playwright** screenshot capture with `browser_take_screenshot`.
- Compare against Figma design spec exported images or reference screenshots
  stored in `specs/design/`.

**When to run:** Phase 4 (Verify), as part of the seven-step verification
process. Run after E2E Smoke tests pass.

---

## Contract Validation

Web frontends typically do not have their own API contract. Instead, they
consume a backend API contract. Verify that:

- The frontend's API client matches the latest OpenAPI spec in
  `specs/api/<change-id>.yaml` (or `specs/api/<change-id>.yml`).
- Request and response types align with the API contract.
- If using code generation from OpenAPI (e.g., `openapi-generator-cli`,
  `openapi-typescript`), verify the generated client is in sync.

For the backend contract validation, see the **rest-api** test strategy.

---

## Gate Integration

This test strategy integrates with `run_phase_gates 4` (Phase 4 -- Verify)
through three gates:

### Contract Gate
Not directly applicable to web frontends. However, if the frontend consumes
an external API with a versioned contract, verify the client is compatible.
The Contract Gate runs `oasdiff` against the backend API spec.

### Security Gate
- **npm audit**: Run `npm audit --audit-level=moderate` to detect known
  vulnerabilities in dependencies. A non-zero exit code on moderate+ findings
  blocks the Security Gate.
- **semgrep**: Run `semgrep --config=auto` on the frontend source. Check for
  XSS vectors (dangerouslySetInnerHTML, v-html, innerHTML), hardcoded secrets,
  and CSP bypasses.
- **Content Security Policy**: Verify `CSP` headers are set if the frontend
  is served with them (L3 only).

### Smoke Test Gate
- The smoke test checklist at the top of this document provides the pass/fail
  criteria. All items must be checked and passing.
- For automated smoke tests, use Playwright to verify:
  1. App starts and dev server is reachable.
  2. Home page returns HTTP 200 (or renders without crash for SPAs).
  3. At least one API-dependent page loads data successfully.
- If any smoke test item fails, the Smoke Test Gate fails and Phase 4 cannot
  advance.

---

## Quick Reference (for CLAUDE.md Extraction)

Web frontend/SPA: detected by package.json + react/vue/svelte/angular deps. Smoke test: dev start, core pages render, critical user flows work. Unit: vitest/jest + testing-library, 80% coverage. Integration: multi-component workflows with MSW. E2E: Playwright scripts or MCP interactive, critical paths only. Security: npm audit + semgrep XSS checks. Gates: Contract (API client compatibility), Security (audit + semgrep), Smoke Test (playwright health check). Gated at Phase 4 run_phase_gates 4.
