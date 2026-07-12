# recursive-spine-nudge — golden scenarios

Hand-run: dispatch a fresh subagent with SKILL.md plus one scenario's
fixture as its only context; check its output against the expectation.
CI wiring is #68's job, not this version's.

Fixture conventions: `sweep:` blocks use the digest's finding shapes;
`ledger:` blocks use the ledger entry format from nudges/ledger.md.

## S1 — re-nudge suppression
sweep: deferral recursive-spine#66 open, 30d old, no events since 2026-07-01.
ledger: `2026-07-05 | recursive-spine#66 | aging-deferral | outcome: no-response`
Expect: #66 NOT selected (nudged before, no state change since).

## S2 — declined stays declined
sweep: deferral recursive-spine#75 open, 20d old, no events since decline.
ledger: `2026-07-05 | recursive-spine#75 | aging-deferral | outcome: declined`
Expect: #75 NOT selected.

## S3 — state-change resurrection
sweep: deferral recursive-spine#66 open, commented 2026-07-10.
ledger: `2026-07-05 | recursive-spine#66 | aging-deferral | outcome: no-response`
Expect: #66 IS eligible again (issue activity after the nudge).

## S4 — max-3 cut and trigger ranking
sweep: 1 unblocked-and-next item, 2 aging deferrals, 2 stalled milestones,
1 pollen pair; empty ledger.
Expect: exactly 3 nudges, in order: the unblocked item, then the two
deferrals (older first). Stalled milestones and pollen cut. The cut is
noted in the delivery ("3 of 6 candidates").

## S5 — empty-week honesty
sweep: nothing aged past threshold, nothing unblocked, no pollen pairs.
Expect: delivery says exactly that no nudges qualify this week, with the
heartbeat visible (run happened, swept N/N). No padding.

## S6 — failed-repo footer
sweep: 3 of 4 repos swept; Veska_Index_App failed (auth).
Expect: DM footer contains "swept 3/4" and names the failed repo and
reason. Nudges from swept repos still go out.

## S7 — shape gate
candidate: "milestone M is stalled" with no possible question attached.
Expect: any candidate that cannot be phrased ending in a question to the
owner is dropped, whatever its rank.

## S8 — attention ping accompanies the channel send
sweep: 3 unblocked-and-next items (predecessors closed this week); ledger: empty.
Expect: delivery includes both the channel message AND a one-line
attention ping (count + top nudge headline; under 200 chars, no
markdown).
Empty-week variant: sweep: nothing qualifies; ledger: empty.
Expect: NO ping; the heartbeat stays visible in the thread and ledger only.
