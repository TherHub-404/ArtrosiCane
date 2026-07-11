# ArtrosiCane (Flutter)

App Flutter per la gestione del profilo cane, onboarding e quiz, con backend Supabase.

## Prerequisiti

### Toolchain base

- `git`
- Flutter SDK `stable` (nel progetto testato con `Flutter 3.35.7` e `Dart 3.9.2`)
- Un editor (VS Code / Android Studio)

Controllo rapido:

```bash
flutter --version
dart --version
flutter doctor -v
```

### Dipendenze piattaforma (sviluppo locale)

- Linux desktop (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
```

- Android:
  - Android Studio + Android SDK
  - almeno un emulatore o device fisico
  - JDK 11 (il progetto compila con target Java/Kotlin 11)
- iOS (solo macOS):
  - Xcode
  - CocoaPods (`sudo gem install cocoapods`)

## Installazione progetto

1. Clona il repository e apri la cartella:

```bash
git clone <URL_REPO>
cd ArtrosiCane
```

2. Installa le dipendenze Dart/Flutter:

```bash
flutter pub get
```

3. Crea il file `.env` partendo dal template:

```bash
cp .env.example .env
```

4. Configura almeno le variabili obbligatorie in `.env`:

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Variabili opzionali (feature specifiche): login demo, Google Sign-In, link inviti, import razze, ecc. sono già documentate in `.env.example`.

## Run in locale

1. Verifica i device disponibili:

```bash
flutter devices
```

2. Avvia l'app:

- Linux desktop:

```bash
flutter run -d linux
```

- Web (Chrome):

```bash
flutter run -d chrome
```

- Android (emulatore/device):

```bash
flutter run -d android
```

- iOS (simulatore/device, solo macOS):

```bash
flutter run -d ios
```

## Setup rapido Android Emulator

1. Apri Android Studio e installa:
   - Android SDK
   - Android SDK Platform (API recente)
   - Android Emulator
2. Crea un AVD da Android Studio (`Device Manager` -> `Create device`).
3. Avvia l'emulatore.
4. Verifica che Flutter lo veda:

```bash
flutter devices
```

5. Avvia l'app sull'emulatore:

```bash
flutter run -d android
```

Tip: se hai piu' emulatori/device, usa l'ID specifico mostrato da `flutter devices`, ad esempio `flutter run -d emulator-5554`.

## Setup rapido iOS Simulator (solo macOS)

1. Installa Xcode dall'App Store.
2. Esegui setup iniziale toolchain Apple:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

3. Installa CocoaPods (se non presente):

```bash
sudo gem install cocoapods
```

4. Installa i pod iOS del progetto:

```bash
cd ios
pod install
cd ..
```

5. Avvia il simulatore iOS e verifica i device:

```bash
open -a Simulator
flutter devices
```

6. Avvia l'app sul simulatore:

```bash
flutter run -d ios
```

## Comandi utili

Il progetto include anche `Taskfile.yml` (se usi `task`):

```bash
task pub-get
task run
task run-chrome
task test
task analyze
```

Reset completo dello stato locale (onboarding/sessione):

```bash
task run-clean
# oppure
flutter run -d linux --dart-define=RESET_FLOW=true
```

## Import razze (opzionale)

Script di import da TheDogAPI verso Supabase:

- Richiede: `DOG_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE` (o `SUPABASE_SERVICE_ROLE_KEY`)
- Comando:

```bash
dart tool/import_dog_breeds.dart
```

## Troubleshooting veloce

- Errore `SUPABASE_URL missing in .env` o `SUPABASE_ANON_KEY missing in .env`:
  - verifica che `.env` esista nella root del progetto e contenga i valori.
- iOS `pod install` / `Generated.xcconfig must exist`:
  - esegui prima `flutter pub get`, poi `cd ios && pod install`.

## Environment verification

Codex environment final test: Flutter setup, branch push, PR creation, and Linear review handoff are verified.
