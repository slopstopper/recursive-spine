# Vertebra 4: Pollination Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `recursive-spine-pollinate` skill and multi-hive pollen registry so proven elements can be captured from any project and pulled into others (issue #37, spec: `docs/superpowers/specs/2026-07-10-pollination-design.md`).

**Architecture:** This is a Claude Code plugin of Markdown skills — there is no runtime code. Deliverables are: a `pollen/` registry with a front-matter schema enforced by the existing `validate.yml` CI, one new SKILL.md (capture + pull modes), edits to the principles/method/digest documents that wire pollination into the convention, manifest updates, and a live recursion test (capture real pollen, exercise pull in a sibling repo).

**Tech Stack:** Markdown skills with YAML frontmatter, `gh` CLI, GitHub Actions (bash/jq validation).

## Global Constraints

- Skill names are self-prefixed: the new skill is `recursive-spine-pollinate` (house rule from #24).
- No shipped defaults for user-specific config: hive repo(s) are interview answers recorded in the dialect note, never hardcoded (house rule from #19, #22).
- No invented demo pollen — worked examples must be structure-faithful abstractions of real use (recursion doctrine, `reference/principles.md`).
- No overstated maturity: never write "battle-tested" or "production-ready" anywhere (CI enforces for README).
- Every skill has `name:` + `description:` frontmatter; description starts "Use when …" (house style).
- Skills reference kin plugins (plumb-line, tokenomics) only through offers, never requirements (Boundaries section of principles).
- Commit messages reference #37; work happens on branch `feat/37-pollinate` cut from `docs/37-pollination-design` (so the spec is present) or from main after PR #39 merges.
- Two-hive routing rule (spec): pollen proven in a private repo files into a private hive; a public hive must be self-contained (no references to repos its readers cannot see).

---

### Task 1: Pollen registry scaffold + CI schema check

**Files:**
- Create: `pollen/README.md`
- Modify: `.github/workflows/validate.yml`

**Interfaces:**
- Produces: the registry directory contract — every pollen record is `pollen/<slug>.md` with front-matter keys `id`, `form`, `source`, `captured`, `stage`, `transplants`. Task 2's skill text and Task 7's live capture must conform to exactly these keys and the enum values defined here.

- [ ] **Step 1: Write the CI check first (this is the failing test)**

Append a new step to the end of the `validate` job's `steps:` in `.github/workflows/validate.yml`:

```yaml
      - name: Pollen records carry the required front-matter
        run: |
          shopt -s nullglob
          fail=0
          for f in pollen/*.md; do
            [ "$(basename "$f")" = "README.md" ] && continue
            for key in id form source captured stage transplants; do
              head -20 "$f" | grep -q "^${key}:" || { echo "missing ${key}: $f"; fail=1; }
            done
            head -20 "$f" | grep -qE '^form: (snippet|pattern|skill-candidate|config)$' || { echo "bad form enum: $f"; fail=1; }
            head -20 "$f" | grep -qE '^stage: (seedling|transplanted|graduated)$' || { echo "bad stage enum: $f"; fail=1; }
          done
          exit $fail
```

- [ ] **Step 2: Verify the check fails on an invalid record**

```bash
mkdir -p pollen && printf -- '---\nid: pollen-bad\n---\nbody\n' > pollen/bad-fixture.md
bash -c "$(awk '/Pollen records carry/{f=1} f && /run: \|/{f=2; next} f==2 && /^          /{sub(/^          /,""); print} f==2 && !/^          /{exit}' .github/workflows/validate.yml)"
```

Expected: prints `missing form: pollen/bad-fixture.md` (and the other missing keys) and exits non-zero. Simpler equivalent: copy the script body into a temp file and run it. Then delete the fixture:

```bash
rm pollen/bad-fixture.md
```

- [ ] **Step 3: Write `pollen/README.md` (the schema contract)**

```markdown
# The pollen registry

Captured, transplantable learnings — each proven in real use before it was
filed (invented demo pollen is banned by the recursion doctrine). Records
are written by the `recursive-spine-pollinate` skill; this directory is
the **public-scope hive** for this installation. Private-proof pollen
lives in a private hive and never appears here — every reference in this
directory must resolve for every reader.

## Record schema

One file per pollen: `pollen/<slug>.md`. Artifact files (a CI gate, a
hook, a template) live alongside in `pollen/<slug>/` and the record links
them.

    ---
    id: pollen-<slug>            # stable identifier, matches filename
    form: snippet | pattern | skill-candidate | config
    source: owner/repo#N         # repo + issue/PR where it proved itself
    captured: YYYY-MM-DD
    stage: seedling | transplanted | graduated
    transplants: []              # repos it took root in, appended over time
    ---

Body: what worked, why it worked, how to transplant it.

## Lifecycle

- **seedling** — captured, never transplanted. The digest ages these.
- **transplanted** — took root in ≥1 other project (recorded in
  `transplants:` and as a comment on the paired `pollen` issue).
- **graduated** — ≥2 transplants and promoted to a real skill, in
  whichever kin repo owns the concern (epistemic honesty → plumb-line,
  model economics → tokenomics, tracking/scaffold → here). The paired
  issue closes on graduation or retirement.

Every record is paired with a `pollen`-labeled issue in this repo — the
queryable half, per principle 1.
```

- [ ] **Step 4: Verify the check passes on the real registry**

Run the same extracted script from Step 2 against the directory (now containing only `README.md`, which the loop skips).
Expected: exit 0, no output.

- [ ] **Step 5: Commit**

```bash
git add pollen/README.md .github/workflows/validate.yml
git commit -m "feat(pollen): registry schema + CI front-matter check (#37)"
```

---

### Task 2: The `recursive-spine-pollinate` skill

**Files:**
- Create: `skills/recursive-spine-pollinate/SKILL.md`

**Interfaces:**
- Consumes: the record schema from Task 1 (`pollen/README.md`).
- Produces: the skill whose behaviors Tasks 3–6 reference by name (`recursive-spine-pollinate`, its capture/pull modes, the `pollinate:` dialect-note section it reads/writes).

- [ ] **Step 1: Write the skill file**

`skills/recursive-spine-pollinate/SKILL.md`, complete content:

```markdown
---
name: recursive-spine-pollinate
description: Use when something just proved itself in real work and should be carried to other projects — captures it as a pollen record in the builder's hive (registry file + paired issue), or, in pull mode, reads every configured hive and offers relevant transplants into the current repo, recording each transplant back onto the record. Interview-driven hive config; never ships a default hive; routes private-proof pollen to a private hive only.
---

# recursive-spine: pollinate

Two modes. **Capture** files a proven element into a hive; **pull** brings
hive pollen into the current work. Ask which the user wants if the
invocation doesn't say. Read `${CLAUDE_PLUGIN_ROOT}/pollen/README.md` for
the record schema before writing any record.

## Hive configuration (both modes, first)

Read the invoking repo's dialect note (`docs/tracking-dialect.md` or
equivalent) for a `pollinate:` section listing hive repos and each hive's
visibility. If absent, interview — never assume:

1. "Which repo is your hive (where pollen records live)?" Accept several;
   record each as `owner/repo (public|private)`.
2. If the builder works across public and private projects, recommend one
   hive per visibility scope (the two-hive model): private-proof pollen
   must never enter a hive whose readers can't see its source.
3. Write the answers to the dialect note before proceeding. No default
   hive ships with this skill — the hive is the builder's own answer.

Degraded modes, always loud: no `gh` auth or not in a repo → draft the
record locally, print it, and tell the builder exactly what to file where.
Hive unreachable → report the error and stop; never guess.

## Capture mode

1. **Interview (brief — target under a minute):**
   - What worked? (one sentence)
   - What form is it? `snippet` / `pattern` / `skill-candidate` / `config`
   - Where's the proof? (repo + issue/PR — the `source:` field; the proof
     must exist, per the no-invented-pollen doctrine)
2. **Route by proof visibility:** `gh repo view <source-repo> --json
   visibility`. Private proof → a private hive; public proof → the public
   hive. If no hive of the required visibility is configured, say so and
   offer to add one to the dialect note.
3. **Dedup check:** search the target hive's registry
   (`gh search code --repo <hive> --filename '*.md' <keywords>` or a raw
   fetch of `pollen/`) and its `pollen`-labeled issues
   (`gh issue list -R <hive> --label pollen --search <keywords>`). Near
   match → offer "record a transplant on the existing pollen" instead of
   filing a twin.
4. **File the record:** branch + PR to the hive adding
   `pollen/<slug>.md` per the schema (stage `seedling`, `transplants: []`),
   plus artifact files under `pollen/<slug>/` when the pollen is a file.
   Then file the paired issue in the hive: label `pollen`, title
   `pollen: <slug> — <one-line what-worked>`, body linking the record file
   and the proof. Public hive rule: every reference in record and issue
   must resolve for every reader — if a link would point at a repo the
   hive's readers can't see, the pollen belongs in a private hive (or the
   reference must be abstracted).
5. **Report:** record path, issue URL, stage, and anything skipped and why.

## Pull mode

1. Read `pollen/` from **every** configured hive (clone or raw fetch).
2. Match records against the current work context (the repo's language,
   the task at hand, labels in play). Offer only genuine fits with a
   one-line "why this applies here". Nothing relevant → say so and stop;
   no forced suggestions.
3. On acceptance, perform the transplant: copy and adapt the artifact, or
   apply the pattern. Show the diff before writing.
4. Record the transplant, both halves:
   - append the target repo to the record's `transplants:` list (PR to
     the hive; flip `stage:` to `transplanted` if it was `seedling`);
   - comment on the paired pollen issue: which repo, what was adapted,
     link to the receiving commit/PR.
5. If a record now has ≥2 transplants, note it is graduation-eligible and
   name the kin repo that owns the concern — but graduation is the
   builder's deliberate act, never automatic.

## Declassification (deliberate, never automatic)

To publish a private-hive pollen: re-file it into the public hive with
scrubbed provenance ("proven in a private production app" — no name, no
link), a fresh paired issue, and a note in the private record pointing to
its public sibling. Offer this only when the builder asks.

## What this skill never does

No transplants without approval, no auto-graduation, no default hive, no
private references in a public hive. Pushing "consider adopting X" issues
into target repos is deliberately out of scope: deferred as
recursive-spine#38.
```

- [ ] **Step 2: Verify frontmatter passes the CI check**

```bash
head -20 skills/recursive-spine-pollinate/SKILL.md | grep -c '^name:\|^description:'
```

Expected: `2`

- [ ] **Step 3: Commit**

```bash
git add skills/recursive-spine-pollinate
git commit -m "feat(pollinate): capture + pull skill, multi-hive, visibility-routed (#37)"
```

---

### Task 3: Principles — the pollination module + graduation ladder

**Files:**
- Modify: `reference/principles.md` (Modules section, currently ending with the Dialect-note bullet ~line 58)

**Interfaces:**
- Consumes: skill name and lifecycle terms from Tasks 1–2 (must match exactly: seedling/transplanted/graduated, `pollen` label).

- [ ] **Step 1: Add the module bullet**

In `reference/principles.md`, after the existing `- **Dialect note** …` bullet in the Modules list, insert:

```markdown
- **Pollination module** — a `pollen` label in the hive repo plus a
  `pollen/` registry: elements that proved themselves in one project,
  captured as records and pulled into others by the
  `recursive-spine-pollinate` skill. The graduation ladder: *seedling*
  (captured, never transplanted — the digest ages these) → *transplanted*
  (took root in ≥1 other project) → *graduated* (≥2 transplants, promoted
  to a real skill in whichever kin repo owns the concern). Hives are the
  builder's own answer, one per visibility scope; private-proof pollen
  never enters a hive whose readers cannot see its source. Capture points:
  in-flow on noticing, at handover (see principle 4's sibling question),
  and retrospective sweep.
```

- [ ] **Step 2: Add the handover sibling question to principle 4's text**

In the same file, extend principle 4 (currently: "**Handover files its debts before it closes.** … A closing comment that names a debt without a filed issue is a violation.") by appending one sentence to that paragraph:

```markdown
   Where the pollination module is installed, closing asks the sibling
   question too: any pollen to capture?
```

- [ ] **Step 3: Verify wording consistency**

```bash
grep -n "seedling\|transplanted\|graduated" reference/principles.md pollen/README.md skills/recursive-spine-pollinate/SKILL.md | grep -icv "seedling"
```

Simpler check: `grep -rn 'pollen to capture' reference/principles.md` → 1 hit; `grep -c 'recursive-spine-pollinate' reference/principles.md` → 1.

- [ ] **Step 4: Commit**

```bash
git add reference/principles.md
git commit -m "docs(principles): pollination module + graduation ladder + handover sibling question (#37)"
```

---

### Task 4: Wire the method and digest skills

**Files:**
- Modify: `skills/recursive-spine-method/SKILL.md`
- Modify: `skills/recursive-spine-digest/SKILL.md`

**Interfaces:**
- Consumes: module description from Task 3; lifecycle terms from Task 1.

- [ ] **Step 1: Method skill — teach the module and route to the skill**

In `skills/recursive-spine-method/SKILL.md`:

(a) In "How to teach it" item 4, change

```markdown
4. Walk the module system: deferral label mandatory, gap/debt/lane optional.
```

to

```markdown
4. Walk the module system: deferral label mandatory; gap/debt/lane/
   pollination optional.
```

(b) In "Dialect design", after the lane bullet (`- Do you route work across model tiers or people? …`), add:

```markdown
- Do elements that proved themselves in one project die there? If yes →
  pollination module (`recursive-spine-pollinate`).
```

(c) In "What this skill never does", change the last sentence routing list from

```markdown
If they have an existing prose
ledger, name `recursive-spine-migrate`. Suggest; never auto-invoke.
```

to

```markdown
If they have an existing prose
ledger, name `recursive-spine-migrate`. If something just proved itself
and should travel, name `recursive-spine-pollinate`. Suggest; never
auto-invoke.
```

- [ ] **Step 2: Digest skill — age the seedlings**

In `skills/recursive-spine-digest/SKILL.md`, in "The sweep (per repo, via gh)" list, after the **Unfiled debts** bullet, add:

```markdown
- **Seedling pollen (hive repos only):** open `pollen`-labeled issues whose
  record still says `stage: seedling`, sorted oldest-first with age in
  days — pollen that never transplanted is a signal, same as an aging
  deferral. Omit the section for repos that are not a configured hive.
```

Also extend the digest's frontmatter description: after "and debts named in closing comments but never filed", insert ", plus seedling pollen that never transplanted (hive repos)".

- [ ] **Step 3: Verify both files still pass frontmatter CI and reference consistent terms**

```bash
for f in skills/recursive-spine-method/SKILL.md skills/recursive-spine-digest/SKILL.md; do
  head -20 "$f" | grep -q '^name:' && head -20 "$f" | grep -q '^description:' && echo "ok: $f"
done
grep -l 'recursive-spine-pollinate' skills/recursive-spine-method/SKILL.md
grep -l 'stage: seedling' skills/recursive-spine-digest/SKILL.md
```

Expected: two `ok:` lines, then both filenames.

- [ ] **Step 4: Commit**

```bash
git add skills/recursive-spine-method/SKILL.md skills/recursive-spine-digest/SKILL.md
git commit -m "feat(method,digest): teach pollination module; digest ages seedling pollen (#37)"
```

---

### Task 5: Manifests + README skill count

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

- [ ] **Step 1: plugin.json — five skills, version bump**

Update `description` to:

```
GitHub issues+milestones tracking convention: recursive-spine-method, recursive-spine-bootstrap, recursive-spine-migrate, recursive-spine-digest, recursive-spine-pollinate. State lives where it's queryable, not where it merges — and what proves itself travels.
```

Bump `"version": "0.3.0"` → `"version": "0.4.0"`. Add `"pollination"` and `"cross-project"` to `keywords`.

- [ ] **Step 2: marketplace.json — same story**

Update the plugin entry's `description` to:

```
GitHub issues+milestones tracking convention — five skills (recursive-spine-method, recursive-spine-bootstrap, recursive-spine-migrate, recursive-spine-digest, recursive-spine-pollinate). State lives where it's queryable, not where it merges. Get oriented: run recursive-spine-method first.
```

- [ ] **Step 3: README — minimal truth fix only (full identity rewrite is #34, out of scope)**

- Line ~2–8 intro sentence: after "…and sweeps every conforming repo for aging deferrals and stalled work (`recursive-spine-digest`)." append: "A fifth skill, `recursive-spine-pollinate`, captures elements that proved themselves in one project and pulls them into others."
- Line ~14 "the principles (reference/principles.md) and all four skills —" → "…and all five skills —" and append `recursive-spine-pollinate` to the list that follows.
- Line ~46 "the second installs the four skills" → "the five skills".

- [ ] **Step 4: Verify manifest CI checks pass**

```bash
jq -e '.name == "recursive-spine" and (.description | length > 0)' .claude-plugin/plugin.json
jq -e '.plugins[0].description | contains("five skills")' .claude-plugin/marketplace.json
! grep -inE 'battle-tested|production-ready' README.md
grep -c 'four skills' README.md .claude-plugin/*.json | grep -v ':0' && echo LEFTOVER || echo clean
```

Expected: `true`, `true`, no grep hits, `clean`.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md
git commit -m "chore(manifest,readme): five skills, v0.4.0 (#37)"
```

---

### Task 6: Dialect note — this installation's hive config

**Files:**
- Modify: `docs/tracking-dialect.md`

**Interfaces:**
- Produces: the `pollinate:` section the skill's hive-configuration step reads for THIS repo. Section name must match what Task 2's skill text looks for ("a `pollinate:` section").

- [ ] **Step 1: Append the section**

At the end of `docs/tracking-dialect.md`, add:

```markdown
## pollinate: hives (this installation)

Recorded per the pollinate skill's interview (recursion: this repo
configures itself first).

- **Public hive:** `slopstopper/recursive-spine` (this repo, `pollen/`) —
  pollen whose proof is public (plumb-line, tokenomics, this repo).
  Must stay self-contained: no references readers can't resolve.
- **Private hive:** not yet created — tracked as
  [#40](https://github.com/slopstopper/recursive-spine/issues/40). Until
  it exists, capture of private-proof pollen degrades loudly: draft
  locally, do not file into this repo.

Routing rule: pollen inherits the visibility of its proof.
Declassification into the public hive is a deliberate, scrubbed act.
```

Note: an unmerged branch (`docs/14-board-created`) also edits this file's board section; this append touches a different section, so merge conflict risk is low — rebase normally if it lands first.

- [ ] **Step 2: Commit**

```bash
git add docs/tracking-dialect.md
git commit -m "docs(dialect): hive configuration — public hive here, private hive pending #40 (#37)"
```

---

### Task 7: Recursion test — live capture, live pull (acceptance criteria)

This task is executed against real repos, not fixtures. It is the spec's acceptance test; do not fake any part of it. Requires `gh` auth as the owner.

**Files:**
- Create: `pollen/<slug>.md` for the first real pollen (slug decided at capture)
- External: one `pollen`-labeled issue in this repo; one transplant in a sibling repo (plumb-line or tokenomics).

- [ ] **Step 1: Capture the first pollen by following the new skill's capture mode literally**

The pollen must come from building pollination itself or an already-proven element. A genuine candidate with public proof, usable if the builder confirms it: the **dialect-note-as-config pattern** — "skills stay owner/config-neutral text; installation data (board owner, repo set, hives) lives in the repo's dialect note" — proven across #19 (parameterized board owner/repo set) and this build (hive config). `form: pattern`, `source: slopstopper/recursive-spine#19`, `stage: seedling`. Walk the skill's capture steps: interview answers → visibility routing (public proof → this hive) → dedup search → record file on a branch → paired `pollen` issue. If executing as part of this plan's branch, commit the record here instead of a separate PR.

- [ ] **Step 2: Verify the record passes the CI schema check**

Run the validation script from Task 1 Step 2 against `pollen/`.
Expected: exit 0.

- [ ] **Step 3: Exercise pull mode against a sibling repo**

In a clone/worktree of `slopstopper/plumb-line` (or tokenomics), invoke the skill's pull mode. It reads this hive, offers the captured pollen if genuinely relevant, and on the builder's acceptance performs the transplant and records it: `transplants:` gains the target repo, `stage:` flips to `transplanted`, and the paired issue gets the transplant comment linking the receiving commit. **If the offer is genuinely not relevant, do not force it** — report honestly, leave the pollen `seedling`, and note in the PR that the pull-exercise acceptance criterion is deferred to the first genuine transplant (file that deferral as an issue per principle 3).

- [ ] **Step 4: Run the full local CI suite one last time**

```bash
jq -e '.name == "recursive-spine"' .claude-plugin/plugin.json
for f in skills/*/SKILL.md; do head -20 "$f" | grep -q '^name:' && head -20 "$f" | grep -q '^description:' || echo "FAIL $f"; done
! grep -inE 'battle-tested|production-ready' README.md
```

Expected: `true` / no FAIL lines / no hits.

- [ ] **Step 5: Commit, push, PR**

```bash
git add pollen/
git commit -m "feat(pollen): first real pollen — captured from building pollination (recursion test) (#37)"
git push -u origin feat/37-pollinate
gh pr create --draft --title "feat: vertebra 4 — pollination (#37)" --body "Closes #37. Implements docs/superpowers/specs/2026-07-10-pollination-design.md."
```

---

## Out of scope (tracked, not forgotten)

- Push distribution — #38 (deferred at design time).
- Private hive creation + personal-state migration — #40.
- README/principles identity rewrite — #34 (do after this merges).
- Scaffold/connective-tissue seams — built with #32/#33.
