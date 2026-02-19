# TestFlight: guida step-by-step per testare QR scan (Universal Link + App Clip)

Questa guida è per lo scenario in cui l'app è su **TestFlight** e non ancora pubblicata su App Store.

## 0) Prerequisiti

1. Build iOS caricata su TestFlight (full app) con:
   - Associated Domains: `applinks:artrosicane.vercel.app`
   - App Group: `group.com.company.app`
2. (Se testi il path App Clip) la build include anche App Clip target.
3. AASA raggiungibile:
   - `https://artrosicane.vercel.app/.well-known/apple-app-site-association`
4. Token reale creato dal backend (random, time-limited).

## 1) Prepara i link da codificare nel QR

Usa questi formati:

- Con sfondo Bibbione:
  - `https://artrosicane.vercel.app/i?t=TOKEN_VALIDO&location=bibbione`
- Senza sfondo Bibbione (bianco):
  - `https://artrosicane.vercel.app/i?t=TOKEN_VALIDO`
  - oppure `https://artrosicane.vercel.app/i?t=TOKEN_VALIDO&location=altro`

Note:
- `t` è obbligatorio.
- `location` è opzionale.
- Se `location=bibbione` (case-insensitive), in Home appare lo sfondo Bibbione.

## 2) Genera il QR

1. Prendi il link completo.
2. Genera un QR (qualsiasi tool QR va bene).
3. Mostralo su un secondo device/schermo o stampalo.

## 3) Test path A: app già installata (Universal Link)

1. Installa la build da TestFlight sul dispositivo.
2. Apri Camera iOS e inquadra il QR.
3. Tocca il banner del link `artrosicane.vercel.app`.
4. Verifica:
   - si apre la full app (non Safari)
   - token viene processato (redeem/flags)
   - con `location=bibbione` Home usa sfondo Bibbione
   - senza `location=bibbione` Home resta bianca

## 4) Test path B: app NON installata (App Clip)

1. Disinstalla la full app dal dispositivo.
2. Inquadra lo stesso QR con Camera.
3. Verifica che si apra App Clip.
4. In App Clip verifica:
   - token validato su `/validate`
   - salvataggio in App Group di:
     - `pending_invite_token`
     - `pending_invite_location` (se presente)
5. Tocca “Get full app”.

## 5) Nota importante su TestFlight (prima della pubblicazione App Store)

Con app non pubblicata, il CTA “Get full app” dell’App Clip può non portare a un'installazione pubblica standard.
Per testare end-to-end in QA:

1. dopo l’App Clip, installa manualmente la full app da TestFlight
2. apri la full app
3. verifica pickup da App Group (`pending_invite_token`/`pending_invite_location`) e applicazione flag/sfondo

## 6) Test matrix minima consigliata

1. Full app installata + `location=bibbione`
2. Full app installata + `location` assente
3. Full app non installata -> App Clip -> install TestFlight -> open app (`location=bibbione`)
4. Token scaduto/non valido (deve mostrare errore senza crash)

## 7) Debug rapido (se qualcosa non va)

1. AASA: nessun redirect, content-type JSON corretto, HTTPS valido.
2. Capabilities: domain/app group uguali su target corretti.
3. Bundle IDs/Team ID coerenti con AASA.
4. Link: path esatto `/i` e query `t` presente.
5. Test su device fisico (non simulatore per flusso QR reale/App Clip reale).
