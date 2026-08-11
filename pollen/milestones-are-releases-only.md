---
id: pollen-milestones-are-releases-only
form: pattern
source: slopstopper/plumb-line#203
captured: 2026-08-11
stage: seedling
transplants: []
---

# Milestones are releases only; tracks are labels

A GitHub milestone means **"these ship together, at a version."** Anything
without a version does not belong in the milestone namespace. Parallel,
open-ended workstreams become **labels** (`track:*`) instead.

Every open issue then carries **exactly one** of:

- a **release milestone** — scheduled, and
- a **`track:*` label** — deliberately unscheduled.

There is no third state. An issue with neither is a tracking bug, not a backlog
item.

## What worked

plumb-line had four "parallel tracks" modelled as milestones — *Portable beyond
Claude*, *Provenance across boundaries*, *Agent epistemic state*, *Ecosystem
docking* — each explicitly documented as having **no version and no due date**.

The consequence is structural, not sloppiness: a milestone that can never ship
is **stalled by construction**. A tracking sweep reported all six open
milestones as stalled (37–40 days silent), four of which were *designed* never
to complete. A signal that always fires is a signal you stop reading — so the
two genuinely stalled release milestones were camouflaged by the four that
could not be anything else.

Two smaller findings from the same sweep:

- **Thirteen open issues had no milestone at all**, including ten deferrals
  aged 22–40 days. They were not neglected on purpose; nothing in the process
  ever asked which bucket they belonged in.
- **Four shipped milestones were still open** with zero open issues (v0.5.0,
  v0.5.1, v0.6.0, v0.7.0). Shipped-but-open is hanging state that dilutes the
  same signal.

After the change ([plumb-line#203](https://github.com/slopstopper/plumb-line/pull/203)):
the milestone list contains only unshipped releases, so "stalled milestone"
became a statement that always means something, and 32/32 open issues carried
exactly one of the two markers.

## Why it worked

The rule makes *unscheduled* a *recorded decision* rather than an absence. That
is the same move as a maturity vocabulary (`current` / `planned`) applied to the
backlog itself: the useful distinction is not "done vs not done" but "we chose
not to schedule this" vs "nobody has looked."

It also fixes the signal-to-noise problem at the source rather than by tuning
thresholds. The alternative — raising the stall threshold until the permanent
milestones stop firing — would have hidden the real ones too.

## How to transplant it

1. List open milestones. For each, ask: **does this ship, at a version?** If
   no, it is a track.
2. For each track: create a `track:<name>` label, apply it to that milestone's
   issues, **remove the milestone from those issues**, then close the
   milestone with a description pointing at the replacement label. Removing
   first matters — a closed milestone left on an open issue recreates the
   confusion.
3. Close any milestone whose release has shipped.
4. Sweep for issues with neither marker and give each one. Expect this to
   surface real backlog you had stopped seeing.
5. Record the rule where contributors will meet it (plumb-line put it in
   `ROADMAP.md` under *How this backlog is organised*), because the next person
   filing an issue is the one who has to honour it.

Pairs naturally with `pollen-deferral-outbox`: the label/milestone split tells
you *what state* an issue is in, and the outbox rule is what moves deferrals
out of the unscheduled bucket on a schedule.

## Caveat

Track work loses its per-milestone page. If that visibility mattered, replace it
with a project board or a saved label filter — **not** by reinstating the
milestones, which reintroduces the permanent-stall problem this solves.
