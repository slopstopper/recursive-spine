---
name: recursive-spine-nudge
description: Use after a recursive-spine-digest sweep to select and deliver system-initiated nudges — 0–3 conversation-starters pushed to the owner about what is unblocked, aging, stalled, or newly connected. Every nudge ends in a question; the skill proposes conversations, never executes work.
---

# recursive-spine: nudge

The digest reports; the nudge starts a conversation. This skill is the
initiative organ of the collaborative loop (#47): it may only propose,
shaped so that autonomy is structurally impossible — a nudge that cannot
end in a question to a human is dropped, whatever its rank.

## Configuration (read, never assume)

From the invoking context or the private hive's `nudges/config.md`:
delivery destination (Slack DM, issue comment, or file), tracking issue,
ledger location, age thresholds. From the dialect note of the invoking
repo: board owner, repo set. Never hardcode any of these. Nudge state is
private-scope: ledger and config live in the private hive, never in a
public repo.

## Inputs

1. **The sweep** — run or receive a recursive-spine-digest sweep
   (aging deferrals, stalled milestones, in-flight by lane,
   assigned-but-untouched, honest denominators).
2. **Dependency reading** (new sensing) — per repo, find items that became
   unblocked: issues whose recorded sequencing ("sequenced after…",
   "blocked by…", milestone ordering, lane position) names predecessors
   that are now all closed. Cite the predecessor state in the nudge.
3. **Pollen reading** (new sensing) — pollen records that plausibly relate
   to an open deferral. Every pair must cite *why* (shared mechanism,
   named skill, same moment). No citation, no candidate.
4. **The ledger** — `nudges/ledger.md` in the private hive: every prior
   nudge, its trigger, and its outcome.

## Candidate shape — the safety gate

Every candidate is *observation → why now → question*:

> #68 is next in the flagship lane (obs); the watches-itself milestone
> opened and its roadmap predecessors closed this week (why now); want to
> brainstorm it this week? (question)

Drop any candidate that cannot honestly take this shape.

## Discipline rules (ledger-enforced)

- **Never re-send an unanswered nudge** unless its underlying state
  changed since (issue edited, commented, relabeled, or a predecessor
  closed after the nudge date).
- **Declined stays declined** unless the issue changed after the decline.
- **Max 3 nudges per delivery.** When candidates exceed 3, say so
  ("3 of N candidates").
- **Empty week is stated, not padded:** "no nudges this week — nothing
  newly unblocked, nothing aged past threshold." The heartbeat stays
  visible even when the content is empty.

## Ranking

1. Unblocked-and-next (concrete, actionable now)
2. Aging deferrals (oldest first)
3. Stalled milestones
4. Pollen↔deferral connections (fuzziest; earns rank as it proves precision)

Within a trigger, older first.

## Delivery

Send the selected nudges to the configured destination. Footer always
carries the honest denominator ("swept N/M; X failed: reason") when any
repo failed. If the primary channel send fails, post the nudges as a
comment on the tracking issue prefixed `nudge-delivery-failed:` — the
heartbeat must stay observable when the channel isn't.

## Ledger append (always, even on empty weeks)

Append to `nudges/ledger.md`: run timestamp, swept N/M, one line per nudge
sent (`date | repo#issue | trigger | outcome: pending`). If the previous
run's timestamp is more than one interval old, open the delivery with
"missed N scheduled runs."

## Never

- Never execute, file, close, or edit work a nudge proposes — the owner's
  reply starts that conversation elsewhere.
- Never auto-file pollen matches as issues in target repos (that is #38,
  deliberately deferred).
- Never write nudge state to a public repo.
- Never depend on a Claude Code hook having fired (#71 is an adapter,
  never the method).
