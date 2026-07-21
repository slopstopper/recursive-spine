#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# Stub curl to return a minimal Anthropic messages response.
cat > "$TMP/curl" <<'STUB'
#!/usr/bin/env bash
echo '{"content":[{"type":"text","text":"1. acme/one#5 — open it? (unblocked)"}]}'
STUB
chmod +x "$TMP/curl"
echo "$TMP/runbook.md" > /dev/null; echo "be brief" > "$TMP/runbook.md"
FAIL=0

OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP:$PATH" ANTHROPIC_API_KEY=x \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
if grep -q "acme/one#5" <<<"$OUT"; then
  echo "PASS: nudge parses model output"
else
  echo "FAIL: nudge parses model output"; FAIL=1
fi

# Degrade path: SPINE_NUDGE_RUNBOOK unset, key present -> exit 0 with loud note, no crash.
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP:$PATH" ANTHROPIC_API_KEY=x \
       GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ] && [ -n "$OUT" ]; then
  echo "PASS: missing runbook degrades to exit 0 with loud note"
else
  echo "FAIL: missing runbook degrades to exit 0 with loud note (rc=$rc, out='$OUT')"; FAIL=1
fi

# Degrade path: no ANTHROPIC_API_KEY -> exit 0 with a 'no ANTHROPIC_API_KEY' note.
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP:$PATH" ANTHROPIC_API_KEY="" \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ] && grep -qi "no ANTHROPIC_API_KEY" <<<"$OUT"; then
  echo "PASS: missing ANTHROPIC_API_KEY degrades to exit 0 with note"
else
  echo "FAIL: missing ANTHROPIC_API_KEY degrades to exit 0 with note (rc=$rc, out='$OUT')"; FAIL=1
fi

exit "$FAIL"
