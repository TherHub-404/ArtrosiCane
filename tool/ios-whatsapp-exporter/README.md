# iPhone WhatsApp Business Automation

Bootstrap locale per pilotare un iPhone reale dal Mac con Appium/XCUITest e arrivare a un export manuale-assistito delle chat di WhatsApp Business.

## Stato attuale su questo Mac

- Xcode presente: `26.2`
- Node presente: `v24.13.1`
- Certificato sviluppo presente: `Apple Development: LORENZO MILANO (655XZ978YP)`
- Device visibile: `Carl1 (17.5.1)`
- Blocco corrente: `Developer Mode` disabilitato sull'iPhone

## Perche' non usare iPhone Mirroring

Su Mac e iPhone nell'Unione Europea, Apple indica che `iPhone Mirroring` e' al momento non disponibile. Inoltre AirPlay consente sola visualizzazione, non interazione completa.

Fonte ufficiale Apple:
- https://support.apple.com/en-euro/120421

## Flusso minimo

1. Sbloccare l'iPhone.
2. Abilitare `Developer Mode` su iPhone.
3. Da questa cartella eseguire `npm install`.
4. Installare il driver XCUITest: `npx appium driver install xcuitest`
5. Copiare `.env.example` in `.env` e verificare `APP_BUNDLE_ID` e `WDA_BUNDLE_ID`.
6. Avviare Appium: `npm run appium`
7. In un altro terminale lanciare `npm run probe`

Lo script `probe` apre l'app target, salva screenshot e XML della UI in `artifacts/`, e ci permette di capire i selettori reali da usare per il workflow di export.

`WDA_BUNDLE_ID` deve essere un identificatore firmabile dal tuo team Apple, per esempio `com.lorenzomilano.WebDriverAgentRunner`.

## Identificare il bundle id di WhatsApp Business

Con `Developer Mode` attivo:

```bash
npm run find:whatsapp
```

Questo script legge tutte le app installate sul device e cerca bundle che contengano `whatsapp`.

## Note importanti

- Il progetto e' isolato da quello Flutter principale.
- Per un'app di terze parti come WhatsApp Business, l'automazione finale andra' validata sulla UI reale, perche' etichette e gerarchie possono cambiare.
- L'export "massivo" non e' esposto da WhatsApp come API pubblica: il percorso realistico e' automazione UI del flusso chat-per-chat.
