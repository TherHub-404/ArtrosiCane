#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME="${1:-com.artrosicane.artrosicane}"
DOMAIN="${2:-artrosicane.vercel.app}"
TEST_URL="${3:-https://${DOMAIN}/i?t=TESTTOKEN&location=bibione}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

if ! command -v adb >/dev/null 2>&1; then
  die "adb non trovato. Installa Android Platform Tools e riprova."
fi

echo "== Android App Links Verification =="
echo "Package : ${PACKAGE_NAME}"
echo "Domain  : ${DOMAIN}"
echo "Test URL: ${TEST_URL}"
echo

echo "1) Verifico presenza device/emulatore..."
adb_devices="$(adb devices | sed -n '2,$p' | rg -v '^\s*$' || true)"
if [[ -z "${adb_devices}" ]]; then
  die "nessun device collegato. Collega un telefono o avvia un emulatore."
fi
echo "${adb_devices}"
echo

echo "2) Reset stato App Links..."
adb shell pm set-app-links --package "${PACKAGE_NAME}" 0 all
echo

echo "3) Trigger manuale verifica dominio..."
adb shell pm verify-app-links --re-verify "${PACKAGE_NAME}"
echo "Attendo 8 secondi per completare la verifica..."
sleep 8
echo

echo "4) Stato verifica (deve mostrare '${DOMAIN}: verified')..."
adb shell pm get-app-links "${PACKAGE_NAME}"
echo

echo "5) Apertura URL di test..."
adb shell am start \
  -a android.intent.action.VIEW \
  -c android.intent.category.BROWSABLE \
  -d "${TEST_URL}"
echo

echo "Comandi utili extra:"
echo "  adb shell pm get-app-links --user cur ${PACKAGE_NAME}"
echo "  adb shell cmd package query-app-links ${PACKAGE_NAME} 2>/dev/null || true"
