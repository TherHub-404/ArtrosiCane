# Vercel AASA + Asset Links Host

This folder hosts:
- Apple App Site Association file for iOS Universal Links / App Clip
- Android Digital Asset Links file for Android App Links

## Deploy

```bash
npx vercel deploy . --prod -y
```

## Verify

```bash
curl -i https://artrosicane.vercel.app/.well-known/apple-app-site-association
curl -i https://artrosicane.vercel.app/.well-known/assetlinks.json
```

Expect:
- HTTP 200
- Content-Type: application/json
- No redirect

## Android App Links setup note

`public/.well-known/assetlinks.json` must contain the SHA-256 certificate
fingerprint used to sign the app distributed by Google Play.

Current value in repo is the upload key fingerprint found in local project
secrets.

Before production rollout, verify it matches the Play App Signing key from:
Play Console -> Setup -> App integrity -> App signing key certificate.

If it differs, update `sha256_cert_fingerprints` accordingly.
