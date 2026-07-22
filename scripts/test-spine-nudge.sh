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

# Stub curl that returns nudges plus a ===LEDGER=== section.
cat > "$TMP/curl-ledger" <<'STUB'
#!/usr/bin/env bash
echo '{"content":[{"type":"text","text":"1. acme/one#5 — open it? (unblocked)\n===LEDGER===\n2026-07-21 | acme/one#5 | unblocked | outcome: pending"}]}'
STUB
chmod +x "$TMP/curl-ledger"

# no ledger configured: SPINE_LEDGER unset, model still emits a ===LEDGER=== section.
# The delimiter and everything after it must never reach stdout, and no ledger write happens
# (no gh stub is on PATH at all, so any gh invocation would fail loudly / be caught by set -e-like checks).
mkdir -p "$TMP/noledger"
cp "$TMP/curl-ledger" "$TMP/noledger/curl"
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP/noledger:$PATH" ANTHROPIC_API_KEY=x \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ] && grep -q "acme/one#5" <<<"$OUT" && ! grep -q "===LEDGER===" <<<"$OUT" \
   && ! grep -q "outcome: pending" <<<"$OUT"; then
  echo "PASS: no ledger configured skips suppression, still selects nudges, strips ledger block"
else
  echo "FAIL: no ledger configured skips suppression, still selects nudges, strips ledger block (rc=$rc, out='$OUT')"; FAIL=1
fi

# ledger delimiter stripping: confirm with SPINE_LEDGER set (full ledger read+append path stubbed via gh).
# The read must be a SINGLE `gh api repos/.../contents/PATH` call (no --jq) returning full JSON
# with both .content and .sha, parsed locally with jq. A second call with the same shape (no -X)
# would indicate the old two-fetch behavior and should fail the "single fetch" assertion below.
mkdir -p "$TMP/withledger"
cp "$TMP/curl-ledger" "$TMP/withledger/curl"
GH_CALL_LOG="$TMP/withledger/gh-calls.log"
cat > "$TMP/withledger/gh" <<STUB
#!/usr/bin/env bash
# Stub gh: handle \`gh api repos/OWNER/REPO/contents/PATH\` (single-fetch, no --jq) and
# \`gh api repos/OWNER/REPO/contents/PATH -X PUT ...\`.
echo "\$*" >> "$GH_CALL_LOG"
is_put=0
for a in "\$@"; do
  if [ "\$a" = "-X" ]; then is_put=1; fi
done
if [ "\$is_put" -eq 1 ]; then
  exit 0
fi
content="\$(printf '%s' '# ledger
' | base64)"
printf '{"content":"%s","sha":"deadbeef"}\n' "\$content"
STUB
chmod +x "$TMP/withledger/gh"
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP/withledger:$PATH" ANTHROPIC_API_KEY=x \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" SPINE_LEDGER="effythealien/private-hive:nudges/ledger.md" \
       GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ] && grep -q "acme/one#5" <<<"$OUT" && ! grep -q "===LEDGER===" <<<"$OUT" \
   && ! grep -q "outcome: pending" <<<"$OUT"; then
  echo "PASS: ledger delimiter and lines after it never reach stdout"
else
  echo "FAIL: ledger delimiter and lines after it never reach stdout (rc=$rc, out='$OUT')"; FAIL=1
fi

read_calls="$(grep -vc -- '-X' "$GH_CALL_LOG" 2>/dev/null || echo 0)"
if [ "$read_calls" -eq 1 ]; then
  echo "PASS: ledger read is a single gh api call (efficiency)"
else
  echo "FAIL: ledger read is a single gh api call (efficiency) (saw $read_calls read calls)"; FAIL=1
fi

# Ledger unreachable: gh fails -> loud note, still exit 0, still selects nudges.
mkdir -p "$TMP/badledger"
cp "$TMP/curl-ledger" "$TMP/badledger/curl"
cat > "$TMP/badledger/gh" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
chmod +x "$TMP/badledger/gh"
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP/badledger:$PATH" ANTHROPIC_API_KEY=x \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" SPINE_LEDGER="effythealien/private-hive:nudges/ledger.md" \
       GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ] && grep -qi "Ledger unreachable" <<<"$OUT" && grep -q "acme/one#5" <<<"$OUT"; then
  echo "PASS: unreachable ledger degrades loudly, still exits 0, still selects nudges"
else
  echo "FAIL: unreachable ledger degrades loudly, still exits 0, still selects nudges (rc=$rc, out='$OUT')"; FAIL=1
fi

# Stub curl that returns zero nudges ('none') plus an empty ===LEDGER=== section.
cat > "$TMP/curl-none" <<'STUB'
#!/usr/bin/env bash
echo '{"content":[{"type":"text","text":"none\n===LEDGER===\n"}]}'
STUB
chmod +x "$TMP/curl-none"

# Zero nudges with SPINE_LEDGER set: the ledger PUT must still happen, with a
# "## run <date> — sent 0 nudges" header. Stub gh to capture the PUT body.
mkdir -p "$TMP/zeronudges"
cp "$TMP/curl-none" "$TMP/zeronudges/curl"
PUT_BODY_FILE="$TMP/zeronudges/put-body.txt"
cat > "$TMP/zeronudges/gh" <<STUB
#!/usr/bin/env bash
is_put=0
content_arg=""
prev=""
for a in "\$@"; do
  if [ "\$a" = "-X" ]; then is_put=1; fi
  if [ "\$prev" = "-f" ] && [[ "\$a" == content=* ]]; then
    content_arg="\${a#content=}"
  fi
  prev="\$a"
done
if [ "\$is_put" -eq 1 ]; then
  printf '%s' "\$content_arg" | base64 -d > "$PUT_BODY_FILE"
  exit 0
fi
content="\$(printf '%s' '# ledger
' | base64)"
printf '{"content":"%s","sha":"deadbeef"}\n' "\$content"
STUB
chmod +x "$TMP/zeronudges/gh"
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP/zeronudges:$PATH" ANTHROPIC_API_KEY=x \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" SPINE_LEDGER="effythealien/private-hive:nudges/ledger.md" \
       GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ] && [ -f "$PUT_BODY_FILE" ] && grep -q "sent 0 nudges" "$PUT_BODY_FILE"; then
  echo "PASS: zero nudges still appends ledger PUT with 'sent 0 nudges' header"
else
  echo "FAIL: zero nudges still appends ledger PUT with 'sent 0 nudges' header (rc=$rc, out='$OUT')"; FAIL=1
fi

# Ledger read succeeds (content+sha present) but the PUT call fails:
# script must print the "_Ledger append failed_" note AND still exit 0.
mkdir -p "$TMP/putfails"
cp "$TMP/curl-ledger" "$TMP/putfails/curl"
cat > "$TMP/putfails/gh" <<'STUB'
#!/usr/bin/env bash
is_put=0
for a in "$@"; do
  if [ "$a" = "-X" ]; then is_put=1; fi
done
if [ "$is_put" -eq 1 ]; then
  exit 1
fi
content="$(printf '%s' '# ledger
' | base64)"
printf '{"content":"%s","sha":"deadbeef"}\n' "$content"
STUB
chmod +x "$TMP/putfails/gh"
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP/putfails:$PATH" ANTHROPIC_API_KEY=x \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" SPINE_LEDGER="effythealien/private-hive:nudges/ledger.md" \
       GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ] && grep -qi "Ledger append failed" <<<"$OUT" && grep -q "acme/one#5" <<<"$OUT"; then
  echo "PASS: ledger read succeeds but PUT fails -> append-failed note, exit 0"
else
  echo "FAIL: ledger read succeeds but PUT fails -> append-failed note, exit 0 (rc=$rc, out='$OUT')"; FAIL=1
fi

exit "$FAIL"
