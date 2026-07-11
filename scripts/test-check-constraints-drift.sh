#!/usr/bin/env bash
# Tests for check-constraints-drift.sh, run in a throwaway git repo.
set -eu
CHECKER="$(cd "$(dirname "$0")" && pwd)/check-constraints-drift.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q
git config user.email test@test && git config user.name test
mkdir docs

cat > docs/constraints.md <<'EOF'
<!-- canonical source — downstream docs copy the block below verbatim -->
<!-- constraints:begin -->
- rule one
- rule two
<!-- constraints:end -->
EOF
git add -A && git commit -qm "canonical v1"
sha=$(git rev-parse HEAD)

cat > docs/spec.md <<EOF
# a spec
<!-- constraints-copy: docs/constraints.md @ $sha -->
<!-- constraints:begin -->
- rule one
- rule two
<!-- constraints:end -->
EOF
git add -A && git commit -qm "spec with clean copy"

echo "test 1: clean copy passes"
"$CHECKER" || { echo "FAIL: clean copy should pass"; exit 1; }

echo "test 2: drifted copy fails"
cat > docs/spec.md <<EOF
# a spec
<!-- constraints-copy: docs/constraints.md @ $sha -->
<!-- constraints:begin -->
- rule one
- rule two DRIFTED
<!-- constraints:end -->
EOF
if "$CHECKER"; then echo "FAIL: drifted copy should fail"; exit 1; fi

echo "test 3: old pin stays green after canonical evolves"
git checkout -q docs/spec.md
cat > docs/constraints.md <<'EOF'
<!-- canonical source — downstream docs copy the block below verbatim -->
<!-- constraints:begin -->
- rule one, amended
<!-- constraints:end -->
EOF
git add -A && git commit -qm "canonical v2"
"$CHECKER" || { echo "FAIL: historical pin should stay green"; exit 1; }

echo "test 4: unreadable pin fails"
cat > docs/bad.md <<'EOF'
<!-- constraints-copy: docs/constraints.md @ 0000000 -->
<!-- constraints:begin -->
- rule one
<!-- constraints:end -->
EOF
git add docs/bad.md
if "$CHECKER"; then echo "FAIL: unreadable pin should fail"; exit 1; fi

echo "test 5: unparseable mention notes loudly but does not fail"
git rm -qf docs/bad.md
cat > docs/malformed.md <<'EOF'
<!-- constraints-copy: docs/constraints.md @ <commit sha> -->
<!-- constraints:begin -->
- rule one
<!-- constraints:end -->
EOF
git add docs/malformed.md
out=$("$CHECKER" 2>&1) || { echo "FAIL: unparseable mention must not fail the gate"; exit 1; }
printf '%s\n' "$out" | grep -q 'DRIFT-GATE NOTE' || { echo "FAIL: unparseable mention must print a NOTE"; exit 1; }

echo "test 6: marker with no adjacent constraints block fails loudly"
git rm -qf docs/malformed.md
cat > docs/detached.md <<EOF
# a doc
<!-- constraints-copy: docs/constraints.md @ $sha -->

some unrelated prose that pushes the block further down



<!-- constraints:begin -->
- rule one
<!-- constraints:end -->
EOF
git add docs/detached.md
out=$("$CHECKER" 2>&1) && { echo "FAIL: detached marker should fail"; exit 1; }
printf '%s\n' "$out" | grep -q 'no constraints block immediately after marker' || { echo "FAIL: detached marker must print the adjacency error"; exit 1; }

echo "all 6 tests passed"
