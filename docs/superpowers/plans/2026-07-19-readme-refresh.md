# README Refresh (#86) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite README.md so recursion reads as a live loop the user is in, a newcomer learns what it is fast (after a short philosophy hook), the metaphor count drops to spine + pollination only, macro/micro depth appears, and the duplicate tracking block is gone — then update the GitHub About description.

**Architecture:** Prose rewrite expressed as ordered section replacements against the current README, keeping the Install / Kin / Licence blocks verbatim. One task rewrites the file; a second, gated task updates the public About description after the PR is approved.

**Tech Stack:** Markdown; `gh repo edit` for the About description.

## Global Constraints

- Metaphor budget: only `spine` (the name) and `pollination`/`pollen` (incl. its own seedling→transplanted→graduated ladder). No "nervous system," no "organs," no "vertebrae" — use plain "parts".
- Recursion is a live property **for the user**: the loop the user is in and benefits from; build-history facts appear only as compressed *evidence*, never as the section's point.
- Every claim maps to shipped behavior — describe nothing unshipped.
- The README still refuses to enumerate deferred work, and keeps that one-liner.
- Net length flat-to-shorter than the current README.
- The About description is a public, outward-facing change — apply it only after the owner approves the PR. Exact text is fixed in Task 2.

## File Structure

```
README.md                     # section-level rewrite (Task 1)
(GitHub repo About/description via gh repo edit — Task 2, gated)
```

The current README section order is: title+intro → `## Install` → `## The anatomy` → `## The recursion` → `## The five principles` → `## Tracking (recursive-spine convention)` → `## Kin` → `## Licence`. Task 1 replaces the intro and the four middle sections; Install, Kin, Licence stay byte-for-byte.

---

### Task 1: Rewrite README.md

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the published README; Task 2's About text echoes its subtitle line.

- [ ] **Step 1: Replace the intro (title through the line just before `## Install`)**

Replace everything from the top of the file down to — but not including — the `## Install` heading, with exactly:

```markdown
# recursive-spine

*A project backbone for Claude Code that grows from its own use.*

Most of what a project knows about itself lives in prose files that go
stale the week they're written. recursive-spine puts that state where it
stays true — in GitHub issues and milestones — then stays in a loop with
you: sensing where work stands, surfacing what's next, and keeping what
proves out. A backbone you build on that grows as you use it.

## What it is

A Claude Code plugin — eight skills that give a project a backbone and
help you keep it. In plain terms, it:

- **tracks your work as GitHub issues and milestones** — queryable, with
  none of the merge conflicts or silent row-loss a prose ledger hits;
- **tells you where things stand** — a weekly sweep reports what's aging,
  stalled, or newly unblocked, in plain language;
- **starts the conversation** — nudges you about what's ready to pick up
  next; every nudge ends in a question, never in work done behind your
  back;
- **carries what proves out to other projects** — a pattern, a CI gate, a
  convention that worked once becomes reusable instead of dying where it
  was born;
- **scaffolds house conventions and gates drift** — a rules codex, an ADR
  trail, a constraints file that CI won't let rot.
```

- [ ] **Step 2: Keep the `## Install` block unchanged**

Do not modify the `## Install` section. It stays exactly as it is in the current file.

- [ ] **Step 3: Replace the four middle sections (from `## The anatomy` through the end of `## Tracking (recursive-spine convention)`, i.e. everything between the Install block and `## Kin`)**

Replace that whole span with exactly:

```markdown
## The recursive part

The name is literal on both sides. **Spine:** the backbone a project
stands on. **Recursive:** a loop you stay in, with the system in it too.

The loop runs like this. Work lives as issues; the system sweeps them and
senses what's drifting; it nudges you about what's unblocked and next; you
decide and build; it records what closed and captures what proved out —
and that record is what the next sweep reads. Nothing runs away from you:
every cycle passes back through your judgment. The system keeps
referencing its own state and growing from its own use, in your service.

It runs this loop on itself, which is the honest test. This repo's issues
and milestones existed before its first commit; its labels were stamped by
its own bootstrap skill, its conventions by its own scaffold, its
deferrals age on its own digest, its constraints gate on its own docs.
Self-applied became self-improving — what building it proved fed back in
as the next thing built. If the convention ever feels too heavy here,
that's a bug in the convention, filed as an issue.

## What's in it

Four parts, each a working module:

- **Tracking** — work state in issues and milestones, never prose. Issues
  also carry depth: macro/micro sub-issue trees, created only at a real
  moment — a plan lands, a handover files its debts, a sequence is
  recorded — never as busywork.
- **Scaffold** — stamps the rest of a repo's spine from frames + your
  interview + proven pollen: rules codex, ADR directory, CI skeleton,
  session-memory convention, constraints file. Every part optional;
  declines recorded.
- **Connective tissue** — one canonical `docs/constraints.md`, a
  sha-pinned drift gate in CI, and the closing record posted on each issue
  when a unit of work ends.
- **Pollination** — the propagation layer: the `pollen/` registry, capture
  and pull, and a graduation ladder (seedling → transplanted → graduated)
  measured by real reuse, not ambition. Nothing invented ships — every
  record abstracts something that actually worked, and says where.

Eight skills, each surfacing at its moment:

- Learning the convention → `recursive-spine-method`
- Stamping tracking onto a repo → `recursive-spine-bootstrap`
- Converting an existing prose ledger → `recursive-spine-migrate`
- Growing the rest of the spine → `recursive-spine-scaffold`
- Closing a unit of work → `recursive-spine-handover`
- Something just proved itself → `recursive-spine-pollinate`
- "Where does work stand?" → `recursive-spine-digest`
- The system starts the conversation → `recursive-spine-nudge`

## Principles

See [reference/principles.md](reference/principles.md). In one line each:
state lives where it's queryable; issues are units, milestones are
narratives; deferral requires a record; handover files its debts before it
closes; branches and PRs cite the record. Issues also carry **depth** —
macro/micro sub-issue trees, created only at a real moment, never
speculatively.

In practice: what's in flight is `gh issue list --assignee @me`; deferred
work is `gh issue list --label deferred`; branches are
`<prefix>/<issue>-<slug>` and PRs say `Closes #N`. This file never
enumerates the deferred work itself — it would go stale the week it was
written, which is the whole point. Dialect and modules for this repo:
[docs/tracking-dialect.md](docs/tracking-dialect.md)
```

- [ ] **Step 4: Keep `## Kin` and `## Licence` unchanged**

Do not modify the `## Kin` or `## Licence` sections.

- [ ] **Step 5: Verify the rewrite against the checklist**

Run these greps and read-throughs on the new `README.md`:

```bash
# metaphor diet: these must all be 0
grep -ci "nervous system\|vertebra\|organs\b" README.md
# depth appears (tracking part + principle line): >= 2
grep -ci "depth" README.md
# duplicate block gone: the old heading must be absent
grep -c "Tracking (recursive-spine convention)" README.md
# newcomer-first: 'What it is' precedes 'The recursive part'
grep -n "^## " README.md
```

Expected: metaphor grep `0`; depth grep `2` or more; duplicate-heading grep `0`; heading order shows `## What it is` before `## The recursive part`, and `## Install` between them. Also read the file top-to-bottom once and confirm: recursion reads as a user-facing loop (not build trivia), every bullet in "What it is" maps to a shipped skill, and total length is ≤ the previous version (`git diff --stat` shows net deletions or near-neutral).

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs(readme): recursion as a live user-facing loop, newcomer-first, metaphor diet, depth (#86)"
```

---

### Task 2: Update the GitHub About description (gated on PR approval)

**Files:**
- None in-repo. Output: the public repo description via `gh repo edit`.

**Interfaces:**
- Consumes: owner approval of the README PR (this is an outward-facing change — do not run before the owner has approved the PR).

- [ ] **Step 1: Confirm the gate**

Do not proceed until the owner has approved the README PR. This changes public repo metadata.

- [ ] **Step 2: Set the description**

```bash
gh repo edit slopstopper/recursive-spine --description "A project backbone for Claude Code that grows from its own use. Your project's state lives where it stays true — GitHub issues, not prose that goes stale — and the system stays in a loop with you, sensing what's next and keeping what proves out."
```

- [ ] **Step 3: Verify**

Run: `gh repo view slopstopper/recursive-spine --json description --jq .description`
Expected: the exact string above. Topics are left unchanged.
