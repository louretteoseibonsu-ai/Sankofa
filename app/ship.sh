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

if [[ -z "$GROUPS" && -z "$TESTERS" ]]; then
  echo "✗ Set GROUPS (a group alias) or TESTERS (emails). e.g.:"
  echo "    TESTERS=\"you@example.com\" ./ship.sh \"notes\""
  exit 1
fi

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

echo "▶ distributing to testers";       firebase "${ARGS[@]}"
echo "✅ shipped ($ABI) — $NOTES"
