# Macro/micro issue depth — design (#72 expanded, v0.9.0)

**Date:** 2026-07-14
**Scopes:** #72 (expanded per owner comment 2026-07-13: macro/micro, not
just debt lineage)
**Lane:** mid (graduating to version headline) · **Target:** v0.9.0

## Intent

Expand the issue system into macro and micro — same system, deeper
resolution — using GitHub native sub-issues (verified live on this
installation via REST `sub_issues` and GraphQL `subIssues`/`parent`).
Owner framing: utilize the existing system, expand its depth. Four
applications ship (owner-picked): debt lineage, plan→task breakdown,
sequence structure, milestone→unit umbrellas.

## The principle — depth is moment-triggered, never speculative

Method-doc addition. An issue is macro the moment something real attaches
beneath it; no moment, no tree. Flat issues remain the norm; a tree is
evidence that a moment happened, not a planning aesthetic.

The four recognized moments, each owned by the skill already standing
there:

1. **Handover files debts** (`recursive-spine-handover`): every debt
   filed at close is attached as a sub-issue of the closing unit. The
   closing comment still lists them (the record stays human-readable);
   the attachment makes it machine-true. "What did closing #N leave
   behind?" becomes a query.
2. **A plan lands** (method doc + `reference/templates/work-item.md`):
   when an implementation plan is written for a unit, its tasks are filed
   as sub-issues of that unit, in plan order. Unit progress becomes
   "3/6 children closed."
3. **A sequence is recorded** (method doc): umbrella issues carrying
   prose ordering become parents with ordered children — sub-issue order
   is preserved by GitHub, so "the head of the sequence" is a query.
4. **A milestone item outgrows one unit** (method doc): the umbrella
   pattern — milestone stays coarse, the umbrella carries mid-grain
   children. Not automatic; it happens when someone notices the
   outgrowing.

**Migration is opportunistic:** existing prose sequences convert when a
sweep or handover next touches them — never as a bulk backfill (bulk
conversion is speculative depth, violating the principle on day one).

## Sweep behavior

**Digest — roll up, leak by age.** A parent reports as one line with
progress: `#249 Phase 1 — 3/6 children closed, head: #242`. Healthy
children stay folded. Any child that individually crosses an aging/stall
threshold leaks: it surfaces as its own line under the parent's, so
folding never hides rot. Composes with #81's briefing voice unchanged
(a parent line is already a plain sentence; #81's glance/leads wrap
around these lines).

**Nudge — sequence heads become queries.** The unblocked-and-next trigger
gains a precise definition for parents: the first open child in sub-issue
order whose earlier siblings are all closed. Prose-parsing stays as the
fallback for unconverted sequences; each candidate states which reading
produced it, and query-derived candidates outrank prose-derived ones
(verifiable beats inferred).

## Mechanics — one shared reference

New `reference/sub-issues.md` owns the gh mechanics once (approach A,
owner-picked over a ninth skill or per-skill copies):

- ID resolution: `gh api repos/O/R/issues/N --jq .id` (the REST sub-issue
  API takes internal IDs, not numbers).
- Attach: `POST /repos/O/R/issues/N/sub_issues` with `sub_issue_id`;
  detach; reorder.
- List + order + progress: GraphQL `subIssues(first: 50)` with
  `totalCount` and closed-count; `parent` for upward lookup.
- Cross-repo rule: a sub-issue may live in a different repo, even a
  different owner's, given access to both (verified live 2026-07-14);
  caveats are permissions and visibility — a private child under a
  public parent leaks its existence via the parent's sub-issue count.
- Degrade loudly: if sub-issue APIs are unavailable (older GHES,
  permissions), say so and fall back to today's prose behavior. Depth is
  an upgrade, never a dependency — no skill may fail because a tree
  couldn't be built.

## Files touched

- `reference/principles.md`: the depth principle (moment-triggered, never
  speculative) + the four moments + opportunistic-migration rule, under
  its own heading beside the five principles
- `skills/recursive-spine-method/SKILL.md`: one short pointer to the
  depth principle (the method skill teaches; principles.md is the source)
- `skills/recursive-spine-handover/SKILL.md`: debt-attachment step
- `skills/recursive-spine-digest/SKILL.md`: roll-up/leak reporting
- `skills/recursive-spine-nudge/SKILL.md`: sequence-head query + ranking
- `reference/templates/work-item.md`: plan→task note
- `reference/sub-issues.md`: new mechanics reference
- `.claude-plugin/plugin.json`: version 0.9.0

## Testing

- Nudge golden scenarios extended: sequence-head query (S9),
  leak-by-age visibility (S10), prose-fallback when unconverted (S11).
- Worked examples in digest and handover prose.
- Live verification: convert one real umbrella (Veska #249-style) at its
  next touch, hand-run digest + nudge, confirm rollup line and head
  detection.

## Recognized but deferred: pollen depth (#67)

Owner-raised at scoping: depth also fits pollen — transplant lineage
(transplants as sub-issues of the record's issue) and supersession chains
(#67's deprecation/versioning). Deferred to #67 because GitHub sub-issues
only span same-owner repos and the hive deliberately spans two owners
(slopstopper, effythealien): a native-only lineage would be silently
partial. #67 designs around that gap deliberately; recorded there
2026-07-14.

Correction 2026-07-14: the cross-owner limitation cited above was
disproven by a live probe — cross-owner attachment works given access.
The deferral stands on its remaining grounds (#67's lifecycle mechanics
are undesigned, and the visibility caveat still applies to private-proof
pollen), recorded on #67.

## Out of scope

Bulk migration of existing issues; pollen depth (#67, above); #71 hooks;
#82 portable delivery; #46; any automation that creates depth without a
moment.
