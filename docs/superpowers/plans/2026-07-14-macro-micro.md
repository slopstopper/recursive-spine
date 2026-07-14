# Macro/Micro Issue Depth (#72) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the tracking convention macro/micro depth via GitHub native sub-issues — moment-triggered trees, roll-up/leak-by-age sweeps, queryable sequence heads — as v0.9.0.

**Architecture:** One new mechanics reference (`reference/sub-issues.md`) owns the `gh` sub-issue commands; four existing surfaces each gain a short depth section at their own moment (principles doc, handover, digest, nudge) plus a template note (work-item) and a method-skill pointer. Prose only; no sweep logic is removed.

**Tech Stack:** Markdown prose skills (Claude Code plugin), `gh` CLI (REST `sub_issues` endpoints + GraphQL `subIssues`/`parent`, both verified live on this installation).

## Global Constraints

- Depth is **moment-triggered, never speculative** — the four moments are: handover files debts; a plan lands; a sequence is recorded; a milestone item outgrows one unit. No moment, no tree.
- Migration is opportunistic: existing prose sequences convert when a sweep or handover next touches them — never a bulk backfill.
- Digest: roll up (`#249 Phase 1 — 3/6 children closed, head: #242`), healthy children folded, any child crossing an aging/stall threshold leaks as its own line.
- Nudge: sequence head = first open child in sub-issue order whose earlier siblings are all closed; prose-parsing stays as fallback; query-derived candidates outrank prose-derived.
- Degrade loudly: if sub-issue APIs are unavailable, say so and fall back to flat behavior — depth is an upgrade, never a dependency; no skill may fail because a tree couldn't be built.
- Cross-repo rule stated wherever attach is taught: sub-issues span same-owner repos only.
- Pollen depth is out of scope (deferred to #67); so are #71, #82, #46, and any automation creating depth without a moment.
- Version becomes exactly `0.9.0`.
- Avoid the digest's `## The report` section text entirely (PR #83 rewrites it; this plan's digest change is a standalone section so either PR merges first without conflict).

## File Structure

```
reference/sub-issues.md                     # NEW — the mechanics, owned once
reference/principles.md                     # depth principle after the five principles
skills/recursive-spine-method/SKILL.md      # one pointer line
skills/recursive-spine-handover/SKILL.md    # step 2 gains attachment
skills/recursive-spine-digest/SKILL.md      # new '## Depth' section (not The report)
skills/recursive-spine-nudge/SKILL.md       # Inputs item 2 + Ranking note
skills/recursive-spine-nudge/evals/scenarios.md  # S9–S11
reference/templates/work-item.md            # plan→task note
.claude-plugin/plugin.json                  # 0.8.0 → 0.9.0 (or 0.8.1 → 0.9.0 if #83 merged first)
```

---

### Task 1: The mechanics reference

**Files:**
- Create: `reference/sub-issues.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the file every later task cites as `${CLAUDE_PLUGIN_ROOT}/reference/sub-issues.md`. Section headings other tasks rely on: `## Attach`, `## Read a tree`, `## Degrade loudly`.

- [ ] **Step 1: Write the reference**

Create `reference/sub-issues.md` with exactly this content:

```markdown
# Sub-issue mechanics (macro/micro depth)

Shared by handover, digest, and nudge. Skills describe *when* depth
happens (their moments); this file owns *how*, once. Depth is
moment-triggered, never speculative — see the depth principle in
`principles.md`.

## Attach

The REST endpoint takes the child's internal ID, not its number:

    CHILD_ID=$(gh api repos/<owner>/<repo>/issues/<child-number> --jq .id)
    gh api repos/<owner>/<repo>/issues/<parent-number>/sub_issues \
      -X POST -F sub_issue_id="$CHILD_ID"

`<owner>/<repo>` in both commands is the PARENT's repo; the child may
live in a different repo **under the same owner only** — cross-owner
attachment is unsupported by GitHub. When lineage must cross owners
(the hives do), record it in prose where the moment's skill says to,
and say plainly that the tree is partial.

Detach: same endpoint with `-X DELETE`. Reorder:
`PATCH .../sub_issues/priority` with `sub_issue_id` and
`after_id`/`before_id`.

## Read a tree

One GraphQL query returns order, progress, and the head:

    gh api graphql -f query='{
      repository(owner: "<owner>", name: "<repo>") {
        issue(number: <parent-number>) {
          subIssues(first: 50) {
            totalCount
            nodes { number title state }
          }
        }
      }
    }'

- **Progress:** closed nodes / totalCount ("3/6 children closed").
- **Sequence head:** the first node in returned order with state OPEN
  whose earlier siblings are all CLOSED. Sub-issue order is the recorded
  order — GitHub preserves it.
- **Upward:** `issue(number: N) { parent { number } }` tells you a swept
  issue is a child, so sweeps can fold it under its parent.

`first: 50` is a deliberate page size; a unit with more than 50 children
is a design smell worth surfacing, not paginating past silently.

## Degrade loudly

If any command above fails (older GHES, missing permission, API change):
say so in the output of whatever you were producing ("sub-issue API
unavailable: <error>; reporting flat") and continue with today's flat
behavior. Depth is an upgrade, never a dependency — no skill may fail,
and no report may silently thin out, because a tree couldn't be read.
```

- [ ] **Step 2: Verify the commands against the live repo**

Run: `gh api repos/slopstopper/recursive-spine/issues/72 --jq .id && gh api graphql -f query='{ repository(owner:"slopstopper", name:"recursive-spine") { issue(number:72) { subIssues(first:50){totalCount} parent{number} } } }' --jq .data.repository.issue.subIssues.totalCount`
Expected: a numeric ID, then `0` — both API shapes answer.

- [ ] **Step 3: Commit**

```bash
git add reference/sub-issues.md
git commit -m "feat(depth): sub-issue mechanics reference — attach, read-a-tree, degrade loudly (#72)"
```

---

### Task 2: The depth principle

**Files:**
- Modify: `reference/principles.md` (insert between the five principles and `## Modules`)
- Modify: `skills/recursive-spine-method/SKILL.md` (one pointer)

**Interfaces:**
- Consumes: `reference/sub-issues.md` from Task 1 (cited by name).
- Produces: the heading `## Depth: macro and micro` that Tasks 3–6 cite.

- [ ] **Step 1: Insert the principle section**

In `reference/principles.md`, insert between the end of principle 5 (the line ending `not a file.`) and `## Modules`:

```markdown
## Depth: macro and micro

Issues gain depth through GitHub native sub-issues — same system, deeper
resolution. **Depth is moment-triggered, never speculative:** an issue is
macro the moment something real attaches beneath it; no moment, no tree.
Flat issues remain the norm; a tree is evidence that a moment happened,
not a planning aesthetic.

The recognized moments, each owned by the skill already standing there:

1. **Handover files debts** — debts attach as sub-issues of the closing
   unit (recursive-spine-handover). "What did closing #N leave behind?"
   is a query.
2. **A plan lands** — the plan's tasks are filed as sub-issues of the
   unit, in plan order. Unit progress is "3/6 children closed."
3. **A sequence is recorded** — umbrella issues carrying prose ordering
   become parents with ordered children; the head of the sequence is a
   query (recursive-spine-nudge reads it).
4. **A milestone item outgrows one unit** — the umbrella pattern:
   milestone stays coarse, the umbrella carries mid-grain children.
   Noticed by a human, never automatic.

Migration is opportunistic: a prose sequence converts when a sweep or
handover next touches it — never as a bulk backfill. Mechanics live in
`reference/sub-issues.md`; sub-issues span same-owner repos only, and
anything crossing owners stays prose and says so. Pollen depth is
deliberately deferred to the pollen-lifecycle work (recorded there).
```

- [ ] **Step 2: Add the method-skill pointer**

In `skills/recursive-spine-method/SKILL.md`, after the line/paragraph that introduces the five principles (locate the first mention of `principles.md`), add this sentence to that paragraph:

```markdown
Issues also carry macro/micro depth — moment-triggered sub-issue trees —
per the depth section of the same principles doc.
```

- [ ] **Step 3: Verify structure**

Run: `grep -c "^## Depth: macro and micro" reference/principles.md && grep -c "macro/micro depth" skills/recursive-spine-method/SKILL.md`
Expected: `1` and `1`.

- [ ] **Step 4: Commit**

```bash
git add reference/principles.md skills/recursive-spine-method/SKILL.md
git commit -m "feat(depth): the depth principle — moment-triggered, four moments, opportunistic migration (#72)"
```

---

### Task 3: Handover attaches debts

**Files:**
- Modify: `skills/recursive-spine-handover/SKILL.md` (section `## 2. Debts, before the close`)

**Interfaces:**
- Consumes: `reference/sub-issues.md` (`## Attach`, `## Degrade loudly`).
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Extend step 2 of the handover skill**

In `skills/recursive-spine-handover/SKILL.md`, replace exactly:

```markdown
Ask for the unit's known-incomplete edges. Every one becomes an issue
**before** the closing comment is posted — deferral/debt labels per the
repo's dialect note. A closing comment that names a debt without a filed
issue is a principle-4 violation; this skill never posts one. If the
builder says there are no debts, record how that was checked (e.g.
"reviewed the PR diff and the unit's acceptance list").
```

with exactly:

```markdown
Ask for the unit's known-incomplete edges. Every one becomes an issue
**before** the closing comment is posted — deferral/debt labels per the
repo's dialect note. A closing comment that names a debt without a filed
issue is a principle-4 violation; this skill never posts one. If the
builder says there are no debts, record how that was checked (e.g.
"reviewed the PR diff and the unit's acceptance list").

Then attach each filed debt as a **sub-issue of the closing unit** —
mechanics in `${CLAUDE_PLUGIN_ROOT}/reference/sub-issues.md` (Attach) —
so the lineage is a query, not comment archaeology. The closing comment
still lists every debt by number: the comment is the human record, the
attachment is the machine truth. A debt filed in a different owner's
repo cannot attach (same-owner rule); list it in the comment with the
marker `(cross-owner, unattached)`. If attachment fails, degrade loudly
per the reference: the close proceeds, the comment says the tree is
incomplete and why.
```

- [ ] **Step 2: Verify**

Run: `grep -c "sub-issue of the closing unit" skills/recursive-spine-handover/SKILL.md && grep -c "cross-owner, unattached" skills/recursive-spine-handover/SKILL.md`
Expected: `1`, `1`.

- [ ] **Step 3: Commit**

```bash
git add skills/recursive-spine-handover/SKILL.md
git commit -m "feat(depth): handover attaches debts as sub-issues of the closing unit (#72)"
```

---

### Task 4: Digest rolls up, leaks by age

**Files:**
- Modify: `skills/recursive-spine-digest/SKILL.md` (new section inserted between `## Spine health (repos that carry the scripts)` and `## The report` — do NOT touch `## The report`'s text; PR #83 rewrites it)

**Interfaces:**
- Consumes: `reference/sub-issues.md` (`## Read a tree`).
- Produces: the digest line format Task 5's S10 fixture quotes: `#<parent> <title> — K/N children closed, head: #<child>`.

- [ ] **Step 1: Insert the depth section**

In `skills/recursive-spine-digest/SKILL.md`, insert immediately before the `## The report` heading:

```markdown
## Depth (macro/micro parents)

When a swept issue has sub-issues (`parent`/`subIssues` — mechanics in
`${CLAUDE_PLUGIN_ROOT}/reference/sub-issues.md`, Read a tree), **roll it
up and leak by age**:

- A parent reports as one line with progress and head:
  `#249 Phase 1 — 3/6 children closed, head: #242`.
- Healthy children stay folded — they do not appear as separate lines.
- Any child that individually crosses an aging or stall threshold
  **leaks**: it surfaces as its own indented line directly under its
  parent's, so folding never hides rot.
- A child issue encountered in the sweep folds under its parent rather
  than appearing twice.
- If the tree cannot be read, degrade loudly per the reference: report
  the issues flat and say why.
```

- [ ] **Step 2: Verify placement and non-collision**

Run: `grep -n "^## " skills/recursive-spine-digest/SKILL.md && git diff --stat`
Expected: `## Depth (macro/micro parents)` listed between `## Spine health…` and `## The report`; diff touches only the digest SKILL.md, and `git diff` shows no changes inside the `## The report` section body.

- [ ] **Step 3: Commit**

```bash
git add skills/recursive-spine-digest/SKILL.md
git commit -m "feat(depth): digest rolls up parents, leaks aging children (#72)"
```

---

### Task 5: Nudge queries sequence heads

**Files:**
- Modify: `skills/recursive-spine-nudge/SKILL.md` (Inputs item 2 and `## Ranking`)
- Modify: `skills/recursive-spine-nudge/evals/scenarios.md` (append S9–S11)

**Interfaces:**
- Consumes: `reference/sub-issues.md` (`## Read a tree`); the digest parent-line format from Task 4.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Rewrite Inputs item 2**

In `skills/recursive-spine-nudge/SKILL.md`, replace exactly:

```markdown
2. **Dependency reading** (new sensing) — per repo, find items that became
   unblocked: issues whose recorded sequencing ("sequenced after…",
   "blocked by…", milestone ordering, lane position) names predecessors
   that are now all closed. Cite the predecessor state in the nudge.
```

with exactly:

```markdown
2. **Dependency reading** (new sensing) — per repo, find items that became
   unblocked, by two readings:
   - **Query (preferred):** for issues with sub-issues (mechanics in
     `${CLAUDE_PLUGIN_ROOT}/reference/sub-issues.md`, Read a tree), the
     sequence head is the first open child in sub-issue order whose
     earlier siblings are all closed. Verifiable structure.
   - **Prose (fallback):** issues whose recorded sequencing ("sequenced
     after…", "blocked by…", milestone ordering, lane position) names
     predecessors that are now all closed — for sequences not yet
     converted to sub-issues.
   Cite the predecessor state in the nudge, and say which reading
   produced the candidate.
```

- [ ] **Step 2: Add the ranking note**

In `skills/recursive-spine-nudge/SKILL.md`, replace exactly:

```markdown
1. Unblocked-and-next (concrete, actionable now)
```

with exactly:

```markdown
1. Unblocked-and-next (concrete, actionable now; within this trigger,
   query-derived heads outrank prose-derived ones — verifiable beats
   inferred)
```

- [ ] **Step 3: Append golden scenarios S9–S11**

Append to `skills/recursive-spine-nudge/evals/scenarios.md`:

```markdown
## S9 — sequence head by query
sweep: parent Veska#249 has ordered children #244 (closed), #242 (open),
#239 (open); ledger: empty.
Expect: #242 selected as unblocked-and-next, cited as query-derived
(first open child, earlier siblings closed). #239 NOT selected (its
earlier sibling #242 is open).

## S10 — query outranks prose within the trigger
sweep: query-derived head Veska#242 AND a prose-derived unblocked item
rs#57 ("sequenced behind #10", #10 closed); ledger: empty; both pass the
shape gate.
Expect: both selected (max-3 allows), #242 ranked above #57; each nudge
states which reading produced it.

## S11 — prose fallback when unconverted
sweep: no issue in the sweep has sub-issues; rs#57's prose sequencing
("sequenced behind #10", #10 closed) is present; ledger: empty.
Expect: #57 selected via the prose reading, stated as prose-derived —
the skill does not require trees to produce unblocked-and-next
candidates.
```

- [ ] **Step 4: Hand-run the new scenarios**

For S9–S11: dispatch a fresh subagent with SKILL.md + the scenario fixture, instructed to produce the delivery; check against each Expect line. Also re-walk S4 (trigger ranking) to confirm the ranking note didn't disturb it.
Expected: S9–S11 match; S4 unchanged.

- [ ] **Step 5: Commit**

```bash
git add skills/recursive-spine-nudge/SKILL.md skills/recursive-spine-nudge/evals/scenarios.md
git commit -m "feat(depth): nudge reads sequence heads by query, prose fallback, S9-S11 (#72)"
```

---

### Task 6: Template note, version, live verification

**Files:**
- Modify: `reference/templates/work-item.md`
- Modify: `.claude-plugin/plugin.json` (version only)

**Interfaces:**
- Consumes: everything prior, against live repo state.
- Produces: v0.9.0.

- [ ] **Step 1: Add the plan→task note to the work-item template**

In `reference/templates/work-item.md`, append after the `**Done means:**` line:

```markdown
**Children:** <!-- when an implementation plan lands, file its tasks as
sub-issues of this unit, in plan order — depth principle, principles.md -->
```

- [ ] **Step 2: Bump the version**

In `.claude-plugin/plugin.json`, change the `version` value to `"0.9.0"` (from `0.8.0`, or `0.8.1` if PR #83 merged first). No other manifest changes — the skill count is unchanged.

- [ ] **Step 3: Validate JSON**

Run: `python3 -m json.tool .claude-plugin/plugin.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 4: Live verification on one real umbrella**

Pick one real prose-ordered umbrella at its natural touch point (the spec names Veska #249-style structure; use whichever umbrella the current sweep actually surfaces — opportunistic, not bulk). Attach its already-filed children in recorded order per `reference/sub-issues.md`. Then hand-run: (a) the digest against that repo — expect the parent line `#N <title> — K/M children closed, head: #H` with healthy children folded; (b) the nudge dependency reading — expect the same head, cited as query-derived.
Expected: both hold; if either fails, fix the corresponding skill prose (Tasks 4–5) and re-run.

- [ ] **Step 5: Commit**

```bash
git add reference/templates/work-item.md .claude-plugin/plugin.json
git commit -m "chore: v0.9.0 — macro/micro depth: template note + version (#72)"
```
