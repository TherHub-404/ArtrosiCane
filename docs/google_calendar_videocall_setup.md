# Setup Prenotazione Video Call Diretta (Google Calendar)

Questa integrazione crea l'evento direttamente via backend (Supabase Edge Function) senza aprire Google Calendar lato app.

## 1) Deploy Edge Function

```bash
supabase functions deploy schedule-video-call
```

## 2) Configura i secrets su Supabase

```bash
supabase secrets set \
  GOOGLE_CALENDAR_CLIENT_ID="<google-oauth-client-id>" \
  GOOGLE_CALENDAR_CLIENT_SECRET="<google-oauth-client-secret>" \
  GOOGLE_CALENDAR_REFRESH_TOKEN="<google-refresh-token>" \
  GOOGLE_CALENDAR_ID="primary" \
  VIDEO_CALL_OWNER_EMAIL="adriano.monino@gmail.com"
```

`GOOGLE_CALENDAR_ID` puo essere `primary` oppure un calendar id specifico.

## 3) Scope Google richiesto

L'account Google usato dal refresh token deve avere almeno:

- `https://www.googleapis.com/auth/calendar.events`

## 4) Comportamento runtime

Quando l'utente compila `nome`, `cognome`, `email`, `telefono` e preme `Prenota`:

- l'app invoca `schedule-video-call`
- il backend crea un evento su Google Calendar
- invita entrambi: `adriano.monino@gmail.com` + email utente
- crea link Google Meet
- invia aggiornamenti email agli invitati (`sendUpdates=all`)

## 5) Nota operativa importante

La comparsa automatica sul calendario del partecipante dipende anche dalle impostazioni personali di Google Calendar dell'utente invitato (accettazione inviti/auto-add). L'invito viene comunque inviato e l'evento viene creato nel calendario proprietario.
