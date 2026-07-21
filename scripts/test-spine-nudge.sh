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
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP:$PATH" ANTHROPIC_API_KEY=x \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
grep -q "acme/one#5" <<<"$OUT" && echo "PASS: nudge parses model output" || exit 1
