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
OUT="$(printf 'hello world' | PATH="$TMP:$PATH" SPINE_TRACKING_ISSUE="acme/one#20" \
       SPINE_MENTION="@aoife" GH_TOKEN=x bash "$HERE/spine-deliver.sh" 2>/dev/null)"
grep -q "issuecomment-1" <<<"$OUT" && echo "PASS: deliver returns comment url" || exit 1
