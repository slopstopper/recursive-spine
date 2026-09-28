#!/usr/bin/env bash
# Tests for spine-board-sweep.sh — board membership sweep (#128).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
FAIL=0

# gh stub. Reads which graphql fixture to serve from $STUB_PAGES (a dir of
# page-N.json served in order), and the item-add exit code from $STUB_ADD_RC.
make_stub() {
  local dir="$1"
  cat > "$dir/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "api graphql")
    n=1
    [ -f "$STUB_PAGES/.n" ] && n="$(cat "$STUB_PAGES/.n")"
    f="$STUB_PAGES/page-$n.json"
    [ -f "$f" ] || exit 1
    echo $((n + 1)) > "$STUB_PAGES/.n"
    cat "$f"
    ;;
  "project item-add")
    echo "${4:-}" >> "$STUB_PAGES/.added"
    exit "${STUB_ADD_RC:-0}"
    ;;
  "project view")
    [ -n "${STUB_BOARD_PUBLIC:-}" ] || exit 1
    echo "$STUB_BOARD_PUBLIC"
    ;;
  "repo view")
    # $3 is the repo; private unless listed in STUB_PUBLIC_REPOS
    case " ${STUB_PUBLIC_REPOS:-} " in
      *" $3 "*) echo "PUBLIC" ;;
      *) echo "PRIVATE" ;;
    esac
    ;;
  *) exit 0 ;;
esac
STUB
  chmod +x "$dir/gh"
}

# page <file> <hasNext> <endCursor> <node-json...>
write_page() {
  local f="$1" hasnext="$2" cursor="$3"; shift 3
  local nodes; nodes="$(printf '%s,' "$@")"; nodes="${nodes%,}"
  printf '{"data":{"repository":{"issues":{"pageInfo":{"hasNextPage":%s,"endCursor":"%s"},"nodes":[%s]}}}}\n' \
    "$hasnext" "$cursor" "$nodes" > "$f"
}

on_board()  { printf '{"number":%s,"projectItems":{"nodes":[{"project":{"number":3,"owner":{"login":"acme"}}}]}}' "$1"; }
off_board() { printf '{"number":%s,"projectItems":{"nodes":[]}}' "$1"; }
other_board() { printf '{"number":%s,"projectItems":{"nodes":[{"project":{"number":9,"owner":{"login":"acme"}}}]}}' "$1"; }

run() { # run <repos> <board> <dry> ; pages already written to $PAGES
  local tmp; tmp="$(mktemp -d)"
  make_stub "$tmp"
  OUT="$(PATH="$tmp:$PATH" STUB_PAGES="$PAGES" STUB_ADD_RC="${ADD_RC:-0}" \
        STUB_BOARD_PUBLIC="${BOARD_PUBLIC:-false}" STUB_PUBLIC_REPOS="${PUBLIC_REPOS:-}" \
        SPINE_REPOS="$1" SPINE_BOARD="$2" SPINE_BOARD_DRY_RUN="${3:-0}" GH_TOKEN=x \
        bash "$HERE/spine-board-sweep.sh" 2>&1)"
  RC=$?
  rm -rf "$tmp"
}

# Default: private board, so the visibility guard is inert unless a test opts in.
newpages() { PAGES="$(mktemp -d)"; ADD_RC=0; BOARD_PUBLIC=false; PUBLIC_REPOS=""; }

check_rc()   { if [ "$RC" = "$2" ]; then echo "PASS: $1"; else echo "FAIL: $1 (rc=$RC want $2) :: $OUT"; FAIL=1; fi; }
check_has()  { if printf '%s' "$OUT" | grep -qF "$2"; then echo "PASS: $1"; else echo "FAIL: $1 (missing '$2') :: $OUT"; FAIL=1; fi; }
check_not()  { if printf '%s' "$OUT" | grep -qF "$2"; then echo "FAIL: $1 (unexpected '$2') :: $OUT"; FAIL=1; else echo "PASS: $1"; fi; }
check_adds() { local n=0
               [ -f "$PAGES/.added" ] && n="$(wc -l < "$PAGES/.added" | tr -d ' ')"
               if [ "$n" = "$2" ]; then echo "PASS: $1"; else echo "FAIL: $1 (added=$n want $2)"; FAIL=1; fi; }

# 1. Everything already on the board -> no adds, says so plainly.
newpages
write_page "$PAGES/page-1.json" false "" "$(on_board 1)" "$(on_board 2)"
run "acme/repo" "acme/3"
check_rc   "all-present exits 0" 0
check_has  "all-present reports current" "Board already current"
check_adds "all-present adds nothing" 0

# 2. Missing issues get added.
newpages
write_page "$PAGES/page-1.json" false "" "$(on_board 1)" "$(off_board 2)" "$(off_board 3)"
run "acme/repo" "acme/3"
check_rc   "missing exits 0" 0
check_adds "missing issues added" 2
check_has  "reports the add count" "Added 2 of 2 missing"

# 3. An issue on a DIFFERENT board still counts as missing from this one.
newpages
write_page "$PAGES/page-1.json" false "" "$(other_board 1)"
run "acme/repo" "acme/3"
check_adds "other-board issue is added to this board" 1

# 4. Pagination — a second page must be fetched, not silently dropped.
newpages
write_page "$PAGES/page-1.json" true "CUR1" "$(off_board 1)"
write_page "$PAGES/page-2.json" false "" "$(off_board 2)"
run "acme/repo" "acme/3"
check_adds "paginates past the first page" 2
check_has  "counts the full denominator" "(2 open total)"

# 5. Dry run reports but changes nothing.
newpages
write_page "$PAGES/page-1.json" false "" "$(off_board 1)" "$(off_board 2)"
run "acme/repo" "acme/3" 1
check_rc   "dry run exits 0" 0
check_adds "dry run adds nothing" 0
check_has  "dry run says nothing changed" "Nothing was changed."

# 6. Unreachable repo -> all failed -> rc 2, named in the denominator.
newpages   # no page files written, so the stub's graphql call fails
run "acme/gone" "acme/3"
check_rc  "all-repos-failed exits 2" 2
check_has "names the unreachable repo" "FAILED: acme/gone"

# 7. A failing item-add is counted, not swallowed, and does not fail the run.
newpages; ADD_RC=1
write_page "$PAGES/page-1.json" false "" "$(off_board 1)"
run "acme/repo" "acme/3"
check_rc  "add failure does not fail the sweep" 0
check_has "add failure is reported" "could not add"

# 8. Malformed board input is rejected loudly.
newpages
write_page "$PAGES/page-1.json" false "" "$(off_board 1)"
run "acme/repo" "notaboard"
check_rc  "malformed board exits 2" 2
check_has "malformed board explains the format" "must be owner/number"

newpages
write_page "$PAGES/page-1.json" false "" "$(off_board 1)"
run "acme/repo" "acme/xyz"
check_rc  "non-numeric board exits 2" 2
check_has "non-numeric board explains" "must be numeric"

# 9. Public board + private repo -> refuse, do not add.
newpages; BOARD_PUBLIC=true; PUBLIC_REPOS=""
write_page "$PAGES/page-1.json" false "" "$(off_board 1)"
run "acme/secret" "acme/3"
check_adds "private repo not added to public board" 0
check_has  "refusal is explicit" "REFUSED: acme/secret"

# 10. Public board + public repo -> proceeds normally.
newpages; BOARD_PUBLIC=true; PUBLIC_REPOS="acme/open"
write_page "$PAGES/page-1.json" false "" "$(off_board 1)"
run "acme/open" "acme/3"
check_adds "public repo added to public board" 1
check_not  "no refusal for public repo" "REFUSED"

# 11. Unknown board visibility must not be treated as public-and-safe;
#     a private board is the permissive case, so unknown must still add.
newpages; BOARD_PUBLIC=""; PUBLIC_REPOS=""
write_page "$PAGES/page-1.json" false "" "$(off_board 1)"
run "acme/repo" "acme/3"
check_adds "unknown board visibility does not block a private-board sweep" 1

exit $FAIL
