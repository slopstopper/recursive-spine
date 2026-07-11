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

echo "test 7: fenced example with well-formed but unreadable pin is ignored"
git rm -qf docs/detached.md
cat > docs/example-doc.md <<'EOF'
# a spec explaining the marker format

```
<!-- constraints-copy: docs/constraints.md @ 0000000 -->
<!-- constraints:begin -->
- rule one
<!-- constraints:end -->
```
EOF
git add docs/example-doc.md
out=$("$CHECKER" 2>&1) || { echo "FAIL: fenced example must not fail the gate"; exit 1; }
printf '%s\n' "$out" | grep -q 'DRIFT-GATE FAIL' && { echo "FAIL: fenced example must print no DRIFT-GATE FAIL"; exit 1; }
git rm -qf docs/example-doc.md

echo "test 8: mixed fences don't swallow a later real drift"
cat > docs/mixed-fence.md <<EOF
# doc with a tilde fence containing a backtick fence as content

~~~
this tilde fence contains a backtick fence as plain content:
\`\`\`
not a real close, just content inside the tilde fence
\`\`\`
still inside the tilde fence
~~~

now the tilde fence is closed; this marker is real and drifted:
<!-- constraints-copy: docs/constraints.md @ $sha -->
<!-- constraints:begin -->
- rule one drifted for real
<!-- constraints:end -->
EOF
git add docs/mixed-fence.md
out=$("$CHECKER" 2>&1) && { echo "FAIL: real drift after mixed fences should fail"; exit 1; }
printf '%s\n' "$out" | grep -q 'DRIFT-GATE FAIL.*docs/mixed-fence.md' || { echo "FAIL: mixed-fence drift must be reported"; exit 1; }
git rm -qf docs/mixed-fence.md

echo "test 9: unclosed fence prints a loud note but still passes"
cat > docs/unclosed-fence.md <<EOF
# doc with a fence that never closes

\`\`\`
this fence never closes, and this marker below must not be scanned:
<!-- constraints-copy: docs/constraints.md @ $sha -->
<!-- constraints:begin -->
- rule one
<!-- constraints:end -->
EOF
git add docs/unclosed-fence.md
out=$("$CHECKER" 2>&1) || { echo "FAIL: unclosed fence alone must not fail the gate"; exit 1; }
printf '%s\n' "$out" | grep -q 'DRIFT-GATE NOTE.*unclosed code fence' || { echo "FAIL: unclosed fence must print an UNCLOSED note"; exit 1; }
git rm -qf docs/unclosed-fence.md

echo "all 9 tests passed"
