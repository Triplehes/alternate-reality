# Connect Alternate Reality to AI

The app has nine independent modes: Pessimistic, Cynical, Dark Humor, Worst Case, Uncomfortable Truth, Existential, Sarcastic, Positive, and Literal Negation.

Literal Negation asks the model to reverse the main assertion with correct grammar, tense and agreement. It does not run a search-and-replace rule. Already-negative assertions are normally inverted to affirmative ones. Safety overrides apply in every mode.

## 1. Put the OpenAI key on the server

Install Node.js 22 or later. No npm installation is needed. From the project folder:

```sh
cp server/.env.example server/.env
openssl rand -hex 32
```

Open `server/.env` in your editor. Set:

```dotenv
OPENAI_API_KEY=your_real_openai_api_key
OPENAI_MODEL=gpt-4.1-mini
BACKEND_ACCESS_TOKEN=the_random_value_you_generated
HOST=127.0.0.1
PORT=8787
ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080
```

Create your provider key in the [OpenAI API dashboard](https://platform.openai.com/api-keys). Your account must have API access and billing/quota available. Keep this file private. It is ignored by Git. Do not paste a provider key into the app, chat, screenshots, `pubspec.yaml`, or `--dart-define` flags.

`OPENAI_MODEL` is configurable. The existing project's `gpt-4.1-mini` model is retained for continuity, not a claim that it is the newest model. Check availability for your account before changing it. Restart Node after editing the server environment.

Start the server from the project root:

```sh
node --env-file=server/.env server/server.mjs
```

Leave this terminal running. The server listens on port 8787. It loads the key from `server/.env`; the root `.env.example` is only a pointer to these instructions.

## 2. Connect a test build

In a second terminal, from the project root:

```sh
cp config/ai.example.json config/ai.local.json
```

For local testing, edit `config/ai.local.json` to contain:

```json
{
  "AI_BACKEND_URL": "http://127.0.0.1:8787",
  "AI_BACKEND_TOKEN": "the_same_BACKEND_ACCESS_TOKEN_from_server_env"
}
```

**This token is not your OpenAI API key.** Use it only in local debug builds. Version 2.0 release builds ignore it and use personal invitations with quotas; see [release and deployment](RELEASE.md). Do not distribute builds containing a shared development token.

Both local configuration files are ignored by Git. Changes to client configuration require a fresh `flutter run` or rebuild; hot reload does not change build-time configuration.

### Test in Chrome

```sh
flutter run -d chrome --web-port=8080 --dart-define-from-file=config/ai.local.json
```

Use the exact browser origin allowed by `ALLOWED_ORIGINS`. For another browser port, update that variable and restart the server. CORS restricts browsers; the access token protects the API separately.

### Test on an Android phone by USB

Enable USB debugging, connect the phone, and allow the computer on the phone. Run:

```sh
adb reverse tcp:8787 tcp:8787
flutter devices
flutter run --flavor preview -d YOUR_ANDROID_DEVICE_ID --dart-define-from-file=config/ai.local.json
```

Replace `YOUR_ANDROID_DEVICE_ID` with the value shown by `flutter devices`. Keep the USB connection and Node server running. Only debug Android builds allow HTTP for localhost, 127.0.0.1 and the emulator alias 10.0.2.2. For an Android emulator, use `http://10.0.2.2:8787` as the URL instead.

### Use a release APK away from your computer

A phone cannot reach your Mac through localhost without USB forwarding. Version 2.0 requires a hosted HTTPS backend, a release config containing only its URL, and a personal invitation for each tester. Follow [release signing and deployment](RELEASE.md). Hosting is deferred for the initial offline preview.

## 3. Confirm the behavior

Connection configuration belongs in the developer files and is not displayed in Settings. Submit a thought to verify an actual successful model call.

Check these examples in Literal Negation, allowing equivalent grammatical wording:

| Input | Expected meaning |
| --- | --- |
| She enjoys her job. | She does not enjoy her job. |
| I went to work. | I did not go to work. |
| I didn't go to work. | I went to work. |
| They have finished. | They have not finished. |
| He is ready. | He is not ready. |

Try the same input in Positive, Pessimistic, Cynical and Dark Humor. Confirm that the topic stays the same and the perspective changes. Positive should acknowledge difficulties without promising success. Questions/fragments with no clear assertion may produce a request for a clearer statement. Models can still make grammar or interpretation mistakes; these checks need a live API connection.

Regeneration uses the original thought and its original mode. A failed request preserves the previous result and creates no new history entry. Safety prompts apply to every mode, including inversion of already-negative text. The fast local safety check is a limited keyword safeguard, not comprehensive risk detection; broader production moderation/evaluation remains necessary before public distribution.

## Troubleshooting

- **AI unavailable / not connected:** as the developer, rebuild with a valid backend URL and the correct access token. Release builds reject HTTP and ignore the development token; use a personal invitation.
- **Server needs an API key:** fill `OPENAI_API_KEY` in `server/.env` and restart Node.
- **Connection refused / cannot reach:** confirm Node is running, the URL is reachable, and USB forwarding or HTTPS hosting is active.
- **Access refused:** verify the matching backend token and, for browsers, the exact allowed origin.
- **AI could not create a perspective:** check provider key validity, available credits/quota and model access. Raw provider errors are deliberately not shown in the app.
- **Wait a minute:** the personal backend permits 20 authenticated requests per minute and at most three in flight. Requests that fail validation also consume a rate-limit slot.

No thoughts or generated results are logged by this server. History stays on the device; submitted thoughts and model output are still processed by the AI provider. Requests use `store: false`; that does not override the provider's other retention policies.

## Verification commands

```sh
flutter analyze
flutter test
node --test server/*.test.mjs
```

Automated tests use a mocked provider, so they do not spend API credits or establish real-model grammar/tone quality.

Provider references: [API authentication](https://developers.openai.com/api/reference/overview), [Chat Completions](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create).
