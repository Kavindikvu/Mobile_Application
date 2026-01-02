## Skillora Family — Engineering Prompt and Best Practices (Flutter)

Use this prompt before generating or modifying any code in `skillora-family-mobile`. Adhere strictly to these standards to keep the project scalable, maintainable, and consistent.

### Goals
- Build a large-scale, modular Flutter app aligned with Skillora’s design system and backend contracts.
- Maintain clean separation of concerns with a feature-first structure and clear cross-cutting `core` layer.
- Ensure reliability (tests, error handling), accessibility, performance, and internationalization.

### Project Architecture
- Structure:
  - `lib/core/`
    - `data/`: cross-cutting data providers and clients (e.g., `AssetDataProvider`, `HttpClient`).
    - `domain/`: cross-cutting models/value objects/entities used across features.
    - `providers/`: global Riverpod providers (auth/session, router, http client, analytics, env).
    - `router/`: `GoRouter` setup with `StatefulShellRoute` for tabbed navigation.
    - `theme/`: tokens and `ThemeData` (light/dark), do not hardcode raw colors.
    - `widgets/`: reusable shared widgets (e.g., role/child switcher, empty/error states).
  - `lib/features/<feature_name>/`
    - `data/`: repositories, DTOs, data mappers; keep implementations replaceable (assets -> API).
    - `domain/`: feature-specific domain models and business rules (pure Dart, no Flutter imports).
    - `presentation/`: screens, view models/providers, UI-only helpers.

- Principles:
  - Feature-first organization; avoid cross-feature coupling. Share only via `core/` or typed interfaces.
  - Clean boundaries: UI (presentation) -> providers/use-cases -> repositories -> data sources.
  - Riverpod for state; keep providers small, typed, and testable; avoid putting networking in widgets.
  - Navigation: `GoRouter` with route-name constants, typed params, deep links, and state restoration.
  - Prefer composition over inheritance; avoid singletons except via DI providers.

### State Management (Riverpod)
- Use `StateNotifier` or `AsyncNotifier` for nontrivial state; expose typed states (no `dynamic`).
- Prefer `FutureProvider`/`StreamProvider` for read-only async data. Keep derivations with `Provider`.
- Co-locate feature providers under the feature’s directory; cross-cutting providers live in `core/providers`.
- Do not mutate state in `build`/`build`-like methods; trigger side effects in lifecycle hooks or callbacks.

### Networking and Data
- Introduce a typed HTTP client in `core/data/http_client.dart` wrapping `http` with:
  - Base URL, auth headers, request/response interceptors, retry/backoff, and cancellation.
  - Centralized error normalization (e.g., `NetworkError` with code, message, details).
- Repositories return domain models, not raw JSON. Keep mappers/DTOs near the data layer.
- Pagination: standardize models (cursor/page, total, items) and expose typed pagination helpers.
- Caching: add in-memory and optional persistent caching (per endpoint/feature) where beneficial.

### Errors and Resilience
- Normalize errors into typed classes (`NetworkError`, `ValidationError`, `UnauthorizedError`, etc.).
- UI must handle `loading/empty/error` consistently using shared widgets from `core/widgets`.
- Use retry/backoff for idempotent GETs. Never retry POST/PUT/PATCH automatically.
- Gracefully degrade offline: cache last-read data for read views where feasible.

### Theming, Design Tokens, Accessibility
- All colors/spacing/radii/typography come from `core/theme/tokens.dart` and `AppTheme`.
- No hardcoded colors in widgets; prefer `Theme.of(context).colorScheme` and tokens.
- Support light/dark themes; verify contrast (WCAG AA). Targets: min 44x44 touch areas.
- Provide semantics labels, focus order, and proper roles for interactive components.

### Internationalization (i18n) and Localization (l10n)
- Use ARB files under `lib/l10n/` for all user strings; no hardcoded UI strings.
- Keep `l10n.yaml` configured; run codegen and reference generated localizations via a helper.
- Ensure RTL readiness and test layout on narrow/wide screens.

### Navigation
- Maintain `GoRouter` in `core/router/app_router.dart` using `StatefulShellRoute` for tabs.
- Centralize route names and typed params. Prefer `context.goNamed`/`pushNamed`.
- Enforce role-aware routes and guards via auth/role providers.

### Testing Strategy
- Unit tests: providers, mappers, repositories (mock clients).
- Widget tests: routing shell, critical screens (home, discover, assignments, messages, profile).
- Golden tests for shared widgets and design tokens.
- Keep tests deterministic; no real network. Use fakes/mocks.

### Tooling and Lints
- Strengthen `analysis_options.yaml` beyond `flutter_lints`:
  - Enable: `prefer_single_quotes`, `always_declare_return_types`, `avoid_dynamic_calls`,
    `unawaited_futures`, `use_build_context_synchronously` (warn), `public_member_api_docs` (selective),
    `avoid_print`, `prefer_const_constructors`, `avoid_redundant_argument_values`.
- Run `flutter analyze` and `flutter test` in CI.

### Performance
- Use `const` constructors and `const` widgets where possible; avoid rebuilding large subtrees.
- Memoize expensive computations; use `select` with Riverpod to limit rebuilds.
- Use `ListView.builder`, `SliverList`, and item virtualization patterns for long lists.
- Defer work with `addPostFrameCallback` when needed; avoid heavy sync work on UI thread.

### Logging, Analytics, and Monitoring
- Provide a `Logger` abstraction in `core/` with levels; no `print` in production paths.
- Centralize analytics events; include role and selected-child context in payloads.
- Add crash reporting hooks; sanitize PII.

### Security & Secrets
- Never commit secrets. Use `--dart-define` and per-flavor env files.
- Use secure storage for tokens; refresh flows are handled in the HTTP layer.

### Build Flavors and Environments
- Add `dev`, `staging`, `prod` flavors with distinct app ids, icons, and analytics keys.
- Parameterize base URLs and toggles via `--dart-define` and typed env provider.

### CI/CD
- Pipeline steps: `flutter pub get` → `flutter analyze` → `flutter test` → build (per flavor).
- Cache pub artifacts; fail on warnings optionally for protected branches.

### Code Style and Conventions
- File naming: `snake_case.dart`. Widget files end with `_screen.dart` or `_widget.dart`.
- Keep widgets small and composable; extract private sub-widgets for readability.
- Comments: only for non-obvious rationale, invariants, or caveats. No noise comments.
- Public APIs (providers, repositories, domain) should have concise doc comments.

### Repository-wide UX Patterns
- Every data-driven screen implements states: `loading`, `empty`, `error`, `content`.
- Provide pull-to-refresh where data is user-updated.
- Use optimistic updates for low-risk actions with rollback on failure.

---

## Gap Analysis for Current Repo (Implement Next)
Implement these items incrementally; each should be a separate PR where possible.

- Lints: `analysis_options.yaml` is minimal. Add stricter rules listed above.
- HTTP client & error normalization: missing. Create `core/data/http_client.dart` and error types.
- Repository abstraction for API: features currently use `AssetDataProvider`. Add API-backed repos and keep asset-backed impls for offline/dev.
- Env & flavors: add `dev/staging/prod` with `--dart-define` and typed env provider.
- Logging/analytics: introduce `core/providers/logger_provider.dart` and `analytics_provider.dart`.
- Caching: introduce per-feature caching where useful (discover/classes lists, notifications).
- Tests: expand unit and widget tests; add golden tests for shared widgets.
- i18n: ensure all user-facing strings migrate to ARB-backed generated localizations.
- Accessibility: audit screens for semantics, focus traversal, and minimum touch targets.
- CI: add workflow to run analyze/tests on push/PR.

---

## Generation Checklist (Enforce Before Merging)
When generating new code, ensure all of the following are true:

1) Architecture
- New code lives under the correct feature folder; shared code goes in `core/`.
- Providers are typed and minimal; no networking in widgets.

2) Theming & i18n
- No hardcoded colors/strings. Use tokens and ARB keys.

3) Errors & States
- Screens handle `loading/empty/error` consistently using shared widgets.

4) Tests
- New providers/repositories have unit tests; major screens have widget tests.

5) Lints & Docs
- Code passes `flutter analyze`. Public APIs have concise doc comments.

6) Navigation
- Routes added to `app_router.dart` with typed params and names.

7) Performance & Accessibility
- Prefer `const` widgets; check semantics and touch targets.

---

## Quick Prompt (Copy This For Cursor Before Generation)

"""
You are generating code for `skillora-family-mobile` (Flutter, Riverpod, GoRouter, ARB l10n). Follow the project’s engineering standards:

- Use feature-first structure: `lib/features/<feature>/{presentation,domain,data}` and cross-cutting `lib/core/{data,domain,providers,router,theme,widgets}`.
- State: Riverpod (`StateNotifier`/`AsyncNotifier`) with typed states. No networking in widgets.
- Navigation: Update `core/router/app_router.dart` with named routes, typed params, deep links.
- Theming: Use `AppTheme` and `tokens.dart`. No hardcoded colors; prefer `colorScheme`.
- i18n: All user strings from ARB; no hardcoded strings.
- Data: Repositories return domain models; add implementations for asset-backed and API-backed data.
- Errors: Normalize to typed errors; UI shows loading/empty/error with shared widgets.
- Tests: Add unit tests for providers/repositories and widget tests for new screens.
- Lints: Code must pass analyze with strict rules (single quotes, const constructors, no prints).
- Performance & A11y: Avoid unnecessary rebuilds; add semantics and meet WCAG AA.

If an existing pattern in the repo conflicts with these rules, prefer these rules and, if needed, refactor nearby code to maintain consistency.
"""


