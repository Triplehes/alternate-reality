# Project structure

The Flutter app is organized by feature, with shared infrastructure kept small. Android, iOS, web and desktop host folders stay at the root because Flutter expects those locations.

```text
lib/
  main.dart                      # Entry point
  app/                           # MaterialApp, onboarding gate, navigation shell
  core/
    storage/                     # SharedPreferences loading
    theme/                       # Colors and app theme
    widgets/                     # Shared cards, buttons, branding and layout
  features/
    perspectives/
      domain/                    # Reality modes and saved-entry model
      data/                      # AI client and speech adapter
      application/               # AI wiring and generation/voice controller
      presentation/              # Home and result screens
    history/
      data/                      # Local history repository
      application/               # History/repository providers
      presentation/              # History screen
    motivation/
      domain/                    # Daily message catalog and date selection
      data/                      # Platform scheduling adapter
      application/               # Daily reminder state and persistence
      presentation/              # Today's motivation card
    notifications/
      data/                      # Current-reality notification adapter
      application/               # Shared notification service providers
    settings/
      application/               # Saved mode and notification preferences
      presentation/              # Settings screen and its card widgets
    preview_access/
      application/               # Personal invitation state and secure storage
      presentation/              # Invitation dialog
    onboarding/presentation/     # First-run screens
server/                          # Node backend, prompts, access/quotas, tests
android/                         # Android host and native daily scheduler
config/                          # Safe examples; actual local settings ignored
.run/                            # Shared Android Studio Flutter run targets
test/                           # Flutter regression tests (imports follow feature paths)
tool/                            # Build and local web-serving commands
docs/                            # Setup, testing, privacy and release guides
```

## Where to make changes

- A perspective's label/description: `features/perspectives/domain/reality.dart`.
- AI tone or grammar instructions: `server/prompts.mjs`.
- Request validation/network errors: `features/perspectives/data/ai_service.dart`.
- Generate, regenerate and voice lifecycle: `features/perspectives/application/reality_controller.dart`.
- Daily messages: `features/motivation/domain/daily_motivation.dart`.
- Reminder behavior: motivation's application/data folders and Android's `DailyMotivationScheduler.kt`.
- Settings layout: `features/settings/presentation/`; the main screen assembles separate preference and privacy/about cards.
- Local saving: history's repository; shared preference initialization belongs in `core/storage/`.

## Keep new code organized

Use `domain` for plain models/rules, `data` for storage/network/platform adapters, `application` for state and dependency wiring, and `presentation` for widgets. Only create a layer when the feature needs it. Shared widgets must not depend on individual features. Keep user text out of logs and credentials out of committed configuration.

The former `app_providers.dart` has been replaced by focused provider files. Import the provider from the feature that owns it; do not recreate a global file containing all application behavior. Package imports make dependencies explicit and remain stable when a screen's internal widgets move.

This reorganization preserves provider behavior, preference keys, history format, all nine modes, and both notification types. Generated files, builds, local configuration and signing keys are not source code. The separately created `AlternateReality1/` Java starter is ignored and left untouched.
