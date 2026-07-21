#!/usr/bin/env bash
# Offline test for spine-digest.sh: stubs `gh` on PATH and asserts structure.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Stub gh: return fixed JSON per subcommand so the sweep is deterministic.
cat > "$TMP/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"issue list"*"--label deferred"*) echo '[{"number":7,"title":"old thing","createdAt":"2026-06-01T00:00:00Z"}]' ;;
  *"api"*"/milestones"*)             echo '[{"title":"M1","number":1,"open_issues":2,"updated_at":"2026-05-01T00:00:00Z"}]' ;;
  *"issue list"*"--assignee"*)       echo '[]' ;;
  *)                                  echo '[]' ;;
esac
STUB
chmod +x "$TMP/gh"

OUT="$(PATH="$TMP:$PATH" SPINE_REPOS="acme/one acme/two" SPINE_DEFERRAL_LABEL=deferred \
       SPINE_STALL_DAYS=21 GH_TOKEN=x bash "$HERE/spine-digest.sh" 2>/dev/null)"

fail=0
grep -q "^# Spine digest — " <<<"$OUT" || { echo "FAIL: no title heading"; fail=1; }
grep -q "acme/one" <<<"$OUT"          || { echo "FAIL: repo one missing"; fail=1; }
grep -q "acme/two" <<<"$OUT"          || { echo "FAIL: repo two missing"; fail=1; }
grep -q "#7"       <<<"$OUT"          || { echo "FAIL: aging deferral #7 missing"; fail=1; }
grep -Eq "swept 2/2" <<<"$OUT"        || { echo "FAIL: denominator wrong"; fail=1; }
[ "$fail" = 0 ] && echo "PASS: spine-digest structure" || exit 1
