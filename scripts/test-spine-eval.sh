#!/usr/bin/env bash
# Offline test for spine-eval.sh — the static eval tier's own gate.
# Builds throwaway skills/ + evals/ trees in a temp dir and runs the real script.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAIL=0

seed() { # $1 = SKILL.md body for skills/demo-skill/
  rm -rf "$TMP/skills" "$TMP/evals"
  mkdir -p "$TMP/skills/demo-skill" "$TMP/evals"
  printf '%s\n' "$1" > "$TMP/skills/demo-skill/SKILL.md"
}
evals() { cat > "$TMP/evals/demo.json"; }   # reads JSON on stdin
run()   { ( cd "$TMP" && bash "$HERE/spine-eval.sh" "$@" ) 2>&1; }

ordering_evals() {
  evals <<'JSON'
{ "skill": "demo-skill",
  "assertions": [
    { "id": "approval-precedes-post", "kind": "precedes",
      "anchor": "get approval", "before": "gh issue comment",
      "why": "never posts unreviewed" } ] }
JSON
}

# 1. ordering holds -> pass, exit 0
seed 'Show the comment and get approval before posting (gh issue comment).'
ordering_evals
OUT="$(run)"; RC=$?
{ [ "$RC" = 0 ] && printf '%s' "$OUT" | grep -q 'approval-precedes-post'; } \
  && echo "PASS: satisfied ordering exits 0" \
  || { echo "FAIL: satisfied ordering (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 2. ordering inverted -> FAIL, non-zero
seed 'Post the comment (gh issue comment), then get approval.'
ordering_evals
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] && printf '%s' "$OUT" | grep -q 'FAIL'; } \
  && echo "PASS: inverted ordering fails" \
  || { echo "FAIL: inverted ordering not caught (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 3. anchor removed -> UNRESOLVED, and NOT reported as FAIL
seed 'Post the comment (gh issue comment) once the builder is happy.'
ordering_evals
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] \
  && printf '%s' "$OUT" | grep -q 'UNRESOLVED' \
  && ! printf '%s' "$OUT" | grep -q '✗ FAIL'; } \
  && echo "PASS: removed anchor is UNRESOLVED, not FAIL" \
  || { echo "FAIL: removed anchor mis-reported (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 4. anchor spanning a line break still resolves (hard-wrap normalization)
seed 'Show the comment and get
approval before posting (gh issue comment).'
ordering_evals
OUT="$(run)"; RC=$?
[ "$RC" = 0 ] \
  && echo "PASS: multi-line anchor resolves" \
  || { echo "FAIL: multi-line anchor (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 5. matching is case-insensitive
seed 'GET APPROVAL before posting (GH ISSUE COMMENT).'
ordering_evals
OUT="$(run)"; RC=$?
[ "$RC" = 0 ] \
  && echo "PASS: matching is case-insensitive" \
  || { echo "FAIL: case sensitivity (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 6. kind=contains — present passes, absent is UNRESOLVED
contains_evals() {
  evals <<'JSON'
{ "skill": "demo-skill",
  "assertions": [
    { "id": "never-a-file", "kind": "contains",
      "anchor": "never a file", "why": "principle 1" } ] }
JSON
}
seed 'The record is a comment on the closing issue — never a file.'
contains_evals
OUT="$(run)"; RC=$?
[ "$RC" = 0 ] && echo "PASS: contains present" \
  || { echo "FAIL: contains present (rc=$RC)"; echo "$OUT"; FAIL=1; }

seed 'The record is a comment on the closing issue.'
contains_evals
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] && printf '%s' "$OUT" | grep -q 'UNRESOLVED'; } \
  && echo "PASS: contains absent is UNRESOLVED" \
  || { echo "FAIL: contains absent (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 7. the why prints at the point of failure
seed 'Post the comment (gh issue comment), then get approval.'
ordering_evals
OUT="$(run)"
printf '%s' "$OUT" | grep -q 'never posts unreviewed' \
  && echo "PASS: why printed on failure" \
  || { echo "FAIL: why not printed"; echo "$OUT"; FAIL=1; }

# 8. a skill named by an eval file but absent from skills/ fails loudly
rm -rf "$TMP/skills"; mkdir -p "$TMP/skills"
ordering_evals
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] && printf '%s' "$OUT" | grep -qi 'missing skill'; } \
  && echo "PASS: missing skill fails loudly" \
  || { echo "FAIL: missing skill (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 9. no eval files at all is an error, not a silent green
rm -rf "$TMP/evals"; mkdir -p "$TMP/evals" "$TMP/skills/demo-skill"
printf 'x\n' > "$TMP/skills/demo-skill/SKILL.md"
OUT="$(run)"; RC=$?
[ "$RC" != 0 ] && echo "PASS: empty evals/ is an error" \
  || { echo "FAIL: empty evals/ passed silently"; echo "$OUT"; FAIL=1; }

# 10. unknown argument exits 2, not just non-zero
OUT="$(run --bogus-flag)"; RC=$?
[ "$RC" = 2 ] \
  && echo "PASS: unknown argument exits 2" \
  || { echo "FAIL: unknown argument (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 11. malformed JSON eval file fails loudly with a clear message
rm -rf "$TMP/skills" "$TMP/evals"
mkdir -p "$TMP/skills/demo-skill" "$TMP/evals"
printf 'x\n' > "$TMP/skills/demo-skill/SKILL.md"
printf '{ this is not valid json' > "$TMP/evals/demo.json"
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] && printf '%s' "$OUT" | grep -qi 'malformed'; } \
  && echo "PASS: malformed JSON fails loudly" \
  || { echo "FAIL: malformed JSON (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 12. coverage counts covered/total and names the uncovered
rm -rf "$TMP/skills" "$TMP/evals"
mkdir -p "$TMP/skills/demo-skill" "$TMP/skills/other-skill" "$TMP/evals"
printf 'get approval before posting (gh issue comment)\n' > "$TMP/skills/demo-skill/SKILL.md"
printf 'unrelated prose\n' > "$TMP/skills/other-skill/SKILL.md"
ordering_evals
OUT="$(run --coverage)"; RC=$?
{ [ "$RC" = 0 ] \
  && printf '%s' "$OUT" | grep -q '1/2' \
  && printf '%s' "$OUT" | grep -q 'other-skill'; } \
  && echo "PASS: coverage reports 1/2 and names the uncovered" \
  || { echo "FAIL: coverage report (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 13. ratchet fails when coverage is below the minimum
OUT="$(run --coverage --min-covered 2)"; RC=$?
[ "$RC" != 0 ] \
  && echo "PASS: ratchet fails below minimum" \
  || { echo "FAIL: ratchet did not fire"; echo "$OUT"; FAIL=1; }

# 14. ratchet passes when coverage meets the minimum
OUT="$(run --coverage --min-covered 1)"; RC=$?
[ "$RC" = 0 ] \
  && echo "PASS: ratchet passes at minimum" \
  || { echo "FAIL: ratchet false alarm"; echo "$OUT"; FAIL=1; }

# 15. an eval file with zero assertions does not count as coverage
evals <<'JSON'
{ "skill": "demo-skill", "assertions": [] }
JSON
OUT="$(run --coverage)"; RC=$?
{ [ "$RC" = 0 ] && printf '%s' "$OUT" | grep -q '0/2'; } \
  && echo "PASS: empty assertion list is not coverage" \
  || { echo "FAIL: empty assertion list counted (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 16. the 'before' side of a precedes assertion can go missing too — that is
#     UNRESOLVED (the harness lost its grip), never FAIL (the skill misbehaved)
seed 'Show the comment and get approval before publishing it by hand.'
ordering_evals
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] \
  && printf '%s' "$OUT" | grep -q 'UNRESOLVED' \
  && printf '%s' "$OUT" | grep -q "the 'before' side" \
  && ! printf '%s' "$OUT" | grep -q '✗ FAIL'; } \
  && echo "PASS: missing 'before' side is UNRESOLVED, not FAIL" \
  || { echo "FAIL: missing 'before' side mis-reported (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 17. an unknown assertion kind is a FAIL, not a silent skip
seed 'The record is a comment on the closing issue — never a file.'
evals <<'JSON'
{ "skill": "demo-skill",
  "assertions": [
    { "id": "bogus-kind", "kind": "forbids",
      "anchor": "never a file", "why": "kinds are contains and precedes only" } ] }
JSON
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] \
  && printf '%s' "$OUT" | grep -q 'FAIL' \
  && printf '%s' "$OUT" | grep -qi 'unknown assertion kind'; } \
  && echo "PASS: unknown assertion kind fails" \
  || { echo "FAIL: unknown assertion kind (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 18. the re-anchoring guidance prints on UNRESOLVED — the anti-erosion nudge
#     that tells a reader to re-anchor rather than delete the assertion
seed 'The record is a comment on the closing issue.'
contains_evals
OUT="$(run)"
printf '%s' "$OUT" | grep -q 're-anchor it to the rule' \
  && echo "PASS: re-anchoring guidance printed on UNRESOLVED" \
  || { echo "FAIL: re-anchoring guidance missing"; echo "$OUT"; FAIL=1; }

# 19. a non-numeric --min-covered is CLI misuse, not a silently disabled ratchet
OUT="$(run --coverage --min-covered abc)"; RC=$?
{ [ "$RC" = 2 ] && printf '%s' "$OUT" | grep -qi 'non-negative integer'; } \
  && echo "PASS: non-numeric --min-covered exits 2" \
  || { echo "FAIL: non-numeric --min-covered (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 20. a structurally wrong eval file (valid JSON, wrong shape) fails loudly
seed 'The record is a comment on the closing issue — never a file.'
evals <<'JSON'
[]
JSON
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] \
  && printf '%s' "$OUT" | grep -qi 'invalid eval file' \
  && printf '%s' "$OUT" | grep -q 'demo.json'; } \
  && echo "PASS: top-level array is an invalid eval file" \
  || { echo "FAIL: top-level array not caught (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 21. a JSON null is invalid shape, not "malformed JSON"
seed 'The record is a comment on the closing issue — never a file.'
evals <<'JSON'
null
JSON
OUT="$(run)"; RC=$?
{ [ "$RC" != 0 ] \
  && printf '%s' "$OUT" | grep -qi 'invalid eval file' \
  && ! printf '%s' "$OUT" | grep -qi 'malformed'; } \
  && echo "PASS: JSON null is invalid shape, not malformed" \
  || { echo "FAIL: JSON null mislabelled (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 22. check mode prints the honest denominator too, not only --coverage
rm -rf "$TMP/skills" "$TMP/evals"
mkdir -p "$TMP/skills/demo-skill" "$TMP/skills/other-skill" "$TMP/evals"
printf 'Show the comment and get approval before posting (gh issue comment).\n' \
  > "$TMP/skills/demo-skill/SKILL.md"
printf 'unrelated prose\n' > "$TMP/skills/other-skill/SKILL.md"
ordering_evals
OUT="$(run)"; RC=$?
{ [ "$RC" = 0 ] \
  && printf '%s' "$OUT" | grep -q '1/2' \
  && printf '%s' "$OUT" | grep -q 'other-skill'; } \
  && echo "PASS: check mode prints covered/total and the uncovered list" \
  || { echo "FAIL: check mode denominator (rc=$RC)"; echo "$OUT"; FAIL=1; }

# 24. the "last seen at commit" hint resolves despite case and regex metachars.
# Anchors are authored lowercase while prose is not, and `git log -S` is
# case-sensitive — a literal -S found nothing for almost every real anchor.
GT="$TMP/gitfix"; rm -rf "$GT"; mkdir -p "$GT/skills/demo-skill" "$GT/evals"
(
  cd "$GT" && git init -q .
  printf 'Rules\n\n- Never Write **The Thing** to a file.\n' > skills/demo-skill/SKILL.md
  git -c user.email=t@t -c user.name=t add -A >/dev/null
  git -c user.email=t@t -c user.name=t commit -qm "seed" >/dev/null
  printf 'Rules\n\n(rule removed)\n' > skills/demo-skill/SKILL.md
) >/dev/null 2>&1
cat > "$GT/evals/demo.json" <<'JSON'
{ "skill": "demo-skill",
  "assertions": [
    { "id": "never-write-the-thing", "kind": "contains",
      "anchor": "never write **the thing** to a file",
      "why": "guards the rule" } ] }
JSON
OUT="$( cd "$GT" && bash "$HERE/spine-eval.sh" 2>&1 )"; RC=$?
{ [ "$RC" != 0 ] \
  && printf '%s' "$OUT" | grep -q 'UNRESOLVED' \
  && printf '%s' "$OUT" | grep -Eq 'last seen at commit [0-9a-f]{7}'; } \
  && echo "PASS: last-seen hint resolves across case and regex metachars" \
  || { echo "FAIL: last-seen hint did not resolve (rc=$RC)"; echo "$OUT"; FAIL=1; }

[ "$FAIL" = 0 ] && echo "PASS: all spine-eval scenarios" || exit 1
