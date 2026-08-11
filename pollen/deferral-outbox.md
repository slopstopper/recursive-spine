---
id: pollen-deferral-outbox
form: pattern
source: slopstopper/plumb-line#203
captured: 2026-08-11
stage: seedling
transplants: []
---

# Deferrals need an outbox, not just an inbox

A deferral discipline that only *files* findings accumulates them. Add the
draining half:

> At each release-scoping moment, every open deferral older than **30 days** is
> either **scheduled into the next release** or **closed with a written
> waiver**. No third option.

## What worked

plumb-line's capture discipline was genuinely good. Its convention — every
finding an audit or review declines to fix in place becomes a GitHub issue
labelled `audit-deferral`, back-linked from wherever it was tabled — worked
exactly as designed. A sweep found **zero unfiled debts**: every deferral
recorded in the dogfood log across five audit cycles had a live issue.

And nothing ever left. Ten deferrals sat at **22–40 days**, none assigned, none
touched since filing — in fact *every* open issue in the repo had
`updatedAt == createdAt`. The inbox was immaculate and the outbox did not exist,
because no step in the process ever asked *"which deferrals ship next?"*

Adopting the rule in [plumb-line#203](https://github.com/slopstopper/plumb-line/pull/203)
put seven of them into the very next release (v0.8.0), which then became the
debt-clearing release rather than a feature release. Two of those seven turned
out to be masking live defects — a documentation claim that was factually wrong,
and a bootstrap-installable config that had never loaded for any user.

## Why it worked

The failure mode is not laziness; it is a **missing prompt**. Filing has an
obvious trigger (you just found something). Draining has none, so it never
happens unless a moment is defined for it.

The threshold shape matters as much as the number. "Schedule **or waive**" is
deliberately not "fix everything" — demanding zero deferrals produces either
heroics or quiet non-compliance. This is the **ratchet** shape borrowed from
type-coverage tooling and from plumb-line's own provenance ratchet: *don't
demand zero, refuse regression.* An aging deferral must move, but "we are not
doing this, and here is why" is a legitimate way for it to move.

Writing the waiver is what makes it honest. A silently closed deferral and a
silently aging one leave the same evidence: none.

## How to transplant it

1. Pick the **moment**. It must be one that already happens — release scoping,
   sprint boundary, digest sweep. A rule tied to a moment nobody reaches is the
   original problem in a new place.
2. Pick the **age**. 30 days suited plumb-line's roughly-monthly release cadence;
   the useful property is that it is shorter than the interval at which you stop
   recognising the finding, not any particular number.
3. Enforce the **binary**: scheduled (given a release milestone) or closed with
   a written rationale. Deliberately no "keep deferring" state — that state is
   what the rule exists to eliminate.
4. Record it where the deferral convention already lives, so filing and draining
   are described in the same place.

## What it does not fix

This drains a backlog; it does not tell you whether the findings were right. A
deferral that ages 40 days and is then waived unread is still unread. Pair it
with something that re-reads the finding at scheduling time — the two plumb-line
deferrals that turned out to be masking live defects were only caught because
someone reopened them properly rather than rubber-stamping.
