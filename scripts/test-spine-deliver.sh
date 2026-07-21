#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/gh" <<'STUB'
#!/usr/bin/env bash
# echo a fake comment URL for `gh issue comment`
case "$*" in
  *"issue comment"*) echo "https://github.com/acme/one/issues/20#issuecomment-1" ;;
  *) echo '{}' ;;
esac
STUB
chmod +x "$TMP/gh"

FAILED=""

OUT="$(printf 'hello world' | PATH="$TMP:$PATH" SPINE_TRACKING_ISSUE="acme/one#20" \
       SPINE_MENTION="@aoife" GH_TOKEN=x bash "$HERE/spine-deliver.sh" 2>/dev/null)"
if grep -q "issuecomment-1" <<<"$OUT"; then
  echo "PASS: deliver returns comment url"
else
  echo "FAIL: deliver returns comment url"
  FAILED="1"
fi

printf '' | PATH="$TMP:$PATH" SPINE_TRACKING_ISSUE="acme/one#20" \
       GH_TOKEN=x bash "$HERE/spine-deliver.sh" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 3 ]; then
  echo "PASS: empty body exits 3"
else
  echo "FAIL: empty body exits $rc (expected 3)"
  FAILED="1"
fi

printf 'hi' | PATH="$TMP:$PATH" GH_TOKEN=x bash "$HERE/spine-deliver.sh" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 3 ]; then
  echo "PASS: no tracking issue exits 3"
else
  echo "FAIL: no tracking issue exits $rc (expected 3)"
  FAILED="1"
fi

if [ -n "$FAILED" ]; then
  exit 1
fi
exit 0
