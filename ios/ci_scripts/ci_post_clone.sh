#!/bin/sh
set -e

# --- CALCOLO DINAMICO DELLA ROOT ---
FLUTTER_ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$FLUTTER_ROOT_DIR"

# --- 1. INSTALLAZIONE FLUTTER ---
rm -rf flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
export PATH="$FLUTTER_ROOT_DIR/flutter/bin:$PATH"

flutter --version
flutter precache --ios

# --- 2. DIPENDENZE DART ---
flutter pub get

# --- 3. DIPENDENZE IOS ---
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install --verbose
