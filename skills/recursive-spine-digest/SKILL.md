---
name: recursive-spine-digest
description: Use when sweeping all recursive-spine-conforming repos for tracking health — aging deferrals (oldest first), stalled milestones, in-flight by lane, assigned-but-untouched issues, and debts named in closing comments but never filed. Reports honest denominators; includes the recursive-spine repo itself in every sweep.
---

# recursive-spine: digest

The board is the live view; this digest is the push signal.

## Repo set

Read the board owner and number from the invoking context (or the invoking
repo's dialect note — `docs/tracking-dialect.md` or equivalent), then read
the repo list from the Spine board (`gh project item-list <N> --owner
<BOARD_OWNER>`), falling back to the repo set recorded in the dialect note
of the repo you were invoked from; the author's founding set
(recursive-spine, plumb-line, tokenomics, Veska_Index_App) is the documented
default for this installation. recursive-spine ITSELF is always in the
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

## The report

One section per repo, then a cross-repo "oldest five deferrals anywhere"
table. End with the honest denominator: repos swept / repos failed (auth,
missing label, API error) — a failed repo is a line in the report, never a
silent omission. Note that 21/14-day thresholds are defaults, not doctrine.

## Delivery

Channel is configuration, not doctrine: post as an issue comment on a
designated tracking issue, write to a file, or send to Slack — whatever the
user (or the scheduled runner's config) specifies. Never hardcode.
