# Alternate Reality

A polished, cross-platform Flutter experience that turns a thought into a concise pessimistic, cynical, darkly funny, or uncomfortable alternate interpretation. It includes voice input, seven reality modes, an animated result experience, a single persistent current reality, local history, and platform-compliant notifications.

> The app is creative entertainment, not advice or prophecy. Inputs suggesting self-harm or immediate danger are routed to a supportive response instead of a negative transformation.

## Screenshots

Place release screenshots in `docs/screenshots/`.

## Requirements

- Flutter 3.47.1 or compatible stable release
- Dart 3.13.1+
- Xcode for iOS/macOS, Android Studio SDK for Android, and the normal Flutter desktop toolchains

## Setup

```sh
flutter pub get
flutter run
```

Without an API key the app remains fully usable with a deterministic, safety-aware local fallback. To use an OpenAI-compatible backend during development:

```sh
flutter run \
  --dart-define=AI_API_KEY=your_development_key \
  --dart-define=AI_BASE_URL=https://api.openai.com/v1 \
  --dart-define=AI_MODEL=gpt-4.1-mini
```

Do not ship a production secret in a mobile or web binary: `--dart-define` values can be extracted. For production, point the provider abstraction in `lib/services/ai_service.dart` at a backend you control, keep credentials server-side, authenticate clients, and apply rate limiting. `.env.example` documents the expected names and contains no secret.

## Architecture

- `lib/domain`: reality entities and modes
- `lib/data`: local repository implementation
- `lib/services`: AI, speech, and notification abstractions/adapters
- `lib/providers`: Riverpod state and orchestration
- `lib/presentation`: onboarding, home, result, history, settings, and reusable visual components

History is local in SharedPreferences and the latest entry is marked current. User thoughts are not printed or logged. A successful shift replaces the fixed notification ID, so the OS shows the latest reality rather than stacking messages.

## Platform setup and limitations

- **Android:** microphone, internet, and notification permissions are declared. Android 13+ asks for notification permission on first use. The notification uses `ongoing`; OS/device policy still controls whether it may be dismissed.
- **iOS:** microphone and speech usage descriptions are included. iOS does not permit a permanently ongoing local notification; delivery and persistence follow system policy.
- **macOS:** microphone usage text is included. Signing/sandbox entitlements may need adjustment for a chosen distribution profile.
- **Windows/Linux:** package support varies with host speech engines and notification daemons. Typed input and local history always remain available.
- **Web:** typed input, AI, storage, and UI work. The current adapter deliberately skips local notifications; browser notification/service-worker behavior should be implemented for a production web deployment. Speech availability depends on the browser.

Permissions are requested only when their related feature is used.

## Quality commands

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build macos   # or apk, ios, web, windows, linux
```

## Privacy and safety

History remains on-device unless a future cloud feature is explicitly added. When an AI backend is configured, the submitted thought is sent to that provider for transformation. The system prompt prohibits escalation of self-harm, suicide, violence, abuse, criminal activity, threats, and dangerous instructions. Production deployments should also add server-side moderation and observability that avoids storing raw personal thoughts.
