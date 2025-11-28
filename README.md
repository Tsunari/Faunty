<p align="center">
  <img src="assets/Logo.png" alt="Faunty Logo" width="120" />
</p>

<p align="center">
  <a href="https://img.shields.io/github/v/release/Tsunari/Faunty-2.0"><img src="https://img.shields.io/github/v/release/Tsunari/Faunty-2.0?label=Latest%20Release" alt="Latest Release"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-Stable-blue?logo=flutter" alt="Flutter"></a>
  <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-Enabled-yellow?logo=firebase" alt="Firebase"></a>
  <a href="https://riverpod.dev"><img src="https://img.shields.io/badge/Riverpod-State%20Management-green" alt="Riverpod"></a>
  <a href="https://github.com/slang-i18n/slang"><img src="https://img.shields.io/badge/i18n-Slang-orange" alt="Slang"></a>
  <a href="#license"><img src="https://img.shields.io/badge/License-Private-inactive" alt="License"></a>
    <a href="https://img.shields.io/github/last-commit/Tsunari/Faunty-2.0"><img src="https://img.shields.io/github/last-commit/Tsunari/Faunty-2.0?label=Last%20Commit" alt="Last Commit"></a>
  <a href="https://img.shields.io/github/languages/top/Tsunari/Faunty-2.0"><img src="https://img.shields.io/github/languages/top/Tsunari/Faunty-2.0?label=Dart" alt="Top Language"></a>
  <a href="https://img.shields.io/github/issues-pr/Tsunari/Faunty-2.0"><img src="https://img.shields.io/github/issues-pr/Tsunari/Faunty-2.0?label=PRs" alt="Pull Requests"></a>
</p>

# Faunty — Flutter App for Teams

Faunty is a modern Flutter application for team and organization management. It focuses on real-time collaboration, clear modular architecture, and a consistent, beautiful UI.

## Highlights

- **Firebase-first:** Auth, Firestore, Cloud Messaging, and Cloud Functions
- **Reactive by design:** Riverpod providers stream live data into the UI
- **Internationalized:** Slang-based i18n with automated key extraction
- **Modular domains:** Separate features for kantin, cleaning, catering, program, etc.
- **Reusable UI:** Centralized components for consistency and speed

## Tech Stack

- **Flutter/Dart:** App UI and logic (Dart SDK constraint: `^3.8.1`)
- **Firebase:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`, `cloud_functions`
- **State:** `flutter_riverpod`
- **i18n:** `slang`, `slang_flutter`
- **Utilities:** `url_launcher`, `webview_flutter`, `shared_preferences`, `package_info_plus`, `intl`, `http`, `rxdart`, `uuid`

## Architecture

- **State Management:** Riverpod providers live in `lib/state_management/` (e.g., `user_provider.dart`, `kantin_provider.dart`) to expose Firestore streams and app state.
- **Firestore Services:** Per-domain services in `lib/firestore/` handle reads/writes against the structure below.
- **UI Components:** Shared widgets in `lib/components/` (app bar, chips, dialogs, inputs, navigation, role gates, etc.).
- **Pages:** Feature screens grouped by domain in `lib/pages/`.
- **Localization:** Use the `translation()` helper from `lib/tools/translation_helper.dart` for all user-facing strings.

### Firestore Layout

- `places/{placeId}/{domain}` — Domains include `kantin`, `cleaning`, `catering`, `program`, etc.
- `user_list/{userUID}` — User-specific data as document fields.

## Project Structure (selected)

```
lib/
  components/         # Reusable UI widgets
  firestore/          # Domain Firestore services
  functions/          # Cloud Functions (Node 22)
  helper/             # Logging and helpers
  i18n/               # Slang-generated localization
  models/             # App models
  notifications/      # Push notifications logic
  pages/              # Feature pages by domain
  state_management/   # Riverpod providers
  tools/              # i18n extraction, update service, 
  main.dart           # App entry
```

## Getting Started

### Prerequisites

- Flutter SDK and tooling
- Firebase CLI (`firebase`)
- Node.js 22+ for Cloud Functions (see `lib/functions/package.json`)
- For Android: Android SDK / Java; For iOS/macOS: Xcode/CocoaPods

### Setup

1) Install dependencies

```pwsh
flutter pub get
```

2) Configure Firebase (if needed) using FlutterFire

```pwsh
flutter pub global activate flutterfire_cli
flutterfire configure
```

This generates/updates `lib/firebase_options.dart` and platform configs. The repo already contains `firebase_options.dart` for the current project.

3) Run the app

```pwsh
flutter run
```

### Web Build & Hosting

```pwsh
flutter build web
firebase deploy --only hosting
```

Alternatively, use the release script below for a guided flow.

## Development Workflow

### Common Commands

- Run app: `flutter run`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Build web: `flutter build web`

### VS Code Tasks

Tasks are preconfigured (Terminal > Run Task):

- `Flutter: Run` — `flutter run`
- `Flutter: Build Web` — `flutter build web`
- `Flutter: Analyze` — `flutter analyze`
- `Flutter: Test` — `flutter test`
- `i18n: Extract Keys (AST)` — `dart lib/tools/extract_t_strings_ast.dart`
- `i18n: Generate (slang)` — `dart run slang`
- `Firebase: Deploy Web (release.ps1)` — `pwsh release.ps1`

### Release Script

Use `release.ps1` for version bumping, changelog generation, and CI triggers.

Examples:

```pwsh
# Full flow (prompts for version bump, updates CHANGELOG, pushes, triggers workflows)
pwsh release.ps1

# Hosting-only quick deploy (cleans build/, builds web, deploys hosting)
pwsh release.ps1 -HostingOnly

# Bypass clean working tree check (use sparingly)
pwsh release.ps1 -force
```

## Internationalization (Slang)

- Use `translation()` from `lib/tools/translation_helper.dart` for all strings.
- Discover new keys by scanning the codebase:

```pwsh
dart lib/tools/extract_t_strings_ast.dart
```

- Generate localization files:

```pwsh
dart run slang
```

- Add translations under `lib/i18n/` for each supported language.

## Cloud Functions

- Location: `lib/functions/` (Node `22`).
- Install and deploy:

```pwsh
cd lib/functions
npm i
npm run deploy   # or: firebase deploy --only functions
```

- Emulate locally:

```pwsh
npm run serve
```

## Notifications (Web)

- Web assets include `web/firebase-messaging-sw.js` and runtime config in `build/web/` after builds.
- Ensure Firebase Messaging is properly configured for web push if used.

## Troubleshooting

- If a web deploy serves stale assets, clear the `build/` folder and rebuild:

```pwsh
Remove-Item -Recurse -Force build
flutter pub get
flutter build web
```

- Validate Firebase setup by confirming `lib/firebase_options.dart` is present and matches your project.

- .env file is not included in the repository. Currently OneSignal API key is used.

## Contributing

Contributions are welcome. Please follow existing patterns:

- Prefer components in `lib/components/` and providers in `lib/state_management/`.
- Keep Firestore access in `lib/firestore/` services.
- Add/adjust i18n keys and run Slang codegen.
- Include tests for user-facing features where applicable.

## License

This repository is licensed for private use.

—

For questions or feedback, please open an issue or contact the maintainer.
