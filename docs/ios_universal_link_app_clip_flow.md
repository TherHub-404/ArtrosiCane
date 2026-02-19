# iOS Universal Link + App Clip Token Flow

This document matches the implementation in this repo and the required production flow:

- QR URL format: `https://artrosicane.vercel.app/i?t=TOKEN&location=bibbione`
- App installed: Universal Link opens full app and passes `TOKEN` to Flutter
- App not installed: App Clip opens, validates token, stores pending token in App Group, shows install CTA
- Full app launch/open: fetch/redeem flags from backend and persist state idempotently

## Part A: Server files and requirements

### `https://artrosicane.vercel.app/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TEAMID>.com.company.app",
        "paths": [
          "/i",
          "/i/*"
        ]
      }
    ]
  },
  "appclips": {
    "apps": [
      "<TEAMID>.com.company.app.Clip"
    ]
  }
}
```

Requirements:
- Serve exactly at `/.well-known/apple-app-site-association` (no `.json` extension).
- Response header: `Content-Type: application/json`.
- HTTPS only with valid public certificate.
- No redirects (no 301/302/307).
- Ensure Apple can access it publicly.

## Part B: Full app (Runner target) setup

### Xcode checklist (Runner target)

1. Open `ios/Runner.xcworkspace` in Xcode.
2. `Runner` target -> `Signing & Capabilities`:
   - Add `Associated Domains` with: `applinks:artrosicane.vercel.app`
   - Add `App Groups` with: `group.com.company.app`
3. Keep bundle id aligned with AASA appID (e.g. `com.company.app` in production).
4. Ensure Team ID in signing matches `<TEAMID>` used in AASA.

### Repo changes already applied

- `ios/Runner/AppDelegate.swift`:
  - Handles Universal Links in `application(_:continue:restorationHandler:)`
  - Bridges link URL to Flutter via `MethodChannel("com.company.app/deeplink")`
  - Supports buffered delivery with `consumeInitialLinks`
  - Reads `pending_invite_token` from App Group and forwards to Flutter at launch
- `ios/Runner/Runner.entitlements`:
  - `com.apple.developer.associated-domains`: `applinks:artrosicane.vercel.app`
  - `com.apple.security.application-groups`: `group.com.company.app`
- `ios/Runner.xcodeproj/project.pbxproj`:
  - `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` for Debug/Release/Profile
- `ios/Runner/SceneDelegate.swift`:
  - Optional bridge for scene-based templates (`scene(_:continue:)`)

## Part C: Flutter/Dart deep link + token handling

### Added dependencies

- `app_links`
- `http`
- `uuid`

### Added files

- `lib/core/linking/feature_flags_state.dart`
- `lib/core/linking/feature_flags_controller.dart`
- `lib/core/linking/link_service.dart`

### Startup integration

- `lib/app.dart`: app now starts `LinkService` in `initState`.

### Behavior implemented

- Cold start + resume links from:
  - `app_links` initial link
  - `app_links` stream
  - iOS native `MethodChannel` fallback (`onDeepLink`)
  - iOS buffered initial links (`consumeInitialLinks`)
- URL validation:
  - scheme `https`
  - host `artrosicane.vercel.app` (configurable)
  - path `/i` (configurable)
  - query param `t`
  - optional query param `location` (stored in app state)
- Backend flow:
  - `POST /redeem { token, deviceId }`
  - fallback to `GET /flags?token=...` for idempotent/replayed tokens
- Persistence:
  - stores flags and last token in `SharedPreferences`
  - provider exposes current flags and status across app

### Config keys added

In `.env` / `.env.example`:

- `INVITE_API_BASE_URL` (default `https://api.example.com`)
- `INVITE_DOMAIN` (default `artrosicane.vercel.app`)
- `INVITE_PATH` (default `/i`)

## Part D: App Clip target implementation

Create target in Xcode:

1. `File -> New -> Target... -> App Clip`
2. Bundle id: `com.company.app.Clip`
3. Signing/Team: same `<TEAMID>` as full app
4. `Signing & Capabilities` (App Clip target):
   - Add `App Groups` -> `group.com.company.app`
   - Add `Associated Domains` if needed by your template/invocation path
5. Keep invocation URL on the same associated domain (`artrosicane.vercel.app`).

Use these Swift files in the App Clip target:

- `ios/AppClip/AppClipApp.swift`
- `ios/AppClip/ClipInvocationModel.swift`
- `ios/AppClip/ClipContentView.swift`

Implemented App Clip behavior:
- Parses invocation URL and extracts `t`
- Calls `GET https://api.example.com/validate?t=TOKEN`
- Stores `pending_invite_token` in `UserDefaults(suiteName: "group.com.company.app")`
- Stores optional `pending_invite_location` in the same App Group defaults
- Presents “Get full app” CTA using `SKOverlay` (fallback App Store URL)

## Part E: Full app pickup from App Group

Implemented in `ios/Runner/AppDelegate.swift`:

- On launch reads App Group key `pending_invite_token`
- Reads optional App Group key `pending_invite_location`
- Converts to `https://artrosicane.vercel.app/i?t=...&location=...`
- Sends through method channel to Dart
- Clears key afterward

This covers the post-install/open path when deferred deep link is not available.

## Backend API assumptions used by code

- `GET /validate?t=TOKEN` -> `{ "valid": true, ... }`
- `POST /redeem` body `{ "token": "...", "deviceId": "..." }` -> `{ "flags": { ... } }`
- `GET /flags?token=TOKEN` -> `{ "flags": { ... } }`

## Security requirements (must hold in production)

- Token is random (>= 128-bit entropy), never semantic/plaintext flags.
- Token expiration + optional single-use semantics enforced server-side.
- Rate limiting and revocation support on validation/redeem endpoints.
- TLS everywhere and strict input validation/audit logging.
