# Alternate Reality 2.0

A Flutter app for exploring nine perspectives on a thought, with a separate daily motivation message and reminder. Positive thinking and grammatically correct Literal Negation sit alongside Pessimistic, Cynical, Dark Humor, Worst Case, Uncomfortable Truth, Existential and Sarcastic modes.

## Version 2.0 preview

The signed Android **Preview** app installs separately from the original app. Hosting is deliberately deferred: the included offline preview offers daily motivation, reminder settings and navigation. AI transformations require the later hosted HTTPS backend and an individual invitation. No fake transformations are shown when AI is unavailable.

- [Release, signing and future deployment](docs/RELEASE.md)
- [Guide for friends testing the app](docs/TESTING.md)
- [Local AI development setup](docs/AI_SETUP.md)
- [Daily motivation and platform behavior](docs/DAILY_MOTIVATION.md)
- [Privacy and data handling](docs/PRIVACY.md)
- [Version 2.0 changes](CHANGELOG.md)

## Development

Use Flutter 3.47.1 / Dart 3.13 and Node 24. Run from this folder:

```sh
flutter pub get
flutter run -d chrome --web-port=8080
```

To use AI locally, follow the AI setup guide. Put the provider key only in `server/.env`. For Android use `flutter run --flavor preview`; use `--flavor production` only for the original application identifier. Release builds require a private signing key and never fall back to debug signing.

```sh
flutter analyze
flutter test
node --test server/*.test.mjs
python3 tool/build_release.py --offline
```

The last command produces `build/app/outputs/flutter-apk/app-preview-release.apk` after signing is configured. To create a connected preview later, use `--config config/ai.release.json` instead of `--offline`. A release config contains only the HTTPS backend URL, never a provider key or shared access token.

## Data and platform scope

The latest 500 history entries, selected perspective and notification preferences remain on-device. The server forwards submitted thoughts to OpenAI without recording thought text or responses. Daily messages are offline and rotate through 60 original messages. Android schedules a different message each day around the selected local time (8:00 AM by default); current-reality notifications are independent.

Android is the primary friend-testing target. The web preview supports UI, typed input and connected AI but not background daily notifications; its invitation lasts for the current page session. iOS/macOS source is included but version 2.0 signing, secure storage entitlement setup and notification delivery need platform-specific validation before distributing Apple builds. Windows/Linux are not release targets for this version.

Automated tests mock AI responses. They do not establish real-model grammar, tone or safety quality, or confirm physical-device notification delivery. See the testing checklist before wider distribution.
