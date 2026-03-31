# Verifica Android App Links (QR normale + bibbione)

Questa guida verifica che i link `https://artrosicane.vercel.app/i...` vengano associati correttamente all'app Android.

## Prerequisiti

- Android Platform Tools installati (`adb` disponibile nel PATH)
- Device Android collegato via USB (o emulatore avviato)
- App installata sul device (`com.artrosicane.artrosicane`)
- Connessione internet attiva sul device

## Verifica rapida (script)

```bash
./tool/verify_android_app_links.sh
```

Parametri opzionali:

```bash
./tool/verify_android_app_links.sh com.artrosicane.artrosicane artrosicane.vercel.app "https://artrosicane.vercel.app/i?t=TOKEN_TEST&location=bibbione"
```

## Verifica manuale (stessi step dello script)

1. Reset stato App Links:

```bash
adb shell pm set-app-links --package com.artrosicane.artrosicane 0 all
```

2. Trigger verifica dominio:

```bash
adb shell pm verify-app-links --re-verify com.artrosicane.artrosicane
```

3. Dopo qualche secondo, leggi stato:

```bash
adb shell pm get-app-links com.artrosicane.artrosicane
```

Output atteso (chiave):

```text
artrosicane.vercel.app: verified
```

4. Test apertura deep link:

```bash
adb shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://artrosicane.vercel.app/i?t=TOKEN_TEST&location=bibbione"
```

## Troubleshooting veloce

- `none`: attendi e rilancia `verify-app-links`.
- `legacy_failure` o codici `>= 1024`: ricontrolla `assetlinks.json` (package/fingerprint) e reachability HTTPS.
- Se apre browser invece dell'app:
  - controlla `intent-filter` con `android:autoVerify="true"`, host corretto e `pathPrefix="/i"`
  - assicurati che non ci sia un'altra app già associata allo stesso dominio sul device.
