---
applyTo: "**/.dart"
---

# Faunty Flutter Project — Copilot Instructions

## Project Overview
Faunty is a modern Flutter app for team and organization management, built for usability, real-time collaboration, and beautiful design.

For more information, see the main [README.md](../../README.md) in the project root.

## Context Convention
- **Always use the `lib` folder as the default context for file references, code searches, and edits unless otherwise specified.** When the user asks about a file or code, assume it is in the `lib` folder unless they provide a different path.
- **If you cannot find a file or resource, first take the project as whole into context and ask for clarification or additional context if you still could not find anything.**


## Architecture & Key Patterns
- **State Management:** Riverpod (`lib/state_management/`). Providers stream Firestore data (see `user_provider.dart`, `kantin_provider.dart`).
- **Firestore Services:** Each domain (kantin, cleaning, catering, etc.) has a service in `lib/firestore/`. Data structure: `places/{placeId}/{domain}` and `user_list/{userUID}`.
- **UI Components:** Use widgets from `lib/components/` (e.g., `custom_chip.dart`, `custom_app_bar.dart`) for UI consistency.
- **Pages:** Feature screens are grouped by domain in `lib/pages/`. Main navigation is in `main.dart` and `components/navigation_bar.dart`.
- **Notifications:** Use OneSignal via the provider-agnostic API in `lib/notifications/` (see `notification_manager.dart`, `notification_provider.dart`). Define notification types in `lib/notifications/types/`. Do not use deprecated FCM code.
- **Localization:** All user-facing strings must use `translation()` from `lib/tools/translation_helper.dart`. Add new keys via `lib/tools/extract_t_strings_ast.dart`.
- **Testing:** Widget tests are in `test/widget_test.dart`. Use `flutter test` for running tests.


## Developer Workflows
- **Build & Run:** Use standard Flutter commands (`flutter run`, `flutter build web`). For web deployment, use `release.ps1` (PowerShell script) to build and deploy to Firebase Hosting.
- **Firebase Setup:** App initialization is in `main.dart` using `firebase_options.dart`. Firestore and Auth are required for most features.
- **i18n:** Add new translation keys to all language files in `lib/i18n/`. Use Slang for codegen (`dart run slang`). Discover new keys with `dart lib/tools/extract_t_strings_ast.dart`.


## Project-Specific Conventions
- **Provider Usage:** Always use Riverpod's `ref.read`/`ref.watch` for state. Streams from Firestore are mapped to domain models.
- **Custom Components:** Prefer using widgets from `lib/components/` for UI consistency.
- **Translation:** All user-facing strings (except intentionally hardcoded ones) must use the translation helper. If no context, just pass the string.
- **Error Handling:** Use `showCustomSnackBar` for user-visible errors. For debug logging, use `lib/helper/logging.dart`.
- **External Links:** Use `url_launcher` with `canLaunchUrl`/`launchUrl` (not deprecated `canLaunch`). Wrap in try/catch for reliability.
- **Theme & Colors:** Use `Theme.of(context)` for colors whenever possible to ensure consistent theming.
- **Notifications:** Implement new notification types by extending `AppNotification` in `lib/notifications/types/`. Use OneSignal provider, avoid deprecated code.
- **Code Examples:** When creating something new (e.g., providers, StreamProviders, or a new page in the `pages` folder), look at similar examples in the codebase and follow their patterns for consistency.


## Integration Points
- **Firebase:** All data flows through Firestore collections. Structure: `places/{placeId}/{domain}` (kantin, cleaning, catering, program, etc.), and `user_list/{userUID}` for user data fields. See Firestore service files for details.
- **Riverpod:** Providers connect UI to Firestore streams for real-time updates.
- **Slang:** Handles all localization; see `lib/tools/translation_helper.dart` for usage.


## Examples
- **Provider Pattern:** See `lib/state_management/user_provider.dart` for real-time user updates.
- **Firestore Service:** See `lib/firestore/kantin_firestore_service.dart` for debt logic and Firestore structure.
- **Custom Chip:** See `lib/components/custom_chip.dart` for reusable UI chips with click handlers.
- **Notification Type:** See `lib/notifications/types/`
- **Translation:** `translation(context: context, 'Key')` or just `translation('Key')` if no context.

## Build & Deploy
- Local: `flutter run`
- Web: `flutter build web`
- Deploy: `pwsh release.ps1` (PowerShell) or `pwsh release_hosting.ps1` for Firebase Hosting.

---

For questions about unclear conventions or missing patterns, ask the user for clarification or examples.
