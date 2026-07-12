# The collaborative loop — design (#47, full slice)

**Date:** 2026-07-12
**Scopes:** #47 (collaborative loop), #21 (digest schedule)
**Stays deferred:** #71 (hooks), #38 (push distribution), #35 (board auto-add — owner UI task)
**Lane:** flagship · **Milestone:** The whole spine

## Intent

Build the missing third organ. Memory (issues, deferrals, pollen) and
coherence (milestones, lanes, sequencing) exist; **initiative** does not —
today the system is purely reactive. This version makes it start
conversations: on a weekly heartbeat, reason over the tracked state and
push 0–3 nudges to the owner, each terminating in a question, never in
autonomous execution. Two goals, verbatim from #47: don't lose good ideas;
do things in a coherent, untangled order.

**Safety property, enforced structurally:** a nudge is
*observation → why now → question*. A candidate that cannot be phrased as a
question to a human is dropped at the data-shape level. The system proposes
conversations; the owner's attention gates every cycle.

## Architecture — one routine, two voices

A single weekly scheduled cloud agent runs:

```
digest sweep (existing skill)
  → full report posted to tracking issue  (unchanged, the durable record)
  → recursive-spine-nudge skill            (new, the brain)
  → top 0–3 nudges sent as Slack DM        (new, the push)
  → ledger appended                        (new, the memory of what was said)
```

### Components

**1. `recursive-spine-nudge` skill** (new, `skills/recursive-spine-nudge/SKILL.md`)

- **Input:** the digest sweep's findings, plus two new readings:
  - *dependency state* — which lane items became unblocked (recorded
    sequencing notes + closed predecessors), per repo;
  - *pollen↔deferral pairs* — pollen records that plausibly relate to open
    deferrals, each pair citing why.
- **Output:** ranked nudge candidates, each shaped
  *observation → why now → question*.
- Config-neutral like every spine skill: board owner, repo set, ledger
  location, delivery destination all come from the dialect note / invoking
  context. No skill names a workspace, repo list, or file path.

**2. Nudge ledger** (new, in the **private hive** repo — #40 scoping:
nudges reason over private repos, so their record is private-scope)

- One append-only file, `nudges/ledger.md`: date, nudge key
  (repo#issue + trigger), text sent, outcome
  (conversation-started / declined / no-response), last-run timestamp.
- Enforces the discipline rules (below) and makes missed runs detectable.

**3. Weekly cloud routine** (closes #21)

- Substrate: Claude Code scheduled cloud agent (`/schedule`). Session-local
  cron stays rejected (dies silently). Fallback if the spike fails: local
  launchd run with a missed-run tripwire.

**4. Owner UI tasks** (pointed at, not built): board auto-add workflows and
views (#35).

## Selection logic

**Triggers (all four, first version):**

| Rank | Trigger | Source |
|---|---|---|
| 1 | Unblocked-and-next | dependency reading (new) |
| 2 | Aging deferrals | digest sweep (exists) |
| 3 | Stalled milestones | digest sweep (exists) |
| 4 | Pollen↔deferral connections | pollen reading (new, fuzzy) |

Ranking is concrete-actionability-first; the fuzzy matcher earns rank as it
proves precision. Within a trigger, older first.

**Discipline rules (ledger-enforced):**

- Never re-send an unanswered nudge unless its underlying state changed
  (issue edited, commented, relabeled, or predecessor closed since).
- A declined nudge stays declined unless its issue changed after the
  decline.
- Max 3 nudges per delivery.
- Empty week is stated, not padded: "no nudges this week — nothing newly
  unblocked, nothing aged past threshold." Silence-with-a-heartbeat.

## Delivery

**Channel is configuration, not doctrine** (same rule as the digest). The
Slack destination (workspace + DM) lives in a config file in the private
hive beside the ledger.

**Open owner decision, recorded, non-blocking:** the currently-linked Slack
account was created for Veska; the owner may create a slopstopper-specific
workspace or refit the existing one as a one-for-all-projects workspace.
Build proceeds against the current linkage as working default; switching
later is a config edit + connector re-link, zero skill edits. Filed as its
own small issue at ship time.

## Error handling — loud, always

- **Repo sweep fails:** a line in the report *and* in the DM footer
  ("swept 3/4; X failed: auth") — honest denominators, never silent
  omission.
- **Slack send fails:** nudges post to the tracking issue with a
  `nudge-delivery-failed` marker; the heartbeat stays observable when the
  channel isn't.
- **Routine doesn't fire:** ledger's last-run timestamp makes a missed week
  detectable; the next successful run opens with "missed N scheduled runs."

## Testing

Golden-scenario checks for the nudge skill, in the spirit of #68: given a
fixture of sweep output + ledger state, it must select / suppress / rank
correctly. Scenarios at minimum: re-nudge suppression, declined-issue
respect, state-change resurrection, max-3 cut, empty-week honesty,
failed-repo footer. Run by hand this version; CI wiring is #68's job.

## Build order

1. **Spike (go/no-go):** headless environment can (a) `gh`-auth to the
   private repos, (b) send to Slack. Fallbacks already named: launchd
   substrate; issue-comment delivery.
2. Nudge skill + ledger format; run manually against real repo state.
3. One manual end-to-end run (sweep → select → DM); owner judges nudge
   quality.
4. Schedule the routine. Close #21 and #47. File the Slack-workspace
   decision and the #35 pointer as small issues.

## Out of scope

Hooks (#71 — nothing in this loop may depend on a hook having fired), push
distribution to other repos (#38), pollen-matching sophistication beyond
cited plausibility, board auto-add (#35), CI-run behavioral evals (#68).
