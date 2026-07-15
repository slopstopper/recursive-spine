---
name: recursive-spine-handover
description: Use when closing a unit of work — an issue is about to close, a PR is about to merge, or a session is ending with its work complete. Assembles the closing record as a comment on the issue: debts filed before the close (principle 4), the pollen question asked, state pointers captured, the down-tier offer made. Previews the comment before posting; degrades loudly when gh or the constraints file is missing.
---

# recursive-spine: handover

The closing record for a unit of work. Read
`${CLAUDE_PLUGIN_ROOT}/reference/principles.md` (principle 4) first. The
record is a **comment on the closing issue** — never a file. A
`docs/handovers/` directory would be a prose ledger, exactly what
principle 1 retires.

Spine **handover** is not tokenomics **handoff**: this skill produces a
closing *record*; tokenomics' handoff-spec is a dispatch *contract* for
down-tier execution. The two documents stay separate on purpose.

## 1. Identify the unit

The unit is the issue that is closing. Confirm it: `gh issue view <N>`.
Find its state pointers — branch (`<prefix>/<issue>-<slug>` per the
convention), PR (`gh pr list --search "<N>" --state all`), and the key
commits. If no issue exists for the work being closed, stop: file one
first (a unit without an issue was never tracked; offer
recursive-spine-bootstrap if the repo has no tracking at all).

## 2. Debts, before the close

Ask for the unit's known-incomplete edges. Every one becomes an issue
**before** the closing comment is posted — deferral/debt labels per the
repo's dialect note. A closing comment that names a debt without a filed
issue is a principle-4 violation; this skill never posts one. If the
builder says there are no debts, record how that was checked (e.g.
"reviewed the PR diff and the unit's acceptance list").

Then attach each filed debt as a **sub-issue of the closing unit** —
mechanics in `${CLAUDE_PLUGIN_ROOT}/reference/sub-issues.md` (Attach) —
so the lineage is a query, not comment archaeology. The closing comment
still lists every debt by number: the comment is the human record, the
attachment is the machine truth. A debt whose repo the actor cannot
write to, or whose visibility must not leak into the parent's public
count (private debt under a public unit), stays unattached; list it in
the comment with the marker `(unattached: <permissions|visibility>)`.
If attachment fails, degrade loudly per the reference: the close
proceeds, the comment says the tree is incomplete and why.

## 3. The pollen question

Ask it in principle 4's wording: **"any pollen to capture?"** If yes,
hand to recursive-spine-pollinate for capture (this skill records
nothing into hives itself). If no, the comment says so and says how it
was checked — an honest denominator, not a reflex "none".

## 4. Assemble, preview, post

Build the comment from this template:

    ## Handover — closing #<N>
    **Debts filed:** #<A> (<what>), #<B> (<what>) — or "none; checked <how>"
    **Pollen:** captured <slug> / "nothing proved itself this unit; checked <how>"
    **State:** branch <name>, PR #<M>, key commits <shas>
    **Constraints at close:** docs/constraints.md @ <sha of current HEAD touching it>
    **Down-tier next?** → tokenomics' handoff-spec owns that doc (offer; wiring per the dialect note)

Rules:
- Show the finished comment and get approval **before** posting
  (`gh issue comment <N> --body-file <tmp>`). Diff-first, always.
- The constraints line pins the sha at close so the digest can measure
  staleness later. No constraints file in the repo → omit the line,
  offer recursive-spine-scaffold's constraints part, and say so in the
  comment's place ("no constraints file; scaffold part offered").
- The down-tier line is an **offer**, present only when the dialect note
  records tokenomics wiring; otherwise omit it. Never require kin.

## Degrade paths (loud, never silent)

- No `gh` auth: print the finished comment for manual posting; do not
  pretend it was posted.
- No dialect note: use the convention's defaults (`deferred` label) and
  say so in the comment.
- Issue already closed: post the record anyway and note it arrived
  after the close — late record beats no record.

## Never

- Never post a closing comment naming an unfiled debt.
- Never write the handover to a file in the repo.
- Never skip the pollen question, or answer it with an unchecked "none".
- Never require tokenomics or plumb-line for any function.
- Never close the issue itself unless asked — the record is this
  skill's job; the close is the builder's.
