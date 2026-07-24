#!/usr/bin/env bash
# Offline test for check-release-version.sh — semver accept/reject.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAIL=0
mk() { mkdir -p "$TMP/.claude-plugin"; printf '{"name":"recursive-spine","version":"%s"}' "$1" > "$TMP/.claude-plugin/plugin.json"; }

mk "0.12.0"
OUT="$(cd "$TMP" && bash "$HERE/check-release-version.sh")"; RC=$?
{ [ "$RC" = 0 ] && [ "$OUT" = "0.12.0" ]; } && echo "PASS: valid semver echoed" || { echo "FAIL: valid semver (rc=$RC out=$OUT)"; FAIL=1; }

for bad in "1.2" "v1.2.3" "1.2.3.4" "" "1.2.x" "1.2.3-rc1"; do
  mk "$bad"
  ( cd "$TMP" && bash "$HERE/check-release-version.sh" ) >/dev/null 2>&1; RC=$?
  [ "$RC" != 0 ] && echo "PASS: rejected '$bad'" || { echo "FAIL: accepted '$bad'"; FAIL=1; }
done

[ "$FAIL" = 0 ] && echo "PASS: all check-release-version scenarios" || exit 1
