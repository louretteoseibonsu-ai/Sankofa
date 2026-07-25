#!/usr/bin/env bash
# Build a release APK and push it to Firebase App Distribution in one step.
#
# Usage:
#   ./scripts/beta.sh                 # uses default release notes
#   ./scripts/beta.sh "Fixed audio"   # custom release notes
#
# First time only: make it runnable ->  chmod +x scripts/beta.sh
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# EDIT THESE ONCE
# ─────────────────────────────────────────────────────────────────────────────
# Your Firebase Android App ID (Console → Project settings → General → Your apps).
APP_ID="1:401880298696:android:e59d2583f059183b1ee1fd"

# Either list testers by email (comma-separated) OR set GROUP and leave TESTERS "".
TESTERS="ajdiversity@gmail.com,ankobiahj@gmail.com,cferreira.valdebenito@gmail.com,eshunabi@gmail.com,gitonganicole@yahoo.com,kwhite021@gmail.com,liu97ajh@gmail.com,lourette.oseibonsu@gmail.com,nanafontomfrom@gmail.com,rachelmbah@gmail.com"
# Override from the shell to target a group, e.g.:  GROUP=raffle-testers ./scripts/beta.sh "notes"
GROUP="${GROUP:-}"   # a tester-group alias sends to that group instead of the emails above
# ─────────────────────────────────────────────────────────────────────────────

# Always run from the app/ folder, regardless of where you call the script from.
cd "$(dirname "$0")/../app"

NOTES="${1:-New beta build — thanks for testing!}"

echo "▶  Cleaning + building release APK…"
flutter build apk --release

APK="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK" ]; then
  echo "✗  Build did not produce $APK — check the Flutter output above."
  exit 1
fi

# Set SILENT=1 to upload the build WITHOUT attaching testers.
# Firebase only emails testers when they're attached to a release, so a
# testerless upload notifies no one — you release/notify manually afterwards.
SILENT="${SILENT:-0}"

echo "▶  Uploading to Firebase App Distribution…"
if [ "$SILENT" = "1" ]; then
  firebase appdistribution:distribute "$APK" \
    --app "$APP_ID" --release-notes "$NOTES"
  echo "✅  Uploaded silently — NO testers attached, NO emails sent."
  echo "   To release when ready: Firebase Console → App Distribution → this"
  echo "   release → Testers → add your group/emails (that step sends the email),"
  echo "   then ping testers yourself if you like."
elif [ -n "$GROUP" ]; then
  firebase appdistribution:distribute "$APK" \
    --app "$APP_ID" --groups "$GROUP" --release-notes "$NOTES"
  echo "✅  Done — group '$GROUP' has been notified."
else
  firebase appdistribution:distribute "$APK" \
    --app "$APP_ID" --release-notes "$NOTES" --testers "$TESTERS"
  echo "✅  Done — testers have been notified."
fi
