# Checklist Implementativa (3 Milestone)

## Milestone 1 — Onboarding + diagnosi
- [x] Schermata benvenuto aggiornata:
  - Titolo: `30 secondi per capire come muoversi oggi.`
  - CTA: `Inizia`
- [x] Disclaimer non-medicale riusabile (`NonMedicalDisclaimer`)
- [x] Diagnosi artrosi a 3 stati:
  - `confirmed` (+1)
  - `notDiagnosed` (+0)
  - `unknown` (+2)
- [x] Domanda diagnosi mostrata solo al primo onboarding (`diagnosisAnsweredAt`)
- [x] Persistenza locale retrocompatibile (`diagnosisStatus` + fallback su `hasDiagnosis`)
- [x] Applicazione del modifier diagnosi nel calcolo score quiz

## Milestone 2 — Quick Check giornaliero + semaforo
- [x] Modello dati Quick Check:
  - Q1 sintomi
  - Q2 carico
  - Q3 fattori vacanza
  - Q4 recupero
- [x] Formula score e classificazione:
  - `0–3` verde
  - `4–6` giallo
  - `7+` rosso
- [x] Motore ranking regole/punteggi (2 azioni + 1 avoid)
- [x] Schermata risultato:
  - Header dinamico per semaforo
  - Percorso consigliato
  - Video consigliato
  - CTA continuita' + salvataggio stato
- [x] Persistenza locale diario + sensitivita' fattori (auto-aggiornamento)
- [x] Scrittura remota best-effort su `daily_logs`

## Milestone 3 — Integrazione UI + backend schema
- [x] Router:
  - `/daily-check`
  - `/daily-check/result`
- [x] Dashboard cane:
  - sezione `Quick Check giornaliero` con CTA
- [x] Carosello home:
  - card switch esperienza (Percorso Salute / Passeggiate Bibione)
  - switch modalita' da card
- [x] Drawer:
  - selezione modalita' esperienza
- [x] Normalizzazione location deep link:
  - supporto `bibione` e varianti, canonicale interno `bibbione`
- [x] Script SQL schema/seed:
  - `docs/monthly_sentence_seed.sql`
  - `docs/daily_check_seed.sql`
- [x] Overview Supabase aggiornata

## Validazione finale (da eseguire in ambiente con Flutter SDK)
- [ ] `flutter analyze`
- [x] `flutter test` (se presenti test)
- [ ] build iOS locale da `ios/Runner.xcworkspace`
