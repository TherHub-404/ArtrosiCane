#!/usr/bin/env bash
# Deploys this app to production AND re-points the artrosicane.vercel.app
# alias at the new deployment.
#
# Why the alias step: artrosicane.vercel.app is a manually-pinned alias, not
# a production domain that auto-follows. `vercel deploy --prod` updates the
# project's own *.vercel.app domains but leaves artrosicane.vercel.app on the
# old deployment — so it must be re-aliased explicitly here.
set -euo pipefail

cd "$(dirname "$0")/.."

ALIAS_DOMAIN="artrosicane.vercel.app"

echo "▸ Building & deploying to production…"
DEPLOY_LOG="$(mktemp)"
trap 'rm -f "$DEPLOY_LOG"' EXIT

# Stream the build live AND keep a copy to extract the deployment URL from.
npx vercel deploy --prod -y 2>&1 | tee "$DEPLOY_LOG"

# The deployment URL is on the "Production:" line(s); the trailing JSON the
# CLI prints must NOT be parsed for it.
DEPLOY_URL="$(
  grep 'Production:' "$DEPLOY_LOG" \
    | grep -oE 'https://[a-z0-9.-]+\.vercel\.app' \
    | head -n1
)"

if [[ -z "$DEPLOY_URL" ]]; then
  echo "✗ Could not read the deployment URL from 'vercel deploy'." >&2
  exit 1
fi
echo "▸ Deployment: $DEPLOY_URL"

echo "▸ Re-pointing $ALIAS_DOMAIN → $DEPLOY_URL"
npx vercel alias set "$DEPLOY_URL" "$ALIAS_DOMAIN"

echo "✓ Done — live at https://$ALIAS_DOMAIN"
