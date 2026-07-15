# Digest Briefing Voice (#81) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the weekly digest read like a briefing — a change-aware "week at a glance" paragraph plus a one-sentence status lead per repo section — without changing the sweep, the data, or the honest denominators.

**Architecture:** One prose edit: the `## The report` section of `skills/recursive-spine-digest/SKILL.md` is expanded to specify the briefing shape, the delta rule, the status vocabulary, and the never-asks guardrail, with two worked examples. Plus a patch version bump. No new files, no sweep changes.

**Tech Stack:** Markdown prose skill (Claude Code plugin), `gh` CLI.

## Global Constraints

- The digest **never asks** — question-shaped sentences are the nudge skill's monopoly; the briefing voice is declarative by rule.
- Status vocabulary is exactly: `healthy`, `aging`, `needs eyes`, `sweep failed`.
- Delta source is exactly one read: the previous digest comment on the tracking issue; if none exists or it is unparseable, open with "no previous digest to compare" — never fake a delta.
- Tables are demoted, not removed: full data, unchanged format, honest denominators untouched.
- Version becomes exactly `0.8.1`.
- Out of scope: the nudge skill, sweep logic, thresholds, ledger, #72, #82.

## File Structure

```
skills/recursive-spine-digest/SKILL.md   # expand '## The report' section only
.claude-plugin/plugin.json               # version 0.8.0 → 0.8.1
```

---

### Task 1: The briefing-voice report section

**Files:**
- Modify: `skills/recursive-spine-digest/SKILL.md:61-66` (the `## The report` section)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the report shape Task 2's verification checks; section heading stays `## The report` (other sections reference the digest by skill name only, so no cross-references change).

- [ ] **Step 1: Replace the `## The report` section**

In `skills/recursive-spine-digest/SKILL.md`, replace exactly this text:

```markdown
## The report

One section per repo, then a cross-repo "oldest five deferrals anywhere"
table. End with the honest denominator: repos swept / repos failed (auth,
missing label, API error) — a failed repo is a line in the report, never a
silent omission. Note that 21/14-day thresholds are defaults, not doctrine.
```

with exactly this text:

```markdown
## The report — briefing voice

The report reads like a briefing a colleague wrote: plain language first,
evidence after. The data, formats, and honest denominators are unchanged —
only the framing is specified here.

**Open with "The week at a glance":** two to four declarative sentences,
in this order — deltas first (newly aging since the last digest, resolved
since, crossed a threshold), then the single most attention-worthy item
if any, then the failed-repo denominator if any repo failed. A quiet week
says so plainly ("Quiet week; nothing newly aging.").

**Delta rule:** before writing, read the previous digest comment on the
tracking issue (one read, no other state). If none exists or it cannot be
read as a digest, open with "No previous digest to compare" — never fake
a delta.

**Every repo section leads with a status** from exactly this vocabulary —
`healthy`, `aging`, `needs eyes`, `sweep failed` — in the heading, plus
one sentence saying why. A reader who reads only the leads has an
accurate picture. The full tables follow each lead as evidence, format
unchanged. Then the cross-repo "oldest five deferrals anywhere" table,
and the closing honest denominator: repos swept / repos failed (auth,
missing label, API error) — a failed repo is a line in the report, never
a silent omission. Note that 21/14-day thresholds are defaults, not
doctrine.

**The digest never asks.** Question-shaped sentences are the nudge
skill's monopoly; every briefing sentence is declarative. Informing is
not nudging.

**Worked example — delta week:**

> **The week at a glance:** #38 crossed the 7-day deferral mark this
> week, and #57 resolved since the last digest. One thing needs eyes:
> Veska_Index_App's Phase-1 milestone has been silent 21 days. Swept 4/4.
>
> ### plumb-line — healthy
> Nothing aging; v0.8.0 has fresh activity.
> *(full deferral/milestone tables follow)*
>
> ### Veska_Index_App — needs eyes
> Milestone Phase-1 stalled 21d; #242 assigned but untouched 14d.
> *(tables follow)*

**Worked example — first run:**

> **The week at a glance:** No previous digest to compare. The oldest
> deferral anywhere is rs#21 (5d); nothing has crossed a stall threshold.
> Swept 4/4.
```

- [ ] **Step 2: Verify the replacement is exact and complete**

Run: `grep -c "week at a glance" skills/recursive-spine-digest/SKILL.md && grep -c "never asks" skills/recursive-spine-digest/SKILL.md && grep -c "oldest five deferrals anywhere" skills/recursive-spine-digest/SKILL.md`
Expected: `3` (heading rule + two examples), `1`, `1` (the cross-repo table survives exactly once).

- [ ] **Step 3: Commit**

```bash
git add skills/recursive-spine-digest/SKILL.md
git commit -m "feat(digest): briefing voice — glance paragraph, status leads, delta rule, never asks (#81)"
```

---

### Task 2: Version bump and live verification

**Files:**
- Modify: `.claude-plugin/plugin.json` (version only)

**Interfaces:**
- Consumes: the report shape from Task 1.
- Produces: v0.8.1 manifests; a verified sample report.

- [ ] **Step 1: Bump the version**

In `.claude-plugin/plugin.json`, change `"version": "0.8.0"` to `"version": "0.8.1"`. No other manifest text changes (skill count and enumeration are untouched).

- [ ] **Step 2: Validate JSON**

Run: `python3 -m json.tool .claude-plugin/plugin.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Hand-run the digest with the new voice, delivery to file**

Invoke the `recursive-spine-digest` skill against the real configured repo set with delivery overridden to a file (the skill's Delivery section allows file output): write to `$CLAUDE_JOB_DIR/tmp/digest-voice-sample.md`. Do NOT post to the tracking issue — this is a shape check, not a scheduled run.

- [ ] **Step 4: Check the sample against the shape checklist**

Verify in the sample file, all six: (1) opens with "The week at a glance" of 2–4 sentences; (2) deltas or "No previous digest to compare" appear first in it; (3) every repo heading carries one of `healthy`/`aging`/`needs eyes`/`sweep failed` plus a one-sentence why; (4) full tables still present after each lead; (5) closing honest denominator present; (6) zero sentences ending in `?`.
Expected: all six hold; fix Task 1 prose and re-run if any fail.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "chore: v0.8.1 — digest briefing voice (#81)"
```
