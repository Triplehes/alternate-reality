# Reality Modes Implementation Plan

> Execute inline in this session; the user approved the design and added grammatical literal negation.

**Goal:** Nine distinct AI modes, including Positive and Literal Negation, with a server-held API key and clear connection errors.

**Architecture:** Flutter sends only `{input, mode}` to a small Node HTTP backend. The backend owns prompts and OpenAI credentials. No silent local rewrite remains. Existing mode names and saved history remain compatible.

**Tech stack:** Existing Flutter/Riverpod/http, Node 22+ built-in HTTP/fetch/test modules; no new package dependencies.

**Approved design:** Keep the current visual style; replace negative-only home copy, expose all modes, describe the selected mode, document API setup. Literal Negation uses grammatical inversion of the main assertion while preserving tense and subject; Positive is grounded encouragement. Safety overrides every mode.

## Tasks

- [x] Backend: add `server/prompts.mjs`, `server/server.mjs`, `server/server.test.mjs`, and `server/.env.example`. Validate mode/input, authenticate a personal-use client token, bound requests, limit usage, handle upstream errors, and never log thoughts or credentials. Run `node --test server/server.test.mjs` with a mocked upstream; no paid calls.
- [x] Flutter: replace the literal fallback with `BackendAIService`, add Positive/Literal Negation enum values and descriptions, surface configuration/network errors, protect regeneration from stale/duplicate responses, and update the home/settings copy and mode selection. Test request mode routing, stored-history compatibility, validation, errors, mode selection, and regeneration.
- [x] Setup and validation: replace client API-key documentation with server environment instructions and a client-only URL/access-token example. Explain local web, Android USB debug, and HTTPS phone builds. Run formatter, Flutter analysis/tests, Node tests, and inspect a rendered mobile view. Apply only changed files to the source checkout after validation; preserve the existing staged artifact. Do not commit or push unless requested.

## Verification limits

Mock responses verify wiring, not a real model's language quality. Without a configured provider key, report live grammar/tone evaluation as outstanding. Never claim an app build is configured for AI without a working backend.

Validation: Flutter analysis clean; 15 Flutter tests and 9 Node tests passed. Mobile widget renders inspected at 390 x 844. No live provider call was made. No APK was rebuilt.
