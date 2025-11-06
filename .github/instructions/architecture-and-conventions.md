---
applyTo: "**/*.dart"
---

# Faunty Project — Architecture, Conventions & Contributor Handbook (v1)

> This document is the authoritative, in-repo reference for how Faunty is structured, how to extend it safely, and the standards expected for code quality, UX, performance and maintainability. Read it end‑to‑end before shipping meaningful changes.

## 1. High-Level Architecture

Faunty is a multi-platform (web + mobile + desktop) Flutter application backed by Firebase (Authentication, Cloud Firestore, Cloud Messaging, Cloud Functions optional). The architecture emphasizes:
- **Reactive UI** via Riverpod providers (all state lives in `lib/state_management/`).
- **Thin Widgets, Explicit Data Flow**: Widgets read providers; business / data logic is in Firestore service classes under `lib/firestore/` and small helpers under `lib/tools/` & `lib/helper/`.
- **Realtime Data**: Firestore snapshot streams mapped into domain models or typed maps.
- **Feature Domains**: Each operational area (kantin, cleaning, catering, program, attendance, survey, feedback, custom lists, place, globals, quota) has:
  - A Firestore service: `X_firestore_service.dart`
  - A provider: `x_provider.dart` (often `StreamProvider` or `StateNotifierProvider`)
  - UI pages/components: under `lib/pages/<domain>/`.
- **Cross-Cutting Concerns**: Localization (Slang), notifications (FCM), theming, update delivery (web auto‑update service), PDF exporting, and role-based gating.

### Data Flow (Conceptual)
```
Firebase Auth → userProvider (authStateChanges + Firestore query)
Firestore (collections) → Firestore Service (domain specific) → Stream<Map|Model>
  → Riverpod Provider (StreamProvider / family) → Widgets (ref.watch)
  → UI Components → User Interaction → Service mutations (set/update)
Localization (Slang) → translation_helper → UI text
NotificationService (FCM) → ForegroundNotificationWrapper → SnackBars/Banners
UpdateService (Web) → Dialog + Hard Refresh (cache bust)
PDF Generation → Domain Data → Layout Strategy → Printing/bytes
```

## 2. Directory Structure & Purpose
| Path | Purpose / Notes |
|------|-----------------|
| `lib/main.dart` | App bootstrap: Firebase init, localization, global services, root navigation, theme mode wiring. |
| `lib/components/` | Reusable UI widgets (AppBar, chips, dropdowns, snackbar, navigation bar, role gate, theming selectors, PDF integrations). Keep stateless unless internal ephemeral state is required. |
| `lib/firestore/` | Firestore service classes; each encapsulates collection paths, queries, write operations, and domain-specific mapping. Keep pure (no BuildContext). |
| `lib/state_management/` | Riverpod providers (StreamProvider, StateNotifierProvider). Providers should be lean orchestration layers over services, not business silos. |
| `lib/models/` | Data classes & enums (plain Dart, serialization). Avoid widget imports. |
| `lib/pages/` | Feature UI pages grouped by domain. Pages compose components + providers. |
| `lib/tools/` | Cross-cutting utilities: translation helper, PDF generation, update service (conditional exports), token extraction scripts, storage helpers, sorting, iframe, etc. |
| `lib/helper/` | Low-level helpers like logging, key normalization, icon registry. |
| `lib/notifications/` | NotificationService (FCM), token management dialogs, foreground UI wrapper. |
| `lib/i18n/` | Generated & source localization files (Slang). Don't hand-edit generated code. |
| `assets/` | Static assets (logos). Update `pubspec.yaml` when adding new assets. |
| `test/` | Widget tests & future unit/integration tests. Expand as features grow. |
| `.github/instructions/` | Copilot & contributor guidance documents. |

## 3. State Management (Riverpod Patterns)
- **Stream Providers**: Real-time Firestore snapshots (e.g., `userProvider`, `kantinProvider`). Use `StreamProvider.family` for place or entity scoped data.
- **State Notifier Providers**: Local ephemeral state with persistence (e.g., `themeProvider`, `languageProvider`). Provide synchronous `state` + async loaders.
- **Avoid Side Effects in build()**: Use `addPostFrameCallback` or internal provider initialization blocks.
- **Backfill / Migration Logic**: Implement idempotent background tasks inside provider initializer closures (see `userProvider` backfill). Guard with SharedPreferences flags.

### Creating a New Provider
1. Decide reactive source (Firestore stream? local prefs? computed?).
2. Add service (if Firestore access). Keep queries & writes inside service.
3. Add provider exposing typed stream or state.
4. Reference in UI via `ref.watch()`; never call Firestore directly in widgets.
5. Handle error/loading states explicitly with `.when(...)`.

## 4. Firestore Access Conventions
- **Collection Structure**: `places/{placeId}/{domainCollection}` (kantin, cleaning, catering, program, attendance, survey, feedback, etc.), user data in `user_list/{userUid}`.
- **Services**: Each service owns its path building & serialization. Example: `KantinFirestoreService.kantinStream()` returns `Stream<Map<String,double>>` for debts.
- **Writes**: Use `SetOptions(merge:true)` when updating singular fields to prevent unintentional overwrites.
- **Batch / Bulk Operations**: Chunk writes (see user authUid backfill) at safe batch sizes (≤500 ops; this code uses 200).
- **Security Rules**: (Not in repo). Enforce role-based privilege server-side; client RoleGate only hides UI.
- **Indexing**: Add composite indexes in Firestore console for new complex queries. Document query & index requirements in service file header.

## 5. Localization (Slang + Helper)
- Use `translation(context: context, 'Some Key')` for all user-facing text (except deliberate raw debugging text). Without context: `translation('Key')`.
- Keys are normalized via `key_normalizer.dart` (case/space transformation). Use natural English phrases as inputs; normalization produces consistent keys.
- Add new phrases then run extraction: `dart lib/tools/extract_t_strings_ast.dart` to collect keys, then run Slang codegen: `dart run slang`.
- Update each language file under `lib/i18n/` with translations.
- Never hardcode dynamic interpolation with args (currently not supported; design for static phrasing or string replacement afterwards if needed).

## 6. Theming & UI
- Theme mode via `themeProvider` (`AppThemeMode.system|light|dark`) persisted in `SharedPreferences`.
- Preset palettes + monochrome modes (see `theme_cards_selector.dart`). Use `ColorScheme.fromSeed` for consistent Material 3 surfaces.
- Prefer `Theme.of(context)` and `colorScheme` tokens over hard-coded colors.
- Custom components should be leightweight, accessible, and reuse typography tokens.
- Navigation with `NavigationBar` + truncation helper `_shortToFit` for long labels.
- Use glass / blur effect AppBar (`CustomAppBar`) for modern style; legacy fallback available.

## 7. Role-Based UI (Authorization Layer)
- `RoleGate` wraps UI, comparing `UserRole` hierarchy indices. Always provide a safe fallback (empty sized box) or explicit denied UI.
- Roles order (privileged → least): superuser < hoca < baskan < talebe < spectator < user < archived < unknown (lower index = higher privilege). Update `RoleGate` and `UserRoleExtension` together if adding roles.
- Never trust the client role for security decisions—server rules must mirror logic.

## 8. Notifications (FCM)
- Initialization deferred until after first frame (to not block start). `NotificationService.init(requestPermissions:false)`; request rights later via UI.
- Web uses VAPID key for token retrieval. Tokens stored with metadata (platform, timestamps) in Firestore (token service not shown here—consult `token_management.dart`).
- `ForegroundNotificationWrapper` surfaces foreground messages with MaterialBanner fallback to overlay/snackbar cascade. Keep user interaction short-lived (auto dismiss timers).
- Only call `fetchTokenIfAllowed` when permission is granted to avoid intrusive prompts on web.

## 9. Update Delivery (Web)
- `UpdateService` polls GitHub Releases (`latest`) every 3 hours + on visibility regain (≥15 min since last check) + manual triggers.
- On detecting a greater semantic version tag vs current `PackageInfo.version`, prompts user to refresh; on confirm, clears service workers & CacheStorage (cache-busting query param) then reloads.
- Use conditional export `update_service.dart` to ship a no-op on non-web platforms.
- This needs to be enhanced as the version number can update without triggering a cache clear reload.

## 10. PDF Generation
- Strategy pattern via `BasePdfLayout` with concrete layouts (`DefaultPdfLayout`, `CateringPdfLayout`, `ProgramPdfLayout`).
- `PdfGenerator.generateAndPrintPdf` uses `Printing.layoutPdf`, building a MultiPage with header/footer toggles.
- Data shape: `Map<String, List<Map<String,dynamic>>>` where top-level key = section/table name. Keep maps flat (primitive / stringifiable values). Provide a custom layout when table formatting diverges.
- UI trigger: `CustomAppBar(onGeneratePdf: ...)` opens `PdfPreviewPage` after data fetch; guard empty content for UX.

## 11. Persistent Local Storage
- `LocalStorageHelper` centralizes theme, language, and future preference keys. Wrap all `SharedPreferences` calls in try/catch (ignore errors quietly). Never duplicate keys inline elsewhere.

## 12. Logging & Error Handling
- Lightweight log helpers: `printInfo`, `printWarning`, `printError` (emoji-coded). Avoid using `print` directly in production code outside these wrappers (except temporary debugging slated for removal).
- User-visible errors → `showCustomSnackBar` (always clear existing snackbars to avoid stacking). For long messages, consider dialogs.
- Avoid crashing builds: catch & ignore non-critical errors in background tasks (e.g., backfill, token fetch). Document silent failure rationale in comments.

## 13. Coding Standards
- **Null Safety**: Embrace explicit Optionals—avoid `!` unless logically proven safe; prefer pattern matching `.when` on AsyncValues.
- **File Naming**: snake_case for files; domain + suffix (e.g., `attendance_provider.dart`, `feedback_firestore_service.dart`).
- **Class Naming**: PascalCase, suffix services with `FirestoreService` and not `Service` alone for Firestore-specific behavior.
- **Providers**: Name as `<domain>Provider` or `<domain>ProviderFamily` when parameterized.
- **Imports**: Prefer relative imports within `lib/` except when package qualifiers improve clarity (internal consistency is acceptable—current code uses package paths frequently). Avoid duplicate imports.
- **Const**: Use `const` constructors & widgets where possible.
- **Magic Strings**: Route names, Firestore collection names and preference keys centralized (where reasonable). Avoid scattering literals.
- **Async**: Use `unawaited()` (from `dart:async`) only when intentionally discarding futures; otherwise await or handle errors.

## 14. Adding a New Domain Feature (End-to-End Workflow)
1. Model: Add a data class in `lib/models/` (immutable, `toMap` / `fromMap`).
2. Firestore Structure: Decide collection path under `places/{placeId}/<newCollection>`; document it in the service header.
3. Service: Create `lib/firestore/<domain>_firestore_service.dart` with streams + CRUD methods.
4. Provider: Add `lib/state_management/<domain>_provider.dart`. Use `StreamProvider.family` if bound to place/user IDs.
5. Pages: Create `lib/pages/<domain>/` UI entry(s). Use `CustomAppBar`, `RoleGate`, and translation helper for all text. Wire provider(s).
6. Navigation: If part of main tabs, update `navigation_bar.dart` and page lists; otherwise add route in `main.dart`.
7. Localization: Add any new strings through code (wrapped in `translation()`), run extraction & `dart run slang`, then fill translations.
8. Permissions: Wrap feature or destructive actions in `RoleGate` with appropriate `minRole`.
9. Testing: Add widget test scaffolding (mount provider + stub Firestore if needed). Verify provider mapping.
10. Docs: Update this document (new collection path, special behaviors) or add a short README in the feature folder if complex. But no READMEs prefered.

## 15. Testing Strategy
- **Widget Tests**: Start from `test/widget_test.dart` pattern. Add tests for: role gating logic, provider-driven widget states, theme or language switching.
- **Service Tests** (Potential): Use Firestore emulator (future) or mock layers (abstract service into interface if testability declines).
- **Localization**: Spot-check existence of expected keys after extraction. Consider a test iterating `t` namespace to ensure no `null` returns for required UI keys.
- **Update Service**: Web-only; consider factoring network fetch into injectable client for easier mocking.

## 16. Performance Guidelines
- Watch provider rebuild scope—prefer finer granularity by splitting large widgets.
- Precompute derived map structures in providers, not builds.
- Avoid heavy synchronous work in hot build paths (move to `addPostFrameCallback` or async tasks).
- Use Firestore queries with `.limit()` when only one document is needed (e.g., user query already uses `limit(1)`).
- Clear banners/snackbars before showing new ones to prevent overdraw/UI jank.
- For large lists, paginate or lazy load (future optimization placeholder).

## 17. Security & Privacy
- Client role logic is UX only. Enforce server-side rules (security rules / Cloud Functions) for writes & sensitive reads.
- Token handling: Never log full FCM tokens in production; mask if necessary. Current code silently stores tokens (review `token_management.dart`).
- Avoid embedding secrets besides Firebase client keys (expected public). VAPID key is public for web.
- Sanitize or validate user-generated fields in backend. Client should avoid trust but keep minimal validation for UX.

## 18. Release & Deployment
- Standard run: `flutter run` (local dev). Ensure Firebase is initialized via `firebase_options.dart`.
- Web build: `flutter build web`.
- Release automation: `release.ps1` (version bump → changelog derive from commit tags `--feat|--fix|--change|--chore` → git push → trigger workflows).
- Hosting-only deploy: `./release.ps1 -HostingOnly` (skips git hygiene; just builds & deploys hosting).
- Manual GitHub Release: Tag format should match semantic version used in `pubspec.yaml` (prefix with `v` acceptable; update service strips leading `v`).

## 19. PDF Export Feature Checklist
- Provide `onGeneratePdf` returning grouped data map.
- Guard empty datasets (`Nothing to export.` snackbar) before navigation.
- Supply custom layout subclass if column logic differs; override header/footer/content methods.
- Keep heavy data preparation async, outside build.

## 20. Common Edge Cases & Patterns
| Area | Edge Case | Handling |
|------|-----------|----------|
| Auth/User | Missing `authUid` field for legacy users | Background backfill + single-doc ensure in `userProvider` |
| Notifications | Permission denied / not determined | Do not force token fetch; UI can prompt later |
| Update Service | Offline / GitHub API failure | Silently ignore; no dialog spam |
| PDF | Empty sections | Early snackbar + abort preview nav |
| RoleGate | User null/loading | Shrink widget or fallback placeholder |
| Localization | Missing key | Falls back to original passed string |

## 21. Contribution Guidelines
- One logical concern per PR; keep diff focused.
- Update tests / add new ones when modifying provider/service behavior.
- Run `flutter analyze` & `flutter test` before pushing.
- Reflect new architectural patterns here instead of ad-hoc README snippets.
- Keep comments high-value (explain why, not what). Remove obsolete TODOs once addressed.

## 22. Future Improvements (Backlog Candidates)
- Firestore emulator integration & service unit tests.
- Domain abstraction interface for uniform CRUD patterns.
- Central route registry & typed navigation wrappers.
- Enhanced error reporting pipeline (Sentry or similar) beyond print helpers.
- Dynamic localization interpolation support (if requirement emerges).
- Paging & caching for high-volume domain collections.

## 23. Quick Reference (Cheat Sheet)
| Task | Steps |
|------|-------|
| Add string | Wrap in `translation()`, run extract script, run slang, translate |
| New domain | Model → Service → Provider → Pages → Nav → Translations → Tests |
| Change theme mode | `ref.read(themeProvider.notifier).setTheme(AppThemeMode.dark)` |
| Generate PDF | Provide `onGeneratePdf` map → `CustomAppBar` → Preview page |
| Request notifications | `NotificationService.checkAndRequestPermission()` then `fetchTokenIfAllowed()` |
| Force update check | `UpdateService.manualCheck(forceDialog:true)` (web) |

## 24. Definition of Done (Feature)
- All user-facing text localized.
- Role gating applied where necessary.
- No analyzer warnings (outside intentional ignores).
- Tests updated / added (minimum: widget smoke or provider logic).
- Changelog prepared if externally visible change (commit message tags used).
- Documentation (this file or inline) updated for new patterns.

---
_Last updated: AUTOGENERATED – refine as architecture evolves._
