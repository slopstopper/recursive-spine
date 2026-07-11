# Vertebra 3: Connective Tissue Implementation Plan (#33)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship vertebra 3 — `docs/constraints.md` as the canonical constraints source, a sha-pinned drift gate in CI, scaffold's fifth part, and the seventh skill `recursive-spine-handover` — plus packaging v0.6.0 and a README full-pass.

**Architecture:** Two thin pieces connected by one file: a canonical constraints file whose delimited block downstream docs copy verbatim under a sha-pinned provenance line (a bash checker in CI fails drift; historical pins stay green), and a new closing-moment skill that posts the handover record as a comment on the closing issue. Scaffold stamps the connective tissue onto other repos as its fifth optional part.

**Tech Stack:** Markdown skill files, bash (checker + tests), GitHub Actions (validate.yml), jq, gh CLI.

## Global Constraints

Copied from the approved spec (`docs/superpowers/specs/2026-07-11-connective-tissue-design.md`) and the repo record:

- Nothing invented ships: frames are structure + interview-slot comments only; this repo's stamped artifacts come from the record.
- Kin wiring is data in the dialect note, never skill text; offers, never requirements. Tokenomics' handoff-spec is offered, never produced or required.
- Every skill's `description:` frontmatter opens with its moment of use (moment-based surfacing pollen).
- Skill names are self-prefixed: `recursive-spine-<name>`. The seventh skill is `recursive-spine-handover`.
- The handover record is a **comment on the closing issue** — never a file; no `docs/handovers/` directory may be created.
- The pollen question uses principle 4's exact wording: "any pollen to capture?"
- Drift gate is sha-pinned: copies are checked against the canonical file **at the pinned sha** (`git show <sha>:<path>`), so merged docs stay green when the canonical file evolves. Staleness is the digest's concern, not CI's.
- Honest denominators: "none" always says how it was checked; degrade loudly, never silently.
- GitHub Actions checkout stays pinned to `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4`.
- Packaging: plugin version `0.6.0`; seven skills listed in both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
- README claims are recalculated at write time against the live record (gh queries), not assumed; the maturity gate (no "battle-tested"/"production-ready") must stay green.
- Do not touch any existing GitHub issue bodies, comments, or milestones (flip-residue edits are deferred per #40/#10).
- Branch: `feat/33-connective-tissue` (already exists, holds the spec). Commits reference #33.

---

### Task 1: Drift checker script + its test script

**Files:**
- Create: `scripts/check-constraints-drift.sh`
- Test: `scripts/test-check-constraints-drift.sh`

**Interfaces:**
- Produces: `scripts/check-constraints-drift.sh` — no arguments, run from repo root; exits 0 when every `constraints-copy` block matches its pinned canonical source, 1 otherwise, printing `DRIFT-GATE FAIL: <file>:<line> — <reason>` plus a diff. Later tasks (validate.yml step in Task 2, scaffold part 5 in Task 3) call it by this exact path.
- Marker contract consumed by all later tasks:

  ```markdown
  <!-- constraints-copy: docs/constraints.md @ <7-40 char sha> -->
  <!-- constraints:begin -->
  ...copied block...
  <!-- constraints:end -->
  ```

- [ ] **Step 1: Write the failing test**

Create `scripts/test-check-constraints-drift.sh`:

```bash
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
git rm -q docs/bad.md
cat > docs/malformed.md <<'EOF'
<!-- constraints-copy: docs/constraints.md @ <commit sha> -->
<!-- constraints:begin -->
- rule one
<!-- constraints:end -->
EOF
git add docs/malformed.md
out=$("$CHECKER" 2>&1) || { echo "FAIL: unparseable mention must not fail the gate"; exit 1; }
printf '%s\n' "$out" | grep -q 'DRIFT-GATE NOTE' || { echo "FAIL: unparseable mention must print a NOTE"; exit 1; }

echo "all 5 tests passed"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `chmod +x scripts/test-check-constraints-drift.sh && scripts/test-check-constraints-drift.sh`
Expected: FAIL — `check-constraints-drift.sh: No such file or directory` (or non-executable).

- [ ] **Step 3: Write the checker**

Create `scripts/check-constraints-drift.sh`:

```bash
#!/usr/bin/env bash
# Drift gate for the connective-tissue vertebra (#33).
#
# Every constraints-copy block must byte-match the canonical constraints
# file AT THE SHA its provenance line pins:
#
#   <!-- constraints-copy: <path> @ <sha> -->
#   <!-- constraints:begin -->
#   ...copied block...
#   <!-- constraints:end -->
#
# Sha-pinning keeps merged docs green when the canonical file evolves;
# stale pins are the digest's concern, not CI's. Requires full git
# history (fetch-depth: 0 in CI).
#
# Exits 0 when all copies match, 1 otherwise, naming the doc, the pinned
# sha, and the exact diff. Templates documenting the marker format are
# excluded by pathspec below.
set -u

first_block() {
  awk '/<!-- constraints:begin -->/{f=1;next} /<!-- constraints:end -->/{exit} f'
}

fail=0
for file in $(git grep -l -e 'constraints-copy:' -- ':!scripts/' ':!reference/templates/' 2>/dev/null); do
  while IFS=: read -r ln _; do
    line=$(sed -n "${ln}p" "$file")
    src=$(printf '%s\n' "$line" | sed -nE 's/.*constraints-copy: *([^ ]+) @ ([0-9a-f]{7,40}) .*/\1/p')
    sha=$(printf '%s\n' "$line" | sed -nE 's/.*constraints-copy: *([^ ]+) @ ([0-9a-f]{7,40}) .*/\2/p')
    if [ -z "$src" ] || [ -z "$sha" ]; then
      # Docs that DOCUMENT the marker format (specs, plans, frames) contain
      # placeholder mentions like "@ <commit sha>" — note them loudly, but
      # only well-formed markers are verifiable claims.
      echo "DRIFT-GATE NOTE: $file:$ln — unparseable constraints-copy mention (documentation? a real marker must be: constraints-copy: <path> @ <hex sha>)"
      continue
    fi
    canonical=$(git show "${sha}:${src}" 2>/dev/null | first_block)
    if [ -z "$canonical" ]; then
      echo "DRIFT-GATE FAIL: $file:$ln — cannot read $src @ $sha (bad sha, bad path, or shallow clone; CI needs fetch-depth: 0)"
      fail=1
      continue
    fi
    copied=$(tail -n +"$ln" "$file" | first_block)
    if [ "$copied" != "$canonical" ]; then
      echo "DRIFT-GATE FAIL: $file:$ln — copy drifted from $src @ $sha:"
      diff <(printf '%s\n' "$canonical") <(printf '%s\n' "$copied") | sed 's/^/    /'
      fail=1
    fi
  done < <(grep -n -e 'constraints-copy:' "$file")
done
exit $fail
```

Then: `chmod +x scripts/check-constraints-drift.sh`

Implementation notes that matter:
- `git grep -l` searches tracked files' working-tree content; the test adds files with `git add` before checking — keep that.
- The marker regex requires a trailing space after the sha inside `-->`; the marker format always ends `<sha> -->` so the pattern `@ ([0-9a-f]{7,40}) .*` matches. Unparseable mentions (placeholder examples in docs that document the format) print a `DRIFT-GATE NOTE` and are skipped, never failed — test 5 covers this. Do not "simplify" the regex.
- `:!scripts/` excludes both checker and test (they contain the literal marker text); `:!reference/templates/` excludes frames that document the format.

- [ ] **Step 4: Run the test to verify it passes**

Run: `scripts/test-check-constraints-drift.sh`
Expected: `all 5 tests passed` (and each `ok`/`test N` line before it).

- [ ] **Step 5: Commit**

```bash
git add scripts/check-constraints-drift.sh scripts/test-check-constraints-drift.sh
git commit -m "feat(#33): sha-pinned constraints drift checker + tests"
```

---

### Task 2: Canonical constraints file + CI wiring

**Files:**
- Create: `docs/constraints.md`
- Modify: `.github/workflows/validate.yml`

**Interfaces:**
- Consumes: `scripts/check-constraints-drift.sh` (Task 1), run as `scripts/check-constraints-drift.sh` from repo root.
- Produces: `docs/constraints.md` with the delimited block later tasks and future docs copy; a `validate.yml` step named `Constraints copies match their pinned canonical source`.

- [ ] **Step 1: Write this repo's canonical constraints file**

Create `docs/constraints.md`. Every line in the block is on the repo record (principles, dialect note, CI gates, surfacing pollen) — nothing invented:

```markdown
# Global constraints — recursive-spine

<!-- Canonical source (connective tissue, #33). Downstream docs — specs,
     plans, handover comments — copy the block below verbatim under a
     provenance line:

       constraints-copy: docs/constraints.md @ <commit sha>

     The drift gate (scripts/check-constraints-drift.sh, wired into
     .github/workflows/validate.yml) fails any copy that does not match
     this file at its pinned sha. Only the block between the markers is
     the copyable unit; prose outside it is never checked. -->

<!-- constraints:begin -->
- Nothing invented ships: worked examples, pollen, and frames are structure-faithful abstractions of real use.
- Kin wiring (plumb-line, tokenomics) is data in the dialect note, never skill text; offers, never requirements.
- Every skill's `description:` frontmatter opens with its moment of use.
- Skill names are self-prefixed: `recursive-spine-<name>`.
- GitHub Actions checkout stays pinned to `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5`.
- README status claims carry honest denominators; the maturity gate bans "battle-tested" and "production-ready".
<!-- constraints:end -->

Rationale and history live in `reference/principles.md` and
`docs/tracking-dialect.md`; this file holds only the copyable set.
```

- [ ] **Step 2: Wire the gate into validate.yml**

In `.github/workflows/validate.yml`, replace the checkout line:

```yaml
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4
```

with:

```yaml
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4
        with:
          fetch-depth: 0 # drift gate reads canonical file at pinned shas
```

and append this step at the end of the `steps:` list (after the pollen front-matter step):

```yaml
      - name: Constraints copies match their pinned canonical source
        run: scripts/check-constraints-drift.sh
```

- [ ] **Step 3: Run the checker and existing gates locally**

Run:

```bash
scripts/check-constraints-drift.sh && echo DRIFT-GATE-OK
jq -e '.name == "recursive-spine" and (.description | length > 0)' .claude-plugin/plugin.json
! grep -inE 'battle-tested|production-ready' README.md && echo MATURITY-OK
```

Expected: `DRIFT-GATE-OK` (no copies exist yet — trivially green, which is correct), the jq object output, `MATURITY-OK`.

- [ ] **Step 4: Validate the workflow YAML parses**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/validate.yml')); print('YAML-OK')"`
Expected: `YAML-OK` (if PyYAML is unavailable, `ruby -ryaml -e "YAML.load_file('.github/workflows/validate.yml'); puts 'YAML-OK'"`).

- [ ] **Step 5: Commit**

```bash
git add docs/constraints.md .github/workflows/validate.yml
git commit -m "feat(#33): canonical constraints file + drift gate in validate.yml"
```

---

### Task 3: Scaffold's fifth part (constraints frame + skill text)

**Files:**
- Create: `reference/templates/scaffold/constraints-frame.md`
- Modify: `skills/recursive-spine-scaffold/SKILL.md`

**Interfaces:**
- Consumes: the marker contract from Task 1; `scripts/check-constraints-drift.sh` as the artifact scaffold copies into target repos.
- Produces: scaffold part 5, referenced by the dialect-note recording in Task 8.

- [ ] **Step 1: Create the constraints frame**

Create `reference/templates/scaffold/constraints-frame.md`:

```markdown
# Global constraints — <REPO_NAME>

<!-- Canonical source for this repo's global constraints (connective
     tissue). Downstream docs — specs, plans, handover comments — copy
     the block below verbatim under a provenance line:

       constraints-copy: docs/constraints.md @ <commit sha>

     The drift gate (scripts/check-constraints-drift.sh) fails any copy
     that does not match this file at its pinned sha. Only the block
     between the markers is the copyable unit. -->

<!-- constraints:begin -->
<!-- interview: one constraint per line, exact values, the builder's
     words — version floors, naming and copy rules, platform
     requirements, API contracts. No defaults are offered; an empty
     interview means this part is not stamped. -->
<!-- constraints:end -->

<!-- Prose below the block (rationale, history) is free-form and never
     checked. -->
```

- [ ] **Step 2: Update the scaffold skill's frontmatter description**

In `skills/recursive-spine-scaffold/SKILL.md`, replace the `description:` line with exactly:

```yaml
description: Use when a repo has (or is getting) the tracking stamp and needs the rest of its spine — interviews for and stamps up to five parts, each optional: a rules codex with a moments map, an ADR directory, a CI gate skeleton, a session-memory convention, and a constraints file with its sha-pinned drift gate. Frames + the builder's answers + proven pollen from their hives; nothing invented ships. Offers recursive-spine-bootstrap first when tracking is missing; records every answer, including declines, in the dialect note.
```

- [ ] **Step 3: Retitle section 2 and add part 5**

Change the section heading `## 2. The four parts (interview one at a time, all optional)` to `## 2. The five parts (interview one at a time, all optional)`, and append after item 4 (session-memory convention):

```markdown
5. **Constraints file + drift gate** — "hand-copied constraints blocks
   rot independently; drift is a measured vector, not a hypothetical."
   Frame: `constraints-frame.md`. Interview: which exact-valued
   constraints (version floors, naming/copy rules, platform
   requirements, API contracts) must every downstream doc carry? Stamps
   `docs/constraints.md`; copies
   `${CLAUDE_PLUGIN_ROOT}/scripts/check-constraints-drift.sh` into the
   repo's `scripts/` and adds one named CI step running it (checkout
   needs `fetch-depth: 0` — pinned-sha reads fail on shallow clones).
   Downstream docs copy the block verbatim under
   `constraints-copy: docs/constraints.md @ <sha>`; the gate fails
   drift, and stale pins are the digest's concern, not CI's. No CI
   workflow accepted or present → stamp the file, state loudly that the
   gate awaits a workflow.
```

- [ ] **Step 4: Add the handover referral seam to the Report section**

In section `## 6. Report` of the same file, replace the sentence:

```
and the repo's next natural moments: "when
something here proves itself, recursive-spine-pollinate captures it; recursive-spine-digest sweeps this repo on its cadence."
```

with:

```
and the repo's next natural moments: "when
something here proves itself, recursive-spine-pollinate captures it;
when your first unit of work closes, recursive-spine-handover assembles
the closing record; recursive-spine-digest sweeps this repo on its
cadence."
```

- [ ] **Step 5: Verify frontmatter gate still passes and commit**

Run:

```bash
for f in skills/*/SKILL.md; do head -20 "$f" | grep -q '^name:' && head -20 "$f" | grep -q '^description:' || echo "missing: $f"; done; echo FRONTMATTER-OK
scripts/check-constraints-drift.sh && echo DRIFT-GATE-OK
git add reference/templates/scaffold/constraints-frame.md skills/recursive-spine-scaffold/SKILL.md
git commit -m "feat(#33): scaffold part 5 — constraints file + drift gate"
```

Expected: `FRONTMATTER-OK`, `DRIFT-GATE-OK` (the frame is excluded by the checker's `:!reference/templates/` pathspec — if this fails, the pathspec broke).

---

### Task 4: The seventh skill — recursive-spine-handover

**Files:**
- Create: `skills/recursive-spine-handover/SKILL.md`

**Interfaces:**
- Consumes: principle 4's wording from `reference/principles.md` ("any pollen to capture?"); `docs/constraints.md` + marker contract (Tasks 1–2).
- Produces: the skill named by Task 5's referral seams and Task 6's manifests, exactly `recursive-spine-handover`.

- [ ] **Step 1: Write the skill**

Create `skills/recursive-spine-handover/SKILL.md` with exactly:

```markdown
---
name: recursive-spine-handover
description: Use when closing a unit of work — an issue is about to close, a PR is about to merge, or a session is ending with its work complete. Assembles the closing record as a comment on the issue: debts filed before the close (principle 4), the pollen question asked, state pointers captured, the down-tier offer made. Previews the comment before posting; degrades loudly when gh or the constraints file is missing.
---

# recursive-spine: handover

The closing record for a unit of work. Read
`${CLAUDE_PLUGIN_ROOT}/reference/principles.md` (principle 4) first. The
record is a **comment on the closing issue** — never a file. A
`docs/handovers/` directory would be a prose ledger, exactly what
principle 1 retires.

Spine **handover** is not tokenomics **handoff**: this skill produces a
closing *record*; tokenomics' handoff-spec is a dispatch *contract* for
down-tier execution. The two documents stay separate on purpose.

## 1. Identify the unit

The unit is the issue that is closing. Confirm it: `gh issue view <N>`.
Find its state pointers — branch (`<prefix>/<issue>-<slug>` per the
convention), PR (`gh pr list --search "<N>" --state all`), and the key
commits. If no issue exists for the work being closed, stop: file one
first (a unit without an issue was never tracked; offer
recursive-spine-bootstrap if the repo has no tracking at all).

## 2. Debts, before the close

Ask for the unit's known-incomplete edges. Every one becomes an issue
**before** the closing comment is posted — deferral/debt labels per the
repo's dialect note. A closing comment that names a debt without a filed
issue is a principle-4 violation; this skill never posts one. If the
builder says there are no debts, record how that was checked (e.g.
"reviewed the PR diff and the unit's acceptance list").

## 3. The pollen question

Ask it in principle 4's wording: **"any pollen to capture?"** If yes,
hand to recursive-spine-pollinate for capture (this skill records
nothing into hives itself). If no, the comment says so and says how it
was checked — an honest denominator, not a reflex "none".

## 4. Assemble, preview, post

Build the comment from this template:

    ## Handover — closing #<N>
    **Debts filed:** #<A> (<what>), #<B> (<what>) — or "none; checked <how>"
    **Pollen:** captured <slug> / "nothing proved itself this unit; checked <how>"
    **State:** branch <name>, PR #<M>, key commits <shas>
    **Constraints at close:** docs/constraints.md @ <sha of current HEAD touching it>
    **Down-tier next?** → tokenomics' handoff-spec owns that doc (offer; wiring per the dialect note)

Rules:
- Show the finished comment and get approval **before** posting
  (`gh issue comment <N> --body-file <tmp>`). Diff-first, always.
- The constraints line pins the sha at close so the digest can measure
  staleness later. No constraints file in the repo → omit the line,
  offer recursive-spine-scaffold's constraints part, and say so in the
  comment's place ("no constraints file; scaffold part offered").
- The down-tier line is an **offer**, present only when the dialect note
  records tokenomics wiring; otherwise omit it. Never require kin.

## Degrade paths (loud, never silent)

- No `gh` auth: print the finished comment for manual posting; do not
  pretend it was posted.
- No dialect note: use the convention's defaults (`deferred` label) and
  say so in the comment.
- Issue already closed: post the record anyway and note it arrived
  after the close — late record beats no record.

## Never

- Never post a closing comment naming an unfiled debt.
- Never write the handover to a file in the repo.
- Never skip the pollen question, or answer it with an unchecked "none".
- Never require tokenomics or plumb-line for any function.
- Never close the issue itself unless asked — the record is this
  skill's job; the close is the builder's.
```

- [ ] **Step 2: Verify frontmatter and description open with the moment**

Run:

```bash
head -20 skills/recursive-spine-handover/SKILL.md | grep -q '^name: recursive-spine-handover$' && head -20 skills/recursive-spine-handover/SKILL.md | grep -q '^description: Use when closing a unit of work' && echo SKILL-OK
```

Expected: `SKILL-OK`

- [ ] **Step 3: Commit**

```bash
git add skills/recursive-spine-handover/SKILL.md
git commit -m "feat(#33): recursive-spine-handover — the closing-moment skill"
```

---

### Task 5: Referral seams + moments-map lines

**Files:**
- Modify: `skills/recursive-spine-method/SKILL.md`
- Modify: `skills/recursive-spine-digest/SKILL.md`
- Modify: `CLAUDE.md`
- Modify: `reference/templates/scaffold/codex-frame.md`

**Interfaces:**
- Consumes: the skill name `recursive-spine-handover` (Task 4).

- [ ] **Step 1: Method skill — dialect-design question + routing line**

In `skills/recursive-spine-method/SKILL.md`, in the `## Dialect design` bulleted list, insert before the scaffold bullet ("Does the repo need the rest of its spine…"):

```markdown
- Does closing a unit need its record assembled — debts filed, the
  pollen question asked, state pointers captured? If yes →
  `recursive-spine-handover` posts the closing comment on the issue.
```

And in `## What this skill never does`, replace the sentence:

```
If something just proved itself
and should travel, name `recursive-spine-pollinate`. Suggest; never
auto-invoke.
```

with:

```
If something just proved itself
and should travel, name `recursive-spine-pollinate`. If a unit of work
is closing, name `recursive-spine-handover`. Suggest; never auto-invoke.
```

- [ ] **Step 2: Digest skill — stale-pin sweep line**

In `skills/recursive-spine-digest/SKILL.md`, in `## The sweep (per repo, via gh)`, append after the "Seedling pollen" bullet:

```markdown
- **Stale constraints pins (repos with a constraints file):** docs whose
  `constraints-copy:` provenance line pins a sha older than the current
  head of `docs/constraints.md`, where the doc belongs to a still-open
  issue — aged like deferrals. (Merged/closed docs stay green by design;
  `recursive-spine-handover` pins the constraints sha in each closing
  record, which is what makes staleness measurable.) Omit for repos
  without the connective-tissue part.
```

- [ ] **Step 3: Moments-map lines — CLAUDE.md and codex frame**

In `CLAUDE.md` (repo root), under `## Moments map`, replace:

```
- closing a unit of work → file debts + ask the pollen question (principle 4)
```

with:

```
- closing a unit of work → recursive-spine-handover (files debts, asks the pollen question, posts the closing record)
```

In `reference/templates/scaffold/codex-frame.md`, in the `## Moments map` seed comment, replace the same line:

```
     - closing a unit of work → file debts + ask the pollen question (principle 4)
```

with:

```
     - closing a unit of work → recursive-spine-handover (files debts, asks the pollen question, posts the closing record)
```

- [ ] **Step 4: Verify and commit**

Run:

```bash
grep -c 'recursive-spine-handover' skills/recursive-spine-method/SKILL.md skills/recursive-spine-digest/SKILL.md CLAUDE.md reference/templates/scaffold/codex-frame.md
scripts/check-constraints-drift.sh && echo DRIFT-GATE-OK
git add skills/recursive-spine-method/SKILL.md skills/recursive-spine-digest/SKILL.md CLAUDE.md reference/templates/scaffold/codex-frame.md
git commit -m "feat(#33): handover referral seams + moments-map lines"
```

Expected: each of the four files reports count ≥ 1; `DRIFT-GATE-OK`.

---

### Task 6: Packaging v0.6.0

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: plugin.json**

Set `"version": "0.6.0"`. Replace the `"description"` value with:

```
GitHub issues+milestones tracking convention and project spine: recursive-spine-method, recursive-spine-bootstrap, recursive-spine-migrate, recursive-spine-digest, recursive-spine-pollinate, recursive-spine-scaffold, recursive-spine-handover. State lives where it's queryable, not where it merges — what proves itself travels, the spine stamps the rest, and every unit closes with its record.
```

Append to `"keywords"`: `"handover"`, `"constraints"` (after `"adr"`).

- [ ] **Step 2: marketplace.json**

Replace the plugin entry's `"description"` value with:

```
GitHub issues+milestones tracking convention and project spine — seven skills (recursive-spine-method, recursive-spine-bootstrap, recursive-spine-migrate, recursive-spine-digest, recursive-spine-pollinate, recursive-spine-scaffold, recursive-spine-handover). State lives where it's queryable, not where it merges. Get oriented: run recursive-spine-method first.
```

- [ ] **Step 3: Validate both manifests and commit**

Run:

```bash
jq -e '.name == "recursive-spine" and .version == "0.6.0" and (.description | length > 0) and (.keywords | index("handover"))' .claude-plugin/plugin.json
jq -e '.plugins[0].description | contains("seven skills")' .claude-plugin/marketplace.json
ls skills/ | wc -l
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore(#33): package v0.6.0 — seven skills"
```

Expected: both jq calls output truthy; `ls skills/ | wc -l` prints `7`.

---

### Task 7: README full-pass refresh

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: seven-skill packaging (Task 6), vertebra-3 components (Tasks 1–4).

- [ ] **Step 1: Verify the live record before writing**

Run and note results (the text in Step 2 assumes these hold — adjust the ops-loose-ends sentence to match reality if any state changed):

```bash
gh issue view 35 --repo slopstopper/recursive-spine --json state --jq .state
gh issue view 21 --repo slopstopper/recursive-spine --json state --jq .state
gh issue view 10 --repo slopstopper/recursive-spine --json state --jq .state
gh issue view 40 --repo slopstopper/recursive-spine --json state --jq .state
```

Expected at plan time: all `OPEN`. If #40 is closed, say the private hive exists instead of listing it as pending.

- [ ] **Step 2: Rewrite README.md**

Replace the full contents of `README.md` with (keeping the shape identity → status → recursion → principles → install → tracking → kin; the Install and Kin sections change only where noted):

````markdown
# recursive-spine

A portable project spine, recursively self-applied.

The name is literal. **Spine:** the plugin grows a backbone for a project,
vertebra by vertebra — tracking, scaffold, connective tissue, pollination.
**Recursive:** every vertebra is built under the convention it enforces,
and since pollination shipped, the system feeds what its own use proves
back into itself — self-applied became self-improving.

**Status, with an honest denominator: four of four vertebrae shipped.**

- **Vertebra 1 — tracking:** work state lives in GitHub issues and
  milestones — queryable, conflict-free — never in prose ledgers that
  merge as text and lose rows. The five principles
  (reference/principles.md) and the method, bootstrap, migrate, and
  digest skills. A practice report, not a benchmark.
- **Vertebra 2 — scaffold:** stamps the rest of a repo's spine from
  frames + the builder's interview + proven pollen — rules codex with a
  moments map, ADR directory, CI gate skeleton, session-memory
  convention, constraints file.
- **Vertebra 3 — connective tissue:** `docs/constraints.md` as the one
  canonical source of global constraints, a sha-pinned drift gate in CI
  (hand-copies were a measured drift vector), and the closing record
  posted on each issue when a unit of work ends.
- **Vertebra 4 — pollination:** captures elements that proved themselves
  in one project and pulls them into others — the `pollen/` registry and
  the graduation ladder (seedling → transplanted → graduated).

Build order was deliberately non-sequential (4 → 2 → 3: pollination
first, so it could capture learnings from building the other two). The
numbering is the spine's anatomy, not its history.

Seven skills, each surfacing at its moment:

- Learning the convention → `recursive-spine-method`
- Stamping tracking onto a repo → `recursive-spine-bootstrap`
- Converting an existing prose ledger → `recursive-spine-migrate`
- Growing the rest of the spine → `recursive-spine-scaffold`
- Closing a unit of work → `recursive-spine-handover`
- Something just proved itself → `recursive-spine-pollinate`
- "Where does work stand?" → `recursive-spine-digest`

The remaining work is tracked in this repo's own issues — that's the
point. Operational loose ends live in the open too: the Spine board's
auto-add is UI-only and pending (#35), the scheduled digest is deferred
(#21), the public visibility flip is pending (#10), and the private-hive
migration is in flight (#40).

## The recursion

This repo's issues and milestones existed before its first commit. Its
labels were stamped by its own bootstrap skill. Its codex and ADR
directory were stamped by its own scaffold skill. Its deferrals age on
its own digest, and its constraints drift-gate runs on its own docs. If
the convention ever feels too heavy here, that is a bug in the
convention — filed as an issue, of course.

## The five principles

See [reference/principles.md](reference/principles.md). In one line each:
state lives where it's queryable; issues are units, milestones are
narratives; deferral requires a record; handover files its debts before it
closes; branches and PRs cite the record.

## Install

**As a Claude Code plugin (recommended).** The repository is its own
plugin marketplace. From inside Claude Code:

```
/plugin marketplace add slopstopper/recursive-spine
/plugin install recursive-spine@recursive-spine
```

The first command registers the repo as a marketplace; the second installs
the seven skills. Updates come through `/plugin`. Start with the
`recursive-spine-method` skill; run `recursive-spine-bootstrap` when you're
ready to stamp a repo.

**Manually.** Clone the repository and point Claude Code at the plugin
directory (`skills/` + `.claude-plugin/plugin.json`), or add it under
`plugins` in your `.claude/settings.json`.

## Tracking (recursive-spine convention)

Work state lives in GitHub issues and milestones, not in prose files.
- What's in flight: `gh issue list --assignee @me`
- Deferred work: `gh issue list --label deferred`
- Branches: `<prefix>/<issue>-<slug>`; PRs say `Closes #N`.
- Deferral requires a filed issue. Handover files its debts before closing.
Dialect and modules for this repo: [docs/tracking-dialect.md](docs/tracking-dialect.md)

## Kin

- [plumb-line](https://github.com/slopstopper/plumb-line) — whether claims
  are honest (provenance, epistemic enforcement).
- [tokenomics](https://github.com/slopstopper/tokenomics) — which model does
  the work (session economics, lanes).
- recursive-spine — where tracked state lives.

MIT.
````

Note: "four of four vertebrae shipped" is truthful **within this branch** — the branch ships vertebra 3; the claim goes live only when the branch merges. This is the same branch-scoped truth rule used when #52 flipped vertebra 2.

- [ ] **Step 3: Run the maturity gate and drift gate**

Run:

```bash
! grep -inE 'battle-tested|production-ready' README.md && echo MATURITY-OK
scripts/check-constraints-drift.sh && echo DRIFT-GATE-OK
grep -c 'recursive-spine-' README.md
```

Expected: `MATURITY-OK`, `DRIFT-GATE-OK`, count ≥ 8.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(#33): README full-pass — four vertebrae, seven skills, refreshed shape"
```

---

### Task 8: Recursion test recording + handover comment draft

**Files:**
- Modify: `docs/tracking-dialect.md`
- Create: `.superpowers/sdd/handover-33-draft.md` (git-ignored scratch — NOT committed)

**Interfaces:**
- Consumes: everything shipped in Tasks 1–7; the handover template from `skills/recursive-spine-handover/SKILL.md`.

- [ ] **Step 1: Record the installation in the dialect note**

Append to `docs/tracking-dialect.md` (after the `## scaffold (this installation)` section):

```markdown
## connective tissue (this installation)

Recorded per the connective-tissue vertebra (#33), run against this repo
(recursion: the module's first target is the repo that ships it).

- **Constraints file:** accepted — `docs/constraints.md`, every line
  from the record (principles, dialect note, CI gates, surfacing
  pollen); nothing invented.
- **Drift gate:** wired — `scripts/check-constraints-drift.sh` runs in
  `.github/workflows/validate.yml` (checkout at `fetch-depth: 0`).
  Sha-pinned: merged docs stay green when the canonical file evolves;
  stale pins in open-issue docs are the digest's concern.
- **Handover:** `recursive-spine-handover` ships with this vertebra; its
  first live record is #33's own closing comment, posted when the
  vertebra's PR merges — the module's first act is recording its own
  completion.
- **Kin seam (settled at design time):** split ownership. Spine
  handover = closing record; tokenomics handoff = dispatch contract.
  The handover template offers the handoff-spec pointer as data (see
  "Kin offers, as answered" above); no dependency.
```

- [ ] **Step 2: Draft #33's own handover comment**

Create `.superpowers/sdd/handover-33-draft.md` (scratch; posted to #33 by the session after the PR merges — fill the `<PR>`/`<sha>` slots from `git log` at draft time and note they must be re-checked at post time):

```markdown
## Handover — closing #33
**Debts filed:** none; checked the spec's acceptance criteria (all seven implemented on the branch) and the out-of-scope list (each item already has its own issue: #38 push distribution; flip residue with #10/#40)
**Pollen:** nothing new captured this unit; checked — the surfacing and truth-gate patterns this vertebra applies were already captured as #49/#50, and this build is a transplant surface for them, not a new proof
**State:** branch feat/33-connective-tissue, PR #<PR>, key commits <first sha>..<last sha>
**Constraints at close:** docs/constraints.md @ <sha of the Task 2 commit>
**Down-tier next?** → tokenomics' handoff-spec owns that doc (offer; wiring per the dialect note — accepted 2026-07-11)
```

- [ ] **Step 3: Run the full local gate suite**

Run:

```bash
jq -e '.version == "0.6.0"' .claude-plugin/plugin.json
for f in skills/*/SKILL.md; do head -20 "$f" | grep -q '^name:' && head -20 "$f" | grep -q '^description:' || echo "missing: $f"; done; echo FRONTMATTER-OK
! grep -inE 'battle-tested|production-ready' README.md && echo MATURITY-OK
scripts/check-constraints-drift.sh && echo DRIFT-GATE-OK
scripts/test-check-constraints-drift.sh
```

Expected: `true`, `FRONTMATTER-OK`, `MATURITY-OK`, `DRIFT-GATE-OK`, `all 5 tests passed`.

- [ ] **Step 4: Commit**

```bash
git add docs/tracking-dialect.md
git commit -m "docs(#33): record connective-tissue installation — recursion test"
```

(The draft in `.superpowers/sdd/` is scratch and is not committed.)
