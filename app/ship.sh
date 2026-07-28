#!/usr/bin/env bash
# One-command tester release: build + distribute to Firebase App Distribution.
#   Usage:  TESTERS="you@x.com,me@x.com" ./ship.sh "optional release notes"
#      or:  GROUPS="qa" ./ship.sh
set -euo pipefail
cd "$(dirname "$0")"                       # -> app/

APP_ID="1:401880298696:android:e59d2583f059183b1ee1fd"
GROUPS="${GROUPS:-}"                        # Firebase group ALIAS (see console)
TESTERS="${TESTERS:-}"                      # comma-separated tester emails
NOTES="${1:-$(git log -1 --pretty=%s)}"

if [[ -z "$GROUPS" && -z "$TESTERS" ]]; then
  echo "✗ Set GROUPS (a group alias) or TESTERS (emails). e.g.:"
  echo "    TESTERS=\"you@example.com\" ./ship.sh \"notes\""
  exit 1
fi

echo "▶ flutter pub get";            flutter pub get
echo "▶ regenerating launcher icon"; dart run flutter_launcher_icons
echo "▶ building release APK";       flutter build apk --release
APK="build/app/outputs/flutter-apk/app-release.apk"

ARGS=(appdistribution:distribute "$APK" --app "$APP_ID" --release-notes "$NOTES")
[[ -n "$GROUPS"  ]] && ARGS+=(--groups  "$GROUPS")
[[ -n "$TESTERS" ]] && ARGS+=(--testers "$TESTERS")

echo "▶ distributing to testers";    firebase "${ARGS[@]}"
echo "✅ shipped — $NOTES"
