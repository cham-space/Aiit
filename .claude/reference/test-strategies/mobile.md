# Test Strategy: Mobile

## Detection Signals

The onboarding system (`/onboard`) auto-detects a mobile project when:

- **React Native / Expo:**
  - `package.json` contains `react-native`, `expo`, or `@react-native-community/*`.
  - `app.json`, `app.config.js`, or `app.config.ts` exists (Expo config).
  - `ios/` and/or `android/` directories exist with native project files.
  - Metro bundler config (`metro.config.js`) is present.

- **Flutter:**
  - `pubspec.yaml` contains `flutter` in the `dependencies` or `dev_dependencies`.
  - `lib/main.dart` exists.
  - `ios/`, `android/`, `web/`, or platform directories exist.
  - `.dart_tool/` directory with Flutter tooling artifacts.

- **Native iOS:**
  - `.xcodeproj` or `.xcworkspace` file exists.
  - `*.swift` or `*.m` files in an organized project structure.
  - `Info.plist` is present.

- **Native Android:**
  - `build.gradle` or `build.gradle.kts` with `com.android.application` plugin.
  - `AndroidManifest.xml` exists.
  - `*.kt` or `*.java` files in `src/main/` or `app/src/main/`.

- **General signals:**
  - Simulator/emulator configuration in CI or scripts.
  - Platform-specific directories (`ios/`, `android/`).
  - Mobile-specific dependencies (push notifications, camera, location).

---

## Smoke Test Checklist

Smoke tests verify the mobile app is functional at a basic level.

- [ ] Dependencies install without errors.
  - React Native: `npm install` (or `yarn`).
  - Flutter: `flutter pub get`.
  - iOS: `pod install` (in `ios/` directory).
  - Android: Gradle sync completes.
- [ ] The app builds successfully:
  - React Native: `npx react-native run-ios` or `npx expo start`.
  - Flutter: `flutter build ios --debug` or `flutter build apk --debug`.
- [ ] The app installs on the simulator/emulator without errors.
- [ ] The app launches on the simulator/emulator without crashing:
  - [ ] Splash screen appears.
  - [ ] Main/home screen renders.
  - [ ] No "app has stopped" or crash dialog.
- [ ] Core screens render:
  - [ ] Home screen loads and displays content.
  - [ ] At least one detail/edit screen renders correctly.
  - [ ] Navigation between screens works (tab tap, stack push/pop).
- [ ] Platform-specific features initialize cleanly:
  - [ ] No permission errors for non-critical permissions on first launch.
  - [ ] Any required permissions are requested with a clear explanation.
- [ ] Error states display gracefully (airplane mode, no data):
  - [ ] The app does not crash when network is unavailable.
  - [ ] Error UI is shown, not a blank screen or infinite spinner.
- [ ] The app does not crash on device rotation (portrait to landscape and
      back) or multitasking resume.

---

## Unit Tests

**Approach:** Test business logic, state management, data transformation,
and utility functions in isolation. Mock ALL platform-specific APIs and
external dependencies.

**Per-platform tooling:**

| Platform | Test Runner | Key Libraries |
|---|---|---|
| React Native | Jest (default) / Vitest | @testing-library/react-native, jest-fetch-mock |
| Flutter | `flutter test` | mockito, mocktail, bloc_test (for BLoC), riverpod testing |
| iOS (Swift) | XCTest | Cuckoo (mock generation) |
| Android (Kotlin) | JUnit 5 / Spek | MockK, Mockito-Kotlin, Turbine (Flow testing) |

**Coverage Target:** 70% line coverage on business logic, state management,
and utility layers. Mobile apps have more platform integration code than
web/backend, so the coverage target is lower. Exclude: generated code, UI
rendering code (tested via widget/component tests), platform bridge code
(thin wrappers over native APIs).

**Key patterns to test:**
- State management (reducers, actions, view models, BLoC events/states).
- Data transformation (API response to domain model, domain model to UI state).
- Validation logic (form fields, business rules).
- Repository/data layer (with mocked HTTP client or database).
- Navigation logic (route guards, deep link routing).
- Platform abstraction layer (mock platform, test the logic around it).

---

## Widget / Component Tests

**Approach:** Test UI components in isolation. Render with props, simulate
interactions, and verify the rendered output and callback behavior.

**Per-platform tooling:**

| Platform | Testing Approach |
|---|---|
| React Native | @testing-library/react-native: render component, query by text/role/testID, fire events, assert on render output. |
| Flutter | `flutter test` with `WidgetTester`: pumpWidget, find by text/key/type, tap/drag, verify widget tree. |
| iOS (SwiftUI) | XCTest + ViewInspector (third-party): inspect SwiftUI view hierarchy programmatically. |
| Android (Jetpack Compose) | Compose Testing: `createComposeRule()`, `onNodeWithText()`, `performClick()`, `assertIsDisplayed()`. |

**Coverage Target:** Key interactive components only (no strict percentage).
Focus on:
- Components that handle user input (forms, search bars, toggles).
- Components with conditional rendering (loading/error/empty states).
- Reusable components used across multiple screens.

**Key patterns to test:**
- Render with different prop combinations and verify output.
- Simulate user interactions (tap, long press, scroll, text input).
- Verify callbacks are called with correct arguments.
- Test loading, success, error, and empty states.
- Test accessibility (role, label, hint properties).

---

## Integration Tests

**Approach:** Test navigation flows and feature workflows that span multiple
screens. Mock the API/data layer at the network boundary.

**Per-platform tooling:**

| Platform | Testing Approach |
|---|---|
| React Native | Jest/Vitest with mocked navigation container + mocked API. Or detox for native-level integration. |
| Flutter | `flutter test` with `IntegrationTestWidgetsFlutterBinding` + mocked HTTP client. |
| iOS | XCUITest with mocked URLProtocol or local server. |
| Android | Espresso / UI Automator with MockWebServer (OkHttp). |

**Key flows to test:**
- Navigation: navigate from home to detail screen, verify detail data is
  displayed, navigate back.
- Form submission: fill form fields, submit, verify success feedback,
  verify data appears on a subsequent screen.
- Authentication flow: login screen, enter credentials, verify redirect
  to main app, logout.
- Error recovery: simulate API failure on a screen, verify error UI,
  simulate retry, verify success UI.

---

## E2E Tests

**Approach:** Full app automation on a real device or simulator, exercising
complete user journeys with the full stack.

**Tools:**
- **Detox** (React Native): Gray box E2E testing. Synchronizes with the
  app's event loop, so tests are deterministic and not sleep-based.
- **Flutter Integration Test:** `integration_test` package. Runs on device/
  emulator with full Flutter framework.
- **XCUITest** (iOS): Native UI testing framework. Supports Swift and
  Objective-C test cases.
- **Espresso** / **UI Automator** (Android): Native UI testing frameworks.

**Coverage Target:** Critical-path user journeys only (2-5 primary flows).

**Key flows to test:**
- Happy path: complete primary user journey from launch to goal completion.
- Authentication: full login/logout cycle with real or test credentials.
- Offline behavior: enable airplane mode, verify graceful degradation.
- Push notification handling (if applicable).
- Deep link handling (if applicable).

---

## Contract Validation

Mobile apps typically do not have their own API contract. They consume a
backend API. Verify:

- The mobile app's API client (or generated code from OpenAPI) matches the
  backend's OpenAPI spec in `specs/api/<change-id>.yaml`.
- Platform-specific contracts (e.g., Android Intents, iOS URL Schemes) are
  documented and stable.

For the backend contract validation, see the **rest-api** test strategy.

---

## Gate Integration

This test strategy integrates with `run_phase_gates 4` (Phase 4 -- Verify)
through three gates:

### Contract Gate
Not directly applicable to mobile apps unless the app exposes an API itself.
If the mobile app is paired with a backend change, the Contract Gate applies
to the backend (see rest-api strategy). For mobile-only changes, Contract
Gate checks:
- API client is compatible with the backend OpenAPI spec.
- Deep link URL scheme has not changed.
- App permissions manifest (Info.plist, AndroidManifest.xml) changes are
  documented and intentional.

### Security Gate
- **npm audit** (React Native) / **Gradle dependency check** (Android) /
  **CocoaPods audit** (iOS): Dependency vulnerability scan.
- **semgrep**: Run on the mobile codebase.
  - React Native: XSS, hardcoded API keys, insecure storage (AsyncStorage
    for secrets).
  - Flutter: hardcoded secrets, insecure HTTP usage.
  - iOS: insecure ATS configuration, hardcoded secrets.
  - Android: cleartext traffic, exported components, hardcoded secrets.
- **Mobile-specific checks:**
  - Keystore/Keychain usage for sensitive data (not plaintext storage).
  - Certificate pinning for API calls (L3 only).
  - Obfuscation/minification enabled for release builds.
  - ProGuard/R8 rules are not overly permissive.

### Smoke Test Gate
- The smoke test checklist at the top of this document provides the pass/fail
  criteria. All items must be checked and passing.
- Automated smoke test (where possible): build the app, install on simulator/
  emulator, launch, verify main screen renders, take a screenshot.
- For apps that require manual testing (no simulator automation available),
  the Smoke Test Gate delegates to the manual smoke test checklist. All
  items must be manually verified and checked off.
- If any smoke test item fails, the Smoke Test Gate fails and Phase 4 cannot
  advance.

---

## Quick Reference (for CLAUDE.md Extraction)

Mobile: detected by react-native/expo/flutter deps, ios/ or android/ dirs. Smoke test: app installs, launches without crash, core screens render, navigation works. Unit: business logic + state management, 70% coverage. Widget/Component: @testing-library/react-native or flutter WidgetTester, key interactive components. Integration: navigation flows with mocked API. E2E: Detox/XCUITest/Espresso, critical paths. Contract: API client compatibility, deep link stability. Security: dependency audit + semgrep + secure storage check. Gates: Contract (client compatibility), Security (mobile-specific checks), Smoke Test (build+launch+render). Gated at Phase 4 run_phase_gates 4.
