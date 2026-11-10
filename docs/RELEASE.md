# Version 2.0 release and deployment

Status: prepared for private Android testing; **hosting is deferred**. No server has been provisioned and no public store release has been made.

## Android signing and builds

The `preview` flavor uses `com.alternatereality.alternate_reality.preview` and the label Alternate Reality Preview. The `production` flavor retains `com.alternatereality.alternate_reality`. Both use version 2.0.0, build 2. Preview installation preserves the original app and its data.

Local release signing is read from `android/key.properties`; the keystore and properties are ignored by Git. Back up both securely outside the repository: losing the key prevents signing updates to an installed preview. Never send these files to testers or commit them. The initial version 2.0 preparation creates these local files if absent. On a fresh checkout, create your own key:

```sh
keytool -genkeypair -v -keystore android/release-keystore.jks -alias alternate-reality -keyalg RSA -keysize 3072 -validity 10000
cp android/key.properties.example android/key.properties
```

Enter the passwords privately in `key.properties`. `storeFile` is relative to `android/`. Release builds fail if signing is missing; no debug-key fallback is permitted.

```sh
# Signed offline package for immediate UI/reminder testing:
python3 tool/build_release.py --offline
# Later: connected preview (after the server below is deployed):
python3 tool/build_release.py --config config/ai.release.json
# Original application identifier, only after distribution readiness review:
python3 tool/build_release.py --production --config config/ai.release.json
```

The preview output is `build/app/outputs/flutter-apk/app-preview-release.apk`. Copy it to `release/Alternate-Reality-2.0.0-preview.apk` for sharing. Release artifacts are ignored by Git. Increment the build number for every subsequent distributed update.

The original app previously used debug signing. A production APK signed with a different key cannot update that installation in place; the separate Preview avoids this problem. Store distribution also needs Play/App Store ownership, signing enrollment and policy review; none was performed here.

## Future HTTPS backend

The server is dependency-free Node 24. Deploy exactly **one instance** behind managed HTTPS with a writable persistent disk at `/data`. The quota file is atomic on a single local filesystem; multiple replicas require shared transactional storage and distributed rate limits. Do not put the server on ephemeral-only storage.

Build from the repository root:

```sh
docker build -f server/Dockerfile -t alternate-reality-api:2.0 .
```

The container runs as the `node` user and listens on port 8787. Give that user write access to `/data` (UID 1000 in this image). Mount a persistent disk there. Keep it private. Supply these values through the hosting provider's secret/environment settings:

| Variable | Value |
| --- | --- |
| `NODE_ENV` | `production` |
| `HOST` | `0.0.0.0` |
| `PORT` | `8787` or the host's port |
| `OPENAI_API_KEY` | Provider secret; server only |
| `OPENAI_MODEL` | `gpt-4.1-mini` or a tested compatible Chat Completions model |
| `INVITE_TOKEN_HASHES` | Comma-separated SHA-256 hashes generated below |
| `ALLOWED_ORIGINS` | Exact HTTPS web app origins; leave empty for native-only testing |
| `USAGE_FILE` | `/data/usage.json` |
| `PER_TESTER_DAILY_LIMIT` | `30` by default |
| `GLOBAL_DAILY_LIMIT` | `300` by default |
| `REQUESTS_PER_MINUTE` | `20` globally by default; also 5/min per invitation and 3 concurrent globally |

Production ignores `BACKEND_ACCESS_TOKEN`. A shared token is allowed only for local development. Requests that reach the provider consume a daily slot even if the provider fails, because they may incur cost. Limits reset at midnight UTC. Minute limits reset on restart; daily counts survive restart when the persistent disk is retained. Use provider project budgets/alerts as an additional cost control. Do not log request bodies or Authorization headers in hosting/proxy logs. Configure host-level request limits before exposing the service broadly.

`GET /healthz` is a liveness endpoint; it does not call OpenAI or prove a valid provider key. `POST /access` validates an invitation without a paid request. Validate one real non-sensitive transformation after deployment.

## Personal invitations

Run locally once for each tester:

```sh
node server/invite.mjs
```

This prints a random personal code and its SHA-256 hash. Share only the personal code with that tester through your chosen private channel. Put only the hash in `INVITE_TOKEN_HASHES`; restart/redeploy after changes. Removing one hash revokes that tester's code while other invitations continue working. Do not paste invitation codes into issues, screenshots or build configuration. This is bearer access for a small private beta, not public account identity.

Create ignored `config/ai.release.json` containing only:

```json
{"AI_BACKEND_URL":"https://YOUR-REAL-BACKEND-HOST"}
```

The release helper rejects local HTTP, placeholder domains and extra keys. The Flutter release client also ignores the development `AI_BACKEND_TOKEN`. Each tester enters their invitation at runtime. Android saves it in secure storage; browser previews require re-entry after reload.

## Before wider distribution

- Run Flutter analysis/tests, Node tests and a signed APK build. The GitHub workflow also checks and builds the offline web preview; it uses no secrets.
- Test a hosted real-model call in all nine modes, supported languages, and grammar/safety edge cases. Existing automated tests mock the provider.
- Run the physical-device checklist in TESTING.md, especially both notifications, permission denial, midnight, reboot, battery restrictions and time-zone changes.
- Verify the deployed HTTPS endpoint, persistent volume, invitation revocation, limits and provider spending controls.
- Review a public privacy policy with the operator's contact details and actual hosting retention behavior. Add broader moderation and abuse monitoring before public anonymous distribution.
- Rotate any keys or access tokens previously exposed in screenshots; sanitized examples cannot revoke an already exposed secret.
- Apple builds need signing, verification of the included Keychain entitlements and real-device testing. They are not included in this Android preview delivery.

References: [Flutter Android deployment](https://docs.flutter.dev/deployment/android), [secure storage package](https://pub.dev/packages/flutter_secure_storage/versions/10.3.4).
