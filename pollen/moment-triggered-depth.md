---
id: pollen-moment-triggered-depth
form: pattern
source: slopstopper/recursive-spine#72
captured: 2026-07-15
stage: transplanted
transplants: [slopstopper/tokenomics]
---

# Moment-triggered depth

Hierarchy in a tracking system is created only at the moment something
real attaches beneath an item — never speculatively. A tree is evidence
that a moment happened, not a planning aesthetic. Flat items remain the
norm; depth is earned, and every consumer of the structure degrades
loudly to flat behavior when the structure isn't there.

## What worked

recursive-spine v0.9.0 (#72, PR
[#84](https://github.com/slopstopper/recursive-spine/pull/84)) gave
GitHub issues macro/micro depth via native sub-issues, gated by a
principle: **no moment, no tree.** Four recognized moments, each owned by
the skill already standing there — a closing unit files its debts
(children), an implementation plan lands (tasks become children, in plan
order), a prose-ordered sequence is recorded (children ordered, head
queryable), a milestone item outgrows one unit (umbrella). Migration of
existing prose structure is opportunistic — converted when next touched,
never bulk-backfilled, because a bulk conversion is speculative depth on
day one.

## Why it worked

Two failure modes bracket hierarchy features. Always-on hierarchy
(epic→story→task) taxes every item with structure most never need — the
heavyweight-PM shape. Structure-on-request drifts: prose orderings
("next: A, then B") rot unqueried. Moment-triggering threads between
them: depth appears exactly where a real workflow event produced real
children, so every tree is load-bearing by construction. On the closing
day of #72 itself, the pattern self-applied: the unit's two leftover
debts were filed and attached as its own sub-issues — "what did closing
this leave behind?" became a query returning 2, at zero added ceremony.
The sweep half proved out the same day on a private repo's umbrella
issue: five children attached in recorded order; the roll-up line
("1/5 children closed, head: #X") and the sequence-head query both
computed correctly on first read, and the queried head matched what a
prose-parsing pass had previously inferred — structure agreed with the
prose it replaced.

## How to transplant it

1. Name the moments your workflow already has where children genuinely
   appear (close-with-debts, plan-lands, sequence-recorded,
   item-outgrows). Write them down; they gate all depth creation.
2. Centralize the mechanics once (for GitHub: REST attach takes internal
   IDs; detach is the singular `/sub_issue` path; GraphQL `subIssues`
   preserves order — see `reference/sub-issues.md` in the source repo).
3. Teach each consumer to roll up (parent as one line with progress and
   head), leak by exception (a child crossing an age/stall threshold
   surfaces itself), and degrade loudly to flat when the tree can't be
   read — depth is an upgrade, never a dependency.
4. Convert existing prose structure opportunistically, at next touch.
5. Mind visibility: a private child under a public parent leaks its
   existence through the parent's child count — private-scope children
   belong under private-scope parents.

## Transplants

- **slopstopper/tokenomics** (2026-07-23, tokenomics PR
  [#14](https://github.com/slopstopper/tokenomics/pull/14)): the v0.4
  switchpoint taxonomy (Route, Dispatch, Return, Close) adapts the
  moment-gating half of this pattern from hierarchy-creation to
  rule-enforcement — the method's rules fire only at named trigger
  points, each with a required crossing artifact, and anything that can
  observe a switchpoint (builder, controller model, hook) enforces the
  rule that belongs to it. The sub-issue mechanics were not carried;
  the transplanted core is "name the moments your workflow already has
  and let them gate the mechanism." Design record:
  `docs/design/2026-07-23-switchpoints-design.md` in the receiving repo.
