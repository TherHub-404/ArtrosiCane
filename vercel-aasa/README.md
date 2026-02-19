# Vercel AASA Host

This folder hosts the Apple App Site Association file for iOS Universal Links and App Clip testing.

## Deploy

```bash
npx vercel deploy . --prod -y
```

## Verify

```bash
curl -i https://artrosicane.vercel.app/.well-known/apple-app-site-association
```

Expect:
- HTTP 200
- Content-Type: application/json
- No redirect
