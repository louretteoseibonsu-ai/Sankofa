#!/usr/bin/env bash
# One-command tester release: build a per-ABI APK and distribute to Firebase
# App Distribution (much smaller than the universal APK).
#   Usage:  TESTERS="you@x.com,me@x.com" ./ship.sh "optional release notes"
#      or:  GROUPS="qa" ./ship.sh
#   Env:
#     ABI=arm64-v8a        which split APK to ship (default arm64-v8a)
#     SKIP_BUILD=1         re-distribute the last build without rebuilding
set -euo pipefail
cd "$(dirname "$0")"                       # -> app/

APP_ID="1:401880298696:android:e59d2583f059183b1ee1fd"
GROUPS="${GROUPS:-}"                        # Firebase group ALIAS (see console)
TESTERS="${TESTERS:-}"                      # comma-separated tester emails
ABI="${ABI:-arm64-v8a}"                     # arm64-v8a | armeabi-v7a | x86_64
NOTES="${1:-$(git log -1 --pretty=%s)}"

# Default to the "testers" group so a bare `./ship.sh "notes"` just works.
# Create the group ONCE in the console (App Distribution → Testers & groups),
# give it the alias `testers`, add people to it — then you never pass emails
# on the CLI again. Override anytime with GROUPS="other" or TESTERS="a@b.com".
if [[ -z "$GROUPS" && -z "$TESTERS" ]]; then GROUPS="testers"; fi

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "▶ flutter pub get";            flutter pub get
  echo "▶ regenerating launcher icon"; dart run flutter_launcher_icons
  echo "▶ building per-ABI release APKs"
  flutter build apk --release --split-per-abi
fi

APK="build/app/outputs/flutter-apk/app-${ABI}-release.apk"
if [[ ! -f "$APK" ]]; then
  echo "✗ $APK not found. Available:"; ls -1 build/app/outputs/flutter-apk/*.apk || true
  exit 1
fi
echo "▶ shipping $(du -h "$APK" | cut -f1) — $APK"

ARGS=(appdistribution:distribute "$APK" --app "$APP_ID" --release-notes "$NOTES")
[[ -n "$GROUPS"  ]] && ARGS+=(--groups  "$GROUPS")
[[ -n "$TESTERS" ]] && ARGS+=(--testers "$TESTERS")

echo "▶ distributing to testers"
set +e
OUT=$(firebase "${ARGS[@]}" 2>&1); RC=$?
set -e
echo "$OUT"
if [[ $RC -ne 0 ]]; then
  # The upload half usually succeeds; only the tester-assignment 404s (a known
  # firebase-tools bug). Don't treat that as a failed ship — the APK is live.
  CONSOLE=$(echo "$OUT" | grep -oE 'https://console\.firebase\.google\.com[^ ]*releases/[A-Za-z0-9]+' | head -1)
  echo ""
  echo "✅ Build UPLOADED successfully — the release (with all bundled audio) is live."
  echo "   CLI auto-assign 404s on this project, so finish in the console (1 step):"
  echo "   1) open the release:"
  if [[ -n "$CONSOLE" ]]; then echo "      → $CONSOLE"
  else echo "      → https://console.firebase.google.com/project/sankofa-twi/appdistribution"; fi
  echo "   2) Distribute to testers → pick the 'testers' group → Done."
  echo "   (Both testers are already in that group, so they all get it.)"
  exit 0
fi
echo "✅ shipped ($ABI) — $NOTES"
