# Digest briefing voice — design (#81, v0.8.1)

**Date:** 2026-07-13
**Scopes:** #81 (digest voice)
**Lane:** small · **Target:** v0.8.1

## Intent

Owner feedback after the first live collaborative-loop runs: the digest is
correct but not *felt* — tables and counts make it hard to see what is
actionable. Fix the voice, not the data: the report should read like a
briefing a colleague wrote, while keeping honest denominators and the full
evidence. Constraint named by the owner: more understandable **without
over-nudging**.

## Design — one skill section, no new components

`skills/recursive-spine-digest/SKILL.md` gains a **"Briefing voice"**
section specifying the report shape. Nothing else in the skill changes;
the sweep itself is untouched.

**1. "The week at a glance" opens the report.** Two to four plain
sentences, in this order: deltas first (*newly aging since the last
digest / resolved since / crossed a threshold*), then the single most
attention-worthy item if any, then the honest denominator if any repo
failed. A quiet week says so plainly ("Quiet week; nothing newly aging").

**2. Every repo section leads with a status.** Fixed vocabulary —
`healthy`, `aging`, `needs eyes`, `sweep failed` — plus one sentence
saying why. The status words are the section's scan layer; a reader who
reads only the four leads has an accurate picture.

**3. Tables demoted, not removed.** The full data follows each lead as
evidence, format unchanged, denominators untouched.

**Delta rule (change-aware, owner-chosen):** before writing, read the
previous digest comment on the tracking issue. If none exists or it is
unparseable, open with "no previous digest to compare" — never fake a
delta. The previous comment is the only state read; no new files.

**Guardrail — informing is not nudging:** the digest never asks. Question-
shaped sentences are the nudge skill's monopoly; the briefing voice is
declarative by rule. This is the structural answer to "understandable
without over-nudging."

## Testing

Two worked example blocks inside the new SKILL.md section (the digest has
no evals directory; examples in the prose are how this skill teaches
shape): a delta week (shows glance paragraph + one `needs eyes` lead) and
a first-run week (shows the no-previous-digest opening). Verified by
hand-running the digest against real repo state once before ship.

## Out of scope

Nudge skill (unchanged), macro/micro sub-issues (#72), portable delivery
(#82), any change to sweep logic, thresholds, or ledger.

## Amendments

- 2026-07-17: v0.9.0 (macro/micro depth, #84) merged before this spec's
  implementation, so it shipped as **v0.9.1**, not the v0.8.1 named
  above. The report section also gained one sentence composing with the
  Depth section (children roll up, never duplicated in raw lists) per
  the coordination note on PR #83.
