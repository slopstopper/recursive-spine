---
name: recursive-spine-digest
description: Use when sweeping all recursive-spine-conforming repos for tracking health — aging deferrals (oldest first), stalled milestones, in-flight by lane, assigned-but-untouched issues, and debts named in closing comments but never filed, plus seedling pollen that never transplanted (hive repos). Reports honest denominators; includes the recursive-spine repo itself in every sweep.
---

# recursive-spine: digest

The board is the live view; this digest is the push signal.

## Repo set

Read the board owner and number from the invoking context (or the invoking
repo's dialect note — `docs/tracking-dialect.md` or equivalent), then read
the repo list from the Spine board (`gh project item-list <N> --owner
<BOARD_OWNER>`), falling back to the repo set recorded in the dialect note
of the repo you were invoked from; the author's founding set
(recursive-spine, plumb-line, tokenomics) is the documented default for
this installation, with private repos read from the private hive's
dialect note rather than named here. recursive-spine ITSELF is always in the
sweep — a digest that exempts its own repo is lying about its coverage.

## The sweep (per repo, via gh)

- **Aging deferrals:** open issues with the repo's deferral label
  (`deferred` or its alias — read the repo's dialect note / tracking
  section), sorted oldest-first, each with age in days.
- **Stalled milestones:** open milestones with open issues and no issue
  activity in 21+ days.
- **In-flight by lane:** open assigned issues grouped by `lane:*` label
  (omit section if the repo has no lane module).
- **Assigned-but-untouched:** assigned open issues with no events in 14+ days.
- **Unfiled debts (best effort):** recently closed issues whose closing
  comment contains "debt", "deferred", "follow-up", or "left behind" with no
  issue reference (#N) in the same comment. Flag for human eyes; do not
  auto-file.
- **Seedling pollen (hive repos only):** open `pollen`-labeled issues whose
  record still says `stage: seedling`, sorted oldest-first with age in
  days — pollen that never transplanted is a signal, same as an aging
  deferral. Omit the section for repos that are not a configured hive.
- **Stale constraints pins (repos with a constraints file):** docs whose
  `constraints-copy:` provenance line pins a sha older than the current
  head of `docs/constraints.md`, where the doc belongs to a still-open
  issue — aged like deferrals. (Merged/closed docs stay green by design;
  `recursive-spine-handover` pins the constraints sha in each closing
  record, which is what makes staleness measurable.) Omit for repos
  without the connective-tissue part.

## Spine health (repos that carry the scripts)

If the swept repo has `scripts/spine-audit.sh` (convention adherence:
closed units without handover records, merged PRs citing no issue,
branches off the naming convention) and/or `scripts/spine-doctor.sh`
(installation integrity: labels vs the dialect note's record, board
membership staleness, stamped parts still present and wired), run them
from the repo root and fold their WARN/NOTE lines into that repo's
section. Both are report-only and always exit 0 — findings are digest
material, never CI failures. If the scripts are absent, say so:
"installation predates the health scripts" is a line in the report, not
a silent skip.

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

## The report

One section per repo, then a cross-repo "oldest five deferrals anywhere"
table. End with the honest denominator: repos swept / repos failed (auth,
missing label, API error) — a failed repo is a line in the report, never a
silent omission. Note that 21/14-day thresholds are defaults, not doctrine.

## Delivery

Channel is configuration, not doctrine: post as an issue comment on a
designated tracking issue, write to a file, or send to Slack — whatever the
user (or the scheduled runner's config) specifies. Never hardcode.
