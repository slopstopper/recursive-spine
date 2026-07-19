# README refresh — design (#86, #81 follow-through)

**Date:** 2026-07-19
**Scopes:** #86 (README under-describes principles.md / depth), plus the
drift the whole README accumulated across v0.8–v0.9
**Lane:** small · **Deliverable:** docs PR + GitHub About update

## Intent

The README advanced past its own prose. It frames "recursive" as
build-history trivia (*it was made under its own rules*), buries the most
interesting thing, carries too many metaphors, and makes a newcomer read
philosophy before they learn what it is. Owner direction:

1. **Recursion is a live property, for the user.** The interesting thing
   is the feedback loop the *user* is in and benefits from: the system
   tracks state, senses where work stands, nudges the user, the user
   decides and builds, the system records what closed and captures what
   proved out — and that feeds the next turn. It keeps referencing itself
   and growing from its own use, in service of the user. Not the product
   admiring its own cleverness.
2. **Short philosophy hook, then newcomer-first.** Open with a little
   philosophy — a taste, not a wall — then quickly: what it is, what it
   does for you, how to start. The fuller recursion explanation comes
   after.
3. **Plainer and shorter.** Cut density; trim duplication.
4. **Metaphor diet.** Keep `spine` (the name) and `pollination`
   (distinctive, load-bearing). Drop the pile-on — no "nervous system"
   as a named figure, no "organs," soften "vertebrae" to plain "parts."
   The collaborative loop is described in plain words, not a new metaphor.

## Structure (new order)

1. **Title + short hook** — 2–3 lines. The taste of philosophy: a project
   backbone whose state lives where it's queryable, and a system you stay
   in a loop with. Brief.
2. **What it is / what it does for you** — plain, concrete, fast. A short
   paragraph or tight bullets in the user's terms: track work as GitHub
   issues and milestones (queryable, no merge conflicts); it sweeps and
   tells you what's aging or newly unblocked; it captures what proves out
   so other projects reuse it; it scaffolds house conventions and gates
   drift.
3. **Install / how to start** — keep the existing block (accurate);
   "start with `recursive-spine-method`, then `recursive-spine-bootstrap`."
4. **The recursive loop** — the heart, rewritten as the live,
   user-facing loop (intent #1). Self-applied *became* self-improving;
   the build-history facts (its own issues predate its first commit, its
   labels stamped by its own bootstrap, etc.) appear as *evidence* of the
   property, compressed — not as the section's point.
5. **What's in it** — plain parts list (tracking incl. macro/micro depth,
   scaffold, connective tissue, pollination) + the eight skills, each at
   its moment. Trimmed; "parts," not "vertebrae."
6. **Principles** — the five one-liners **plus a depth line** (closes
   #86), retitled so it no longer implies five is all of
   `principles.md`. The genuinely useful concrete commands from the old
   duplicate "Tracking convention" block fold in here as an "in practice"
   line; the rest of that block is dropped.
7. **Kin / Licence** — unchanged.

**Dropped:** the standalone "Tracking (recursive-spine convention)" block
(it restated the principles + branch/deferral rules — a duplicate ledger).
Its useful commands survive in the principles section.

## The GitHub About description

Current: "A portable project spine for Claude Code: state lives in issues,
conventions get stamped, constraints can't drift, and proven patterns
pollinate between projects. Recursively self-applied."

New (chosen — "grows from its own use" direction, mechanics implied not
listed): "A project backbone for Claude Code that grows from its own use.
Work lives in GitHub issues, not prose; what proves itself in one project
pollinates to the next. A loop you stay in." (≤ the 350-char GitHub limit;
topics unchanged.)

Applied with `gh repo edit` after the README PR is approved.

## Constraints held

- Every claim stays true — no capability described that isn't shipped.
- The README still refuses to enumerate deferred work (that principle,
  and its one-liner, stay).
- Net length flat-to-shorter despite adding depth + the loop: the trim and
  the dropped block pay for it.
- Voice stays the repo's own — plainer, not blander.

## Out of scope

Kin/Licence rewrites; any skill or principles.md change (principles.md
already has the depth section — this only makes the README describe it);
new metaphors.

## Testing

Read-through against a checklist: (1) a newcomer reaches "what it is" within
the first screen; (2) recursion reads as a user-facing loop, not
build trivia; (3) metaphor count = spine + pollination only; (4) depth
appears (tracking part + principle line); (5) no duplicate
tracking-convention block; (6) every claim maps to shipped behavior;
(7) length ≤ current. Owner review is the real gate.
