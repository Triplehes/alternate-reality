# Build the current app in Android Studio

## Open the right project

Open the **Alternate reality** folder containing `pubspec.yaml` and `lib/main.dart`. On this Mac it is `/Users/mac/Desktop/My App/Alternate reality`.

Do not open `AlternateReality1`: that is a separate Java starter project, not this Flutter app. The `android/` folder is the native host; use the Flutter project root for normal app development. Choose the **Project** view to see `lib/features/` if the Android view hides Dart files.

## Run the current version

1. Let Android Studio finish loading the Flutter project. If it was already open while run configurations changed, close and reopen this project.
2. Select **Alternate Reality - Preview** from the run configuration dropdown.
3. Select your Android emulator or phone, then click Run.
4. Open **Alternate Reality Preview** on the device. The original **Alternate Reality** app is a separate installation and may still contain version 1.0.
5. The current screen shows **Today's motivation**, **One thought. Another perspective.**, **Positive** and **Literal negation**. Settings shows **Alternate Reality 2.0.0**.

The shared configurations live in `.run/` and use `lib/main.dart`:

| Run configuration | Android flavor | Purpose |
| --- | --- | --- |
| Alternate Reality - Preview | `preview` | Current app in a separate installation; offline unless connected configuration is supplied |
| Alternate Reality - Local AI | `preview` | Current app using your ignored `config/ai.local.json` |
| Alternate Reality - Original App | `production` | Same current code, using the original app ID; suitable for updating an older debug installation signed by the same debug key |

The two flavors compile **the same Dart code**. `production` does not mean old code. They differ in Android identity and display name. Do not uninstall the original app just to test Preview; that would remove its local history.

## Why the old screen appeared

The emulator was running package `com.alternatereality.alternate_reality`, version **1.0.0**. The build folder contained an old `app-debug.apk` alongside the new `app-preview-debug.apk` and `app-production-debug.apk` (both version 2.0).

A Flutter run without a flavor asks Gradle for an unflavored build and then looks for the generic `app-debug.apk`. With this old file still present, it can select that stale artifact even though the flavored APKs were rebuilt. The named run configurations now specify a flavor, the existing local `main.dart` run target has been corrected, and Gradle rejects ambiguous build/install tasks with an explanation. Old generic APKs have been moved out of the active Flutter output folder into `build/legacy-apks/` on this Mac.

From a terminal in the Flutter project root:

```sh
flutter run --flavor preview
# Build a debug APK without installing it:
flutter build apk --debug --flavor preview
```

The current debug APK is `build/app/outputs/flutter-apk/app-preview-debug.apk`. For a signed release use the release helper in [RELEASE.md](RELEASE.md). In Android Studio's native Build Variants window choose `previewDebug` or `productionDebug` explicitly.

## Use your local AI server

Follow [AI_SETUP.md](AI_SETUP.md) to start the Node server and set up the ignored `config/ai.local.json`. With a connected emulator/USB phone and a localhost backend URL:

```sh
adb reverse tcp:8787 tcp:8787
```

Then run **Alternate Reality - Local AI**. Start a new run after changing build-time configuration; hot reload cannot change those values. Do not put provider keys or invitation codes into run configurations. Hosting remains deferred; an offline build intentionally disables AI submission while keeping motivation and settings available.

## When changes do not show

First check the project root, selected run configuration, installed app name, and output APK filename. Stop and start the run after native/configuration changes. Use `flutter clean` only when needed for a genuine build-cache issue; it does not correct the wrong project or missing flavor.
