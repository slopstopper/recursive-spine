# Skill Behavioral Evals — Static Tier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gate every PR on the rules inside `SKILL.md` prose — a rewrite that drops a Never rule or inverts a degrade path fails CI instead of shipping green.

**Architecture:** `scripts/spine-eval.sh` reads `evals/*.json`, normalizes each `skills/<skill>/SKILL.md` to a single lowercase whitespace-collapsed line, and evaluates two assertion kinds against it: `contains` (anchor text is present) and `precedes` (anchor A occurs before anchor B). An anchor that no longer resolves reports `UNRESOLVED` — distinct from `FAIL` — because it means the harness lost its grip on the skill, not that the skill misbehaves. A `--coverage --min-covered N` mode ratchets how many skills carry assertions.

**Tech Stack:** bash (`set -uo pipefail`), `jq`, `awk index()`, `tr`. No new runtime dependency — both tools are already load-bearing in `validate.yml`.

**Spec:** `docs/superpowers/specs/2026-07-29-skill-behavioral-evals-design.md`
**Issue:** #68 (unblocks #87). **Scope:** static tier only; the behavioral tier is a separate plan.

## Global Constraints

- Follow the house convention exactly: `scripts/<name>.sh` + `scripts/test-<name>.sh`, `#!/usr/bin/env bash`, `set -uo pipefail`, tests print `PASS: …` / `FAIL: …` per case and exit non-zero if any failed.
- Paths are **relative to CWD** (`evals/`, `skills/`), matching `check-release-version.sh`; tests `cd` into a temp dir. Do not add env-var path overrides.
- `spine-eval.sh` **gates** (exits non-zero on FAIL or UNRESOLVED). This is deliberate and unlike `spine-audit.sh` / `spine-doctor.sh`, which are report-only and always exit 0.
- `UNRESOLVED` must be visually and semantically distinct from `FAIL` in both output and exit-path reasoning. Collapsing them is a plan failure.
- Every assertion in every eval file carries a non-empty `why`, and the `why` prints at the point of failure.
- Anchor matching normalizes: newlines → spaces, runs of spaces → one space, and lowercase on both haystack and needle. The skills are hard-wrapped at ~72 columns; without this, most real rules never resolve.
- The coverage line prints on success too, with the uncovered skills named. A green `2/8` must never read as "everything is guarded".
- `--min-covered` is a ratchet against regression, not a coverage target. Pilot value is exactly `2`.
- No new GitHub repos, no network, no secrets in this tier.
- **Anchor selection rule (proven, not assumed — see Amendment below).** For a
  rule stated within one sentence, use `contains` on the **complete rule phrase
  including its ordering word** (`get approval **before** posting`). Do *not*
  use `precedes` on two fragments of the same sentence: a rewrite can preserve
  the fragments' text order while inverting the meaning, and the assertion
  passes. Reserve `precedes` for **structural** ordering, where the anchors
  genuinely live in different sections (`## 2. Debts, before the close` before
  `## 4. Assemble, preview, post`).

## File Structure

```
scripts/spine-eval.sh              # NEW  the static tier runner (gates)
scripts/test-spine-eval.sh         # NEW  its own offline test suite
evals/handover.json                # NEW  5 assertions, all anchors pre-verified
evals/digest.json                  # NEW  5 assertions, all anchors pre-verified
.github/workflows/validate.yml     # MOD  two new steps
```

`evals/` holds data only. `scripts/` holds behavior. The runner never imports
from the eval files' structure beyond the documented schema, so adding a sixth
skill's evals is a data change with no code change.

**Eval file schema** (used by every task below):

```json
{
  "skill": "recursive-spine-handover",
  "assertions": [
    { "id": "kebab-case-unique-id",
      "kind": "contains" | "precedes",
      "anchor": "text that must exist in SKILL.md",
      "before": "only for kind=precedes: anchor must occur before this",
      "why": "why this rule matters — printed on failure" }
  ]
}
```

---

### Task 1: The runner — `contains`, `precedes`, and the UNRESOLVED distinction

**Files:**
- Create: `scripts/spine-eval.sh`
- Test: `scripts/test-spine-eval.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `scripts/spine-eval.sh`, invoked as `spine-eval.sh` (check mode). Exits `0` when all assertions pass, `1` on any FAIL or UNRESOLVED, `2` on an unknown CLI argument. Task 2 adds `--coverage --min-covered N` to the same file. Task 3 supplies real `evals/*.json`. Task 4 wires it into CI.

- [ ] **Step 1: Write the failing test**

Create `scripts/test-spine-eval.sh`:

```bash
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

[ "$FAIL" = 0 ] && echo "PASS: all spine-eval scenarios" || exit 1
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash scripts/test-spine-eval.sh`
Expected: fails immediately — `spine-eval.sh` does not exist yet, so every `run` produces a "No such file or directory" and the script exits non-zero.

- [ ] **Step 3: Write the runner**

Create `scripts/spine-eval.sh`:

```bash
#!/usr/bin/env bash
# Static tier of the skill behavioral evals (#68). Reads evals/*.json from CWD
# and checks each anchored assertion against skills/<skill>/SKILL.md.
#
#   ✓            the assertion holds
#   ✗ FAIL       anchors resolve, but the required order is violated
#   ⚠ UNRESOLVED anchor text is no longer in the skill — a human must look
#
# Exits non-zero on FAIL or UNRESOLVED. Unlike spine-audit.sh / spine-doctor.sh
# (report-only, always exit 0), this one gates.
#
#   scripts/spine-eval.sh
#   scripts/spine-eval.sh --coverage --min-covered N
set -uo pipefail

MODE="check"; MIN_COVERED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --coverage)    MODE="coverage" ;;
    --min-covered) shift; MIN_COVERED="${1:-0}" ;;
    *) echo "spine-eval: unknown argument '$1'" >&2; exit 2 ;;
  esac
  shift
done

# Hard-wrapped prose: collapse to one lowercase line before matching, or every
# rule that spans a line break reports UNRESOLVED forever.
flatten()   { tr '\n' ' ' < "$1" | tr -s ' ' | tr '[:upper:]' '[:lower:]'; }
lower()     { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
pos()       { awk -v s="$1" -v n="$2" 'BEGIN{print index(s,n)}'; }
last_seen() { git log -S"$1" --format=%h -1 -- "$2" 2>/dev/null | head -1; }

shopt -s nullglob
EVALS=(evals/*.json)
if [ "${#EVALS[@]}" = 0 ]; then
  echo "spine-eval: no eval files in evals/ (cwd=$(pwd))" >&2
  exit 1
fi

FAILS=0; UNRES=0; TOTAL=0

for f in "${EVALS[@]}"; do
  skill="$(jq -r '.skill // empty' "$f")"
  md="skills/$skill/SKILL.md"
  if [ ! -f "$md" ]; then
    echo "✗ MISSING SKILL  $skill (named by $f)"
    FAILS=$((FAILS + 1)); continue
  fi

  flat="$(flatten "$md")"
  n="$(jq -r '.assertions | length' "$f")"
  echo ""
  echo "$skill        $n assertions"

  i=0
  while [ "$i" -lt "$n" ]; do
    id="$(jq -r ".assertions[$i].id" "$f")"
    kind="$(jq -r ".assertions[$i].kind" "$f")"
    anchor="$(jq -r ".assertions[$i].anchor" "$f")"
    before="$(jq -r ".assertions[$i].before // empty" "$f")"
    why="$(jq -r ".assertions[$i].why" "$f")"
    TOTAL=$((TOTAL + 1))
    i=$((i + 1))

    a="$(pos "$flat" "$(lower "$anchor")")"
    if [ "$a" = 0 ]; then
      echo "  ⚠ UNRESOLVED  $id"
      echo "      anchor:  \"$anchor\""
      echo "      not found in $md"
      echo "      why:     $why"
      echo "      last seen at commit $(last_seen "$anchor" "$md" || true)"
      echo "      This is not a test failure. The prose this assertion guards"
      echo "      was edited or removed. Either re-anchor it to the rule's new"
      echo "      wording, or — if the rule was dropped on purpose — delete the"
      echo "      assertion in the same commit and say why in the message."
      UNRES=$((UNRES + 1)); continue
    fi

    case "$kind" in
      contains)
        echo "  ✓ $id" ;;
      precedes)
        b="$(pos "$flat" "$(lower "$before")")"
        if [ "$b" = 0 ]; then
          echo "  ⚠ UNRESOLVED  $id"
          echo "      anchor:  \"$before\"  (the 'before' side)"
          echo "      not found in $md"
          echo "      why:     $why"
          UNRES=$((UNRES + 1))
        elif [ "$a" -lt "$b" ]; then
          echo "  ✓ $id"
        else
          echo "  ✗ FAIL  $id"
          echo "      \"$anchor\" (at $a) must come before \"$before\" (at $b)"
          echo "      why:     $why"
          FAILS=$((FAILS + 1))
        fi ;;
      *)
        echo "  ✗ FAIL  $id — unknown assertion kind '$kind'"
        FAILS=$((FAILS + 1)) ;;
    esac
  done
done

echo ""
echo "spine-eval — $TOTAL assertions, $FAILS failed, $UNRES unresolved"
{ [ "$FAILS" = 0 ] && [ "$UNRES" = 0 ]; } || exit 1
```

- [ ] **Step 4: Make both scripts executable and run the tests**

```bash
chmod +x scripts/spine-eval.sh scripts/test-spine-eval.sh
bash scripts/test-spine-eval.sh
```

Expected: nine `PASS:` lines then `PASS: all spine-eval scenarios`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/spine-eval.sh scripts/test-spine-eval.sh
git commit -m "feat(evals): static tier runner — anchored contains/precedes assertions (#68)

UNRESOLVED (anchor no longer in the skill) is reported distinctly from
FAIL (anchor resolves, ordering violated): one says the harness lost its
grip on the prose, the other says the skill misbehaves.

Anchors are matched against a whitespace-collapsed lowercase form because
the skills are hard-wrapped at ~72 columns."
```

---

### Task 2: Coverage ratchet

**Files:**
- Modify: `scripts/spine-eval.sh` (add the `coverage` mode branch)
- Modify: `scripts/test-spine-eval.sh` (append cases before the final tally line)

**Interfaces:**
- Consumes: `scripts/spine-eval.sh` from Task 1, including its already-parsed `MODE` / `MIN_COVERED` variables and the `EVALS` array.
- Produces: `spine-eval.sh --coverage --min-covered N` — prints `spine-eval coverage — X/Y skills covered`, prints an `uncovered:` line naming every skill with no assertions, exits `1` if `X < N`, else `0`. A skill counts as covered when an eval file names it **and** has at least one assertion.

- [ ] **Step 1: Write the failing test**

In `scripts/test-spine-eval.sh`, insert immediately **before** the final
`[ "$FAIL" = 0 ] && echo "PASS: all spine-eval scenarios" || exit 1` line:

```bash
# 10. coverage counts covered/total and names the uncovered
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

# 11. ratchet fails when coverage is below the minimum
OUT="$(run --coverage --min-covered 2)"; RC=$?
[ "$RC" != 0 ] \
  && echo "PASS: ratchet fails below minimum" \
  || { echo "FAIL: ratchet did not fire"; echo "$OUT"; FAIL=1; }

# 12. ratchet passes when coverage meets the minimum
OUT="$(run --coverage --min-covered 1)"; RC=$?
[ "$RC" = 0 ] \
  && echo "PASS: ratchet passes at minimum" \
  || { echo "FAIL: ratchet false alarm"; echo "$OUT"; FAIL=1; }

# 13. an eval file with zero assertions does not count as coverage
evals <<'JSON'
{ "skill": "demo-skill", "assertions": [] }
JSON
OUT="$(run --coverage)"
printf '%s' "$OUT" | grep -q '0/2' \
  && echo "PASS: empty assertion list is not coverage" \
  || { echo "FAIL: empty assertion list counted"; echo "$OUT"; FAIL=1; }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash scripts/test-spine-eval.sh`
Expected: cases 1–9 still `PASS`; case 10 fails because `--coverage` currently
falls through to check mode and never prints `1/2`.

- [ ] **Step 3: Add the coverage branch**

In `scripts/spine-eval.sh`, insert this block immediately **after** the
`if [ "${#EVALS[@]}" = 0 ] … fi` guard and **before** the
`FAILS=0; UNRES=0; TOTAL=0` line:

```bash
if [ "$MODE" = "coverage" ]; then
  SKILLS=(skills/*/)
  covered=0; uncovered=""
  for d in "${SKILLS[@]}"; do
    name="$(basename "$d")"
    hit=0
    for f in "${EVALS[@]}"; do
      s="$(jq -r '.skill // empty' "$f")"
      n="$(jq -r '.assertions | length' "$f")"
      if [ "$s" = "$name" ] && [ "${n:-0}" -gt 0 ]; then hit=1; fi
    done
    if [ "$hit" = 1 ]; then
      covered=$((covered + 1))
    else
      uncovered="$uncovered $name"
    fi
  done
  # Always printed, including on success: a green 2/8 must never be mistaken
  # for "everything is guarded".
  echo "spine-eval coverage — $covered/${#SKILLS[@]} skills covered"
  [ -n "$uncovered" ] && echo "uncovered:$uncovered"
  if [ "$covered" -lt "$MIN_COVERED" ]; then
    echo "spine-eval: coverage regressed — $covered covered, minimum is $MIN_COVERED" >&2
    exit 1
  fi
  exit 0
fi
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash scripts/test-spine-eval.sh`
Expected: thirteen `PASS:` lines then `PASS: all spine-eval scenarios`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/spine-eval.sh scripts/test-spine-eval.sh
git commit -m "feat(evals): coverage ratchet with honest denominators (#68)

Prints covered/total and names every uncovered skill on success as well as
failure. --min-covered is a regression ratchet, not a target: it fails when
the count drops, so raising it later is a deliberate act visible in a diff."
```

---

### Task 3: The pilot eval files — handover and digest

**Files:**
- Create: `evals/handover.json`
- Create: `evals/digest.json`

**Interfaces:**
- Consumes: `scripts/spine-eval.sh` from Tasks 1–2, and the eval file schema in **File Structure** above.
- Produces: two eval files that make `scripts/spine-eval.sh` exit 0 and
  `scripts/spine-eval.sh --coverage --min-covered 2` exit 0 against the real
  repo. Task 4 wires those two invocations into CI.

Every anchor below was verified to resolve against the current `SKILL.md` files
before this plan was written. If one reports `UNRESOLVED` on a later `main`, the
prose moved — re-anchor it, do not delete it.

- [ ] **Step 1: Write `evals/handover.json`**

Anchors follow the **anchor selection rule** in Global Constraints. Every one
below was executed against the real `SKILL.md` and passes; the first two were
additionally proven to catch a semantic inversion that a fragment-based
`precedes` let through.

```json
{
  "skill": "recursive-spine-handover",
  "assertions": [
    { "id": "approval-before-posting",
      "kind": "contains",
      "anchor": "get approval **before** posting",
      "why": "diff-first; the ordering word IS the rule — never post unreviewed" },

    { "id": "debts-before-closing-comment",
      "kind": "contains",
      "anchor": "**before** the closing comment is posted",
      "why": "principle 4 — the ordering word IS the rule" },

    { "id": "debts-section-precedes-post-section",
      "kind": "precedes",
      "anchor": "## 2. debts, before the close",
      "before": "## 4. assemble, preview, post",
      "why": "structural: debts are collected before the posting step" },

    { "id": "record-is-comment-never-file",
      "kind": "contains",
      "anchor": "never a file",
      "why": "principle 1 — a docs/handovers/ directory would be a prose ledger" },

    { "id": "no-orphan-debt",
      "kind": "contains",
      "anchor": "never posts one",
      "why": "a closing comment naming an unfiled debt is a principle-4 violation" },

    { "id": "pollen-question-asked",
      "kind": "contains",
      "anchor": "any pollen to capture",
      "why": "principle 4's sibling question, asked in its exact wording" },

    { "id": "has-never-section",
      "kind": "contains",
      "anchor": "## never",
      "why": "the skill's hard prohibitions must remain a named section" },

    { "id": "degrade-paths-loud",
      "kind": "contains",
      "anchor": "degrade paths (loud, never silent)",
      "why": "degradation must stay loud by name, not silent" }
  ]
}
```

- [ ] **Step 2: Write `evals/digest.json`**

```json
{
  "skill": "recursive-spine-digest",
  "assertions": [
    { "id": "self-in-sweep",
      "kind": "contains",
      "anchor": "always in the sweep",
      "why": "a digest that exempts its own repo is lying about its coverage" },

    { "id": "absent-scripts-declared",
      "kind": "contains",
      "anchor": "installation predates the health scripts",
      "why": "missing health scripts are a reported line, never a silent skip" },

    { "id": "unfiled-debts-not-auto-filed",
      "kind": "contains",
      "anchor": "do not auto-file",
      "why": "the digest flags for human eyes; filing is the builder's act" },

    { "id": "healthy-children-folded",
      "kind": "contains",
      "anchor": "healthy children stay folded",
      "why": "leak-by-age rollup — the shape #87's scenario will exercise" },

    { "id": "honest-denominators",
      "kind": "contains",
      "anchor": "honest denominators",
      "why": "the promise the digest's whole credibility rests on" }
  ]
}
```

- [ ] **Step 3: Run the runner against the real repo**

```bash
scripts/spine-eval.sh
```

Expected: two skill blocks, thirteen `✓` lines, and
`spine-eval — 13 assertions, 0 failed, 0 unresolved`. Exit 0.

- [ ] **Step 4: Verify the gate actually catches an inverted rule**

Prove the gate bites before trusting it. Both doctoring commands below were
executed during planning and both produce `exit=1`:

```bash
cp skills/recursive-spine-handover/SKILL.md /tmp/handover-backup.md

# (a) semantic inversion — the rule's ordering word is removed
perl -0pi -e 's/get approval \*\*before\*\* posting/post, then get approval/' \
  skills/recursive-spine-handover/SKILL.md
scripts/spine-eval.sh; echo "exit=$?"
cp /tmp/handover-backup.md skills/recursive-spine-handover/SKILL.md

# (b) structural reorder — the debts section is renumbered after the close
perl -0pi -e 's/## 2\. Debts, before the close/## 9. Debts, after the close/' \
  skills/recursive-spine-handover/SKILL.md
scripts/spine-eval.sh; echo "exit=$?"
cp /tmp/handover-backup.md skills/recursive-spine-handover/SKILL.md
```

Expected: (a) prints `⚠ UNRESOLVED  approval-before-posting` with the anchor
and `why` beneath it, `exit=1`. (b) prints
`⚠ UNRESOLVED  debts-section-precedes-post-section`, `exit=1`.

Then confirm the restore is clean: `git diff --exit-code skills/` — expected no
output, exit 0.

**Do not weaken these anchors to fragments if they ever feel brittle.** The
fragment form (`anchor: "get approval"`, `before: "gh issue comment"`) was
tried first and *silently passed* case (a) — the inversion left both fragments
in their original text order. That is the failure this plan exists to prevent.

- [ ] **Step 5: Check coverage reports honestly**

```bash
scripts/spine-eval.sh --coverage --min-covered 2
```

Expected: `spine-eval coverage — 2/8 skills covered`, an `uncovered:` line
naming `recursive-spine-bootstrap`, `recursive-spine-method`,
`recursive-spine-migrate`, `recursive-spine-nudge`,
`recursive-spine-pollinate`, `recursive-spine-scaffold`, and exit 0.

- [ ] **Step 6: Commit**

```bash
git add evals/handover.json evals/digest.json
git commit -m "feat(evals): pilot assertions for handover and digest (#68)

Thirteen anchored assertions over the two highest-stakes skills: handover's
ordering rules (approval before posting, debts before close, debts section
before the posting section) plus its Never and degrade-path sections, and
digest's honesty rules (self in sweep, absent scripts declared, honest
denominators).

Anchors carry the ordering word ('**before**') rather than being fragments
either side of it: the fragment form silently passed a rewrite that inverted
the meaning while preserving text order.

Coverage is 2/8 and says so."
```

---

### Task 4: CI wiring

**Files:**
- Modify: `.github/workflows/validate.yml` (append two steps)

**Interfaces:**
- Consumes: `scripts/spine-eval.sh` (Tasks 1–2) and `evals/*.json` (Task 3).
- Produces: the static tier running on every push to `main` and every PR. Nothing depends on this task.

`scripts/test-spine-eval.sh` needs **no** wiring — `release.yml`'s gate already
globs `scripts/test-*.sh` and will pick it up.

- [ ] **Step 1: Add the two steps**

In `.github/workflows/validate.yml`, append after the existing
`Constraints copies match their pinned canonical source` step, at the same
indentation (6 spaces before `- name:`):

```yaml
      - name: Skill assertions hold
        run: scripts/spine-eval.sh

      - name: Eval coverage has not regressed
        run: scripts/spine-eval.sh --coverage --min-covered 2
```

- [ ] **Step 2: Verify the workflow is still valid YAML and the steps run**

```bash
python3 -c "import sys,yaml" 2>/dev/null \
  && python3 -c "import yaml;yaml.safe_load(open('.github/workflows/validate.yml'));print('yaml ok')" \
  || echo "no pyyaml — skipping parse check"
scripts/spine-eval.sh && scripts/spine-eval.sh --coverage --min-covered 2
echo "exit=$?"
```

Expected: `exit=0`, ten `✓` lines, and the `2/8` coverage line.

- [ ] **Step 3: Run the full local gate as CI would**

```bash
jq -e '.name == "recursive-spine" and (.description | length > 0)' .claude-plugin/plugin.json >/dev/null && echo "manifest ok"
scripts/check-constraints-drift.sh && echo "drift ok"
bash scripts/test-spine-eval.sh
scripts/spine-eval.sh
```

Expected: `manifest ok`, `drift ok`, `PASS: all spine-eval scenarios`, and a
clean eval run. Any failure here is a blocker — do not commit past it.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/validate.yml
git commit -m "ci(evals): gate every PR on the static skill assertions (#68)

Two steps in validate.yml: the assertions themselves, and a coverage
ratchet pinned at the pilot's 2. test-spine-eval.sh needs no wiring —
release.yml's scripts/test-*.sh glob already picks it up."
```

---

### Task 5: File the debts the spec names

**Files:** none — this task files GitHub issues and posts a comment.

**Interfaces:**
- Consumes: the completed static tier from Tasks 1–4.
- Produces: filed issue numbers, to be cited in #68's eventual closing record.

Principle 4: a unit's known-incomplete edges become issues **before** the unit
closes. All five are named in the spec; none may be left as memory.

- [ ] **Step 1: File the debts**

```bash
gh issue create --label deferred --label "lane:small" \
  --title "evals: 'forbids' assertion kind, cut from the pilot as too heuristic" \
  --body "The static tier ships with \`contains\` and \`precedes\` only. \`forbids\` (a phrase must not appear) was cut because the phrases worth forbidding — e.g. \`docs/handovers/\` — legitimately appear in the skills as *named anti-patterns*, so it needs a negation heuristic (skip lines containing never/not/avoid/retires) too fragile to be load-bearing in a gate whose only asset is credibility. Revisit if a real prose edit demonstrates the need. Spec: docs/superpowers/specs/2026-07-29-skill-behavioral-evals-design.md. Refs #68"

gh issue create --label deferred --label "lane:mid" \
  --title "evals: behavioral tier — stubbed gh, call-log assertions, advisory judge" \
  --body "Tier 2 of the #68 design, split out as its own plan because it is a distinct subsystem (model invocation, \`evals/stub/gh\`, fixtures). Call-log assertions gate; a judge model advises without a vote. Fires at named moments only (release, milestone close, workflow_dispatch) — never continuously. Unblocks #87. Spec: docs/superpowers/specs/2026-07-29-skill-behavioral-evals-design.md. Refs #68, #87"

gh issue create --label deferred --label "lane:small" \
  --title "evals: fixture drift — canned gh responses can diverge from real gh output" \
  --body "The behavioral tier stubs \`gh\` with canned JSON. If GitHub changes a field, the fixtures do not, and the evals certify behavior against a \`gh\` that no longer exists. A disposable throwaway repo was considered and rejected *for the pilot* on merits (needs a write-scoped token, adds minutes, orphans repos on a failed run, and still cannot simulate the failure paths) — not ruled out permanently. Revisit if drift is ever observed. Refs #68"

gh issue create --label deferred --label "lane:small" \
  --title "evals: six skills carry no assertions (coverage 2/8)" \
  --body "The pilot covers handover and digest. Uncovered: bootstrap, method, migrate, nudge, pollinate, scaffold. \`scripts/spine-eval.sh --coverage\` reports this honestly on every run and ratchets at \`--min-covered 2\`; raising it is a deliberate diff. Attach as sub-issues of #68 per the depth convention. Refs #68"

gh issue create --label deferred --label "lane:small" \
  --title "CI: scripts/test-*.sh run only at release, not on PRs" \
  --body "Pre-existing gap noticed while wiring #68: \`release.yml\` globs \`scripts/test-*.sh\` in its gate, but \`validate.yml\` runs none of them. So every script's own test suite — including the new \`test-spine-eval.sh\` — is unverified until release time. Not widened into #68's scope; filed instead. Refs #68"
```

- [ ] **Step 2: Attach them as sub-issues of #68**

Follow `reference/sub-issues.md` (Attach). If attachment fails, degrade loudly
per that reference: proceed, and say in #68's comment that the tree is
incomplete and why.

- [ ] **Step 3: Record the debts on #68**

Post a comment on #68 listing each filed issue by number and what it covers, so
the lineage is a query rather than comment archaeology. Do **not** close #68 —
the behavioral tier is still outstanding under it.

- [ ] **Step 4: Verify**

```bash
gh issue list --state open --search "evals in:title" --json number,title \
  --template '{{range .}}#{{.number}} {{.title}}{{"\n"}}{{end}}'
```

Expected: the five new issues listed.

---

## Self-Review

**Spec coverage.** Every static-tier requirement maps to a task: two tiers →
Task 4 wires tier 1, tier 2 filed as a debt in Task 5; anchored assertions and
the drift argument → Tasks 1 and 3; whitespace normalization → Task 1 Step 3
plus test case 4; `contains`/`precedes` and the cut `forbids` → Task 1 and
Task 5 debt 1; `why` required and printed → Task 1 test case 7; call log,
judge, fixtures, `evals/stub/gh` → deferred to the tier-2 plan by the scope
split; no new GitHub repos → nothing in this plan touches the network;
`scripts/` convention and no new dependency → Global Constraints; CI wiring and
the ratchet → Tasks 2 and 4; the report's three properties (`UNRESOLVED` ≠
`FAIL`, `why` at point of failure, coverage always printed) → Task 1 Step 3,
test cases 3 and 7, Task 2 Step 3; `last seen at commit` → `last_seen()` in
Task 1 Step 3; pilot scope and the four named debts → Tasks 3 and 5.

**Placeholder scan.** No TBD/TODO. Every code step carries complete runnable
content; every command states its expected output.

**Type consistency.** Names used identically across tasks: `flatten`, `lower`,
`pos`, `last_seen`, `MODE`, `MIN_COVERED`, `EVALS`, `FAILS`, `UNRES`, `TOTAL`,
`covered`, `uncovered`. Test helpers `seed`, `evals`, `run`, `ordering_evals`,
`contains_evals` are defined in Task 1 Step 1 and reused unchanged in Task 2.
Task 2's new cases are appended before the tally line, so `FAIL` accumulates
across all thirteen.

**Known deviation from the spec, deliberate:** the spec's `evals/bin/` layout is
replaced by `scripts/`, because the real repo has seven `scripts/<name>.sh` +
`scripts/test-<name>.sh` pairs and one glob in `release.yml` that depends on
that naming. Following the house convention beats following the spec's sketch.

## Amendment — the fragment-`precedes` weakness (found during planning)

The spec's worked example used `{"kind":"precedes", "anchor":"get approval",
"before":"gh issue comment"}`. The runner was prototyped and run against the
real `handover/SKILL.md` before this plan was finalized, and that assertion
**silently passed** a rewrite of `get approval **before** posting` into
`post, then get approval` — because the literal text "get approval" still
occurs earlier in the document than "gh issue comment". Text order survived;
the meaning inverted.

The fix is anchor selection, not a runner change: anchor on the whole rule
phrase including its ordering word. Re-run against the same doctored file, the
corrected assertion reports `UNRESOLVED` and exits 1. A structural reorder
(`## 2. Debts, before the close` → `## 9. Debts, after the close`) is caught by
the one remaining `precedes`, which spans sections rather than fragments of one
sentence.

This is recorded rather than quietly fixed because the spec is committed and
approved, and because the general rule it yields — *the ordering word is the
rule; anchor on it* — belongs in the eventual pollen record if this pattern
ever proves itself widely.

**Verified during planning** (prototype, not yet the committed script): all 13
assertions pass against current prose; the two doctoring cases both exit 1;
coverage prints `2/8` and names the six uncovered skills; the multi-line,
case-insensitive, missing-skill, empty-`evals/`, and zero-assertion cases all
behave as the tests specify.
