#!/usr/bin/env bash
# Tests for spine-audit.sh and spine-doctor.sh (#63, #64).
#
# gh is stubbed: SPINE_GH points at a fake that answers each command
# pattern from fixtures, so the scripts' logic runs without a live repo.
# Mirrors the drift checker's test style: each case prints PASS/FAIL,
# any FAIL flips the exit code.
set -u

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail=0
check() { # check <name> <expected-grep> <file>
  if grep -qE "$2" "$3"; then echo "PASS: $1"; else
    echo "FAIL: $1 — expected /$2/ in output:"; sed 's/^/    /' "$3"; fail=1
  fi
}
check_absent() { # check_absent <name> <forbidden-grep> <file>
  if grep -qE "$2" "$3"; then
    echo "FAIL: $1 — did not expect /$2/ in output:"; sed 's/^/    /' "$3"; fail=1
  else echo "PASS: $1"; fi
}

# --- gh stub ---------------------------------------------------------------
fix="$tmp/fix"; mkdir -p "$fix"
cat > "$tmp/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"repo view --json nameWithOwner"*)      echo "test/repo" ;;
  *"repo view --json defaultBranchRef"*)   echo "main" ;;
  *"issue list"*"--state closed"*)         cat "$FIX/closed.tsv" ;;
  *"issue view 1 "*)                       printf 'plain comment\n' ;;
  *"issue view 2 "*)                       printf '## Handover — closing #2\nrecorded\n' ;;
  *"pr list"*"length"*)                    echo "2" ;;
  *"pr list"*)                             cat "$FIX/prs_nocite.txt" ;;
  *"api repos/test/repo/branches"*)        cat "$FIX/branches.txt" ;;
  *"label list"*)                          cat "$FIX/labels.txt" ;;
  *"project item-list"*)                   cat "$FIX/board.json" ;;
  *"project view"*)                        exit 0 ;;
  *"issue list"*"--state open"*)           cat "$FIX/open_issues.txt" ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$tmp/gh"
export FIX="$fix" SPINE_GH="$tmp/gh"

# --- audit fixtures ---------------------------------------------------------
# #1 completed, no handover comment -> WARN
# #2 completed, has handover        -> clean
# #3 NOT_PLANNED                    -> skipped
printf '1\tCOMPLETED\n2\tCOMPLETED\n3\tNOT_PLANNED\n' > "$fix/closed.tsv"
printf '7\n' > "$fix/prs_nocite.txt"           # PR #7 cites no issue
printf 'main\nfeat/12-good-slug\nstray-branch\n' > "$fix/branches.txt"

out="$tmp/audit.out"
(cd "$tmp" && "$here/spine-audit.sh" > "$out" 2>&1)
rc=$?

[ "$rc" -eq 0 ] && echo "PASS: audit exits 0" || { echo "FAIL: audit exit $rc"; fail=1; }
check        "audit: missing handover warned"        "WARN: issue #1 closed as completed" "$out"
check_absent "audit: recorded handover not warned"   "issue #2"                           "$out"
check_absent "audit: NOT_PLANNED skipped"            "issue #3"                           "$out"
check        "audit: NOT_PLANNED counted in summary" "1 closed-as-not-planned skipped"    "$out"
check        "audit: non-citing PR warned"           "WARN: PR #7 merged without citing"  "$out"
check        "audit: stray branch warned"            "WARN: branch 'stray-branch'"        "$out"
check_absent "audit: conforming branch not warned"   "feat/12-good-slug"                  "$out"

# --- doctor fixtures ----------------------------------------------------------
# Repo has lane:mid but not lane:small; dialect names small (current) and
# records a rename away from lane:old (provenance — must not be flagged).
printf 'deferred\nlane:mid\n' > "$fix/labels.txt"
mkdir -p "$tmp/docs"
cat > "$tmp/docs/tracking-dialect.md" <<'NOTE'
- **Lane:** labels `lane:mid`, `lane:small`. (Renamed
  2026-07-11 from `lane:old` per owner decision.)
**Board owner:** `test-owner`
**`SPINE_BOARD_NUMBER`: 4**
NOTE
# Board holds issue 10 for this repo; open issues are 10 and 11 -> one missing.
cat > "$fix/board.json" <<'JSON'
{"items":[{"content":{"repository":"test/repo","number":10}},
          {"content":{"repository":"other/repo","number":99}}]}
JSON
printf '10\n11\n' > "$fix/open_issues.txt"

out="$tmp/doctor.out"
(cd "$tmp" && "$here/spine-doctor.sh" > "$out" 2>&1)
rc=$?

[ "$rc" -eq 0 ] && echo "PASS: doctor exits 0" || { echo "FAIL: doctor exit $rc"; fail=1; }
check        "doctor: missing current lane warned"   "WARN: label 'lane:small'"     "$out"
check_absent "doctor: renamed-away lane not flagged" "lane:old"                     "$out"
check_absent "doctor: present label not flagged"     "label 'deferred' missing"     "$out"
check        "doctor: stale board membership warned" "1 open issue\(s\).*not on board test-owner/projects/4" "$out"
check        "doctor: absent templates noted"        "NOTE: no .github/ISSUE_TEMPLATE" "$out"

# Missing deferred label -> WARN
printf 'lane:mid\n' > "$fix/labels.txt"
out="$tmp/doctor2.out"
(cd "$tmp" && "$here/spine-doctor.sh" > "$out" 2>&1)
check "doctor: missing deferred label warned" "WARN: label 'deferred' missing" "$out"

exit $fail
