#!/usr/bin/env bash
# Tests for spine-visibility-guard.sh — fail-closed visibility enforcement.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
FAIL=0

# Build a gh stub that reports a given visibility per repo name.
# Usage: make_stub <dir> "owner/pub=public owner/priv=private ..."
make_stub() {
  local dir="$1" map="$2"
  cat > "$dir/gh" <<STUB
#!/usr/bin/env bash
# only handles: gh repo view <owner/repo> --json visibility --jq .visibility
repo="\$3"   # gh repo view <repo> ...
case "\$1 \$2" in
  "repo view")
STUB
  for kv in $map; do
    local repo="${kv%%=*}" v="${kv#*=}"
    printf '    if [ "$repo" = "%s" ]; then echo "%s"; exit 0; fi\n' "$repo" "$v" >> "$dir/gh"
  done
  cat >> "$dir/gh" <<'STUB'
    exit 1   # unknown repo -> gh fails (guard treats as unknown)
    ;;
esac
exit 0
STUB
  chmod +x "$dir/gh"
}

run() { # run <stub-map> <repos> <issue> [slack] -> sets RC and OUT
  local tmp; tmp="$(mktemp -d)"
  make_stub "$tmp" "$1"
  OUT="$(PATH="$tmp:$PATH" SPINE_REPOS="$2" SPINE_TRACKING_ISSUE="$3" SLACK_WEBHOOK_URL="${4:-}" GH_TOKEN=x \
        bash "$HERE/spine-visibility-guard.sh" 2>&1)"
  RC=$?
  rm -rf "$tmp"
}

check() { # check <name> <expected-rc>
  if [ "$RC" = "$2" ]; then echo "PASS: $1"; else echo "FAIL: $1 (rc=$RC expected $2) :: $OUT"; FAIL=1; fi
}

# 1. all-public swept + public target -> allow (0)
run "a/pub1=public a/pub2=public" "a/pub1 a/pub2" "a/pub1#5"
check "all-public to public target allowed" 0

# 2. private swept + public target -> REFUSE (1)
run "a/pub=public b/priv=private" "a/pub b/priv" "a/pub#5"
check "private swept to public target refused" 1

# 3. private swept + private target -> allow (0)
run "a/pub=public b/priv=private h/hive=private" "a/pub b/priv" "h/hive#2"
check "private swept to private target allowed" 0

# 4. unknown swept repo + public target -> REFUSE (fail-safe treats unknown as private) (1)
run "a/pub=public" "a/pub b/ghost" "a/pub#5"
check "unknown swept repo refused against public target" 1

# 5. private swept + unknown target -> REFUSE (fail-closed) (1)
run "a/pub=public b/priv=private" "a/pub b/priv" "z/unverifiable#1"
check "private swept to unverifiable target refused" 1

# 6. private swept + private target + slack webhook -> allow but WARN (0, warning in output)
run "b/priv=private h/hive=private" "b/priv" "h/hive#2" "https://hooks.slack.com/services/xxx"
check "private+slack allowed (rc0)" 0
echo "$OUT" | grep -q "guard WARNING" && echo "PASS: slack warning emitted" || { echo "FAIL: no slack warning"; FAIL=1; }

[ "$FAIL" = 0 ] && echo "PASS: all visibility-guard scenarios" || { echo "SOME FAILED"; exit 1; }
