---
name: recursive-spine-scaffold
description: Use when a repo has (or is getting) the tracking stamp and needs the rest of its spine — interviews for and stamps up to five parts, each optional: a rules codex with a moments map, an ADR directory, a CI gate skeleton, a session-memory convention, and a constraints file with its sha-pinned drift gate. Frames + the builder's answers + proven pollen from their hives; nothing invented ships. Offers recursive-spine-bootstrap first when tracking is missing; records every answer, including declines, in the dialect note.
---

# recursive-spine: scaffold

Stamp the rest of the spine onto the current repo. Read
`${CLAUDE_PLUGIN_ROOT}/reference/principles.md` first. Content comes from
three sources only: the frames in
`${CLAUDE_PLUGIN_ROOT}/reference/templates/scaffold/` (structure), the
interview (the builder's discipline), and the builder's configured hives
(proven pollen). If a part's content would have to be invented, the part
is not stamped.

## 1. Preflight

- `gh auth status` — must be authenticated; `gh repo view --json
  nameWithOwner` — must be a GitHub repo.
- Tracking check: does the repo have a dialect note
  (`docs/tracking-dialect.md` or the repo's equivalent)? If not, **offer
  recursive-spine-bootstrap first** — tracking is the vertebra this one
  bolts onto. Builder may decline and scaffold anyway; record the decline.
- Hive check: read the dialect note's `pollinate:` section. If no hives
  are configured, offer the recursive-spine-pollinate hive interview; if
  declined, proceed pollen-less and say so loudly in the report — never
  substitute a default hive.

## 2. The five parts (interview one at a time, all optional)

Each part runs the same cycle:
**offer → interview → pollen check → stamp (diff first) → record.**

Offer each part with its one-line failure-mode pitch, then stop for the
answer before moving on:

1. **Rules codex** — "without one, every session re-derives the house
   rules, wrongly." Frame: `codex-frame.md`. Interview fills each
   section in the builder's own words; declined sections are omitted.
   The moments map is seeded with the spine's moments (listed in the
   frame) and edited to the builder's reality. If a CLAUDE.md/AGENTS.md
   already exists, show a merged proposal — never overwrite silently.
   Ask which filename the repo uses before writing.
2. **ADR directory** — "undocumented decisions get re-litigated by
   people who weren't there." Frames: `adr-frame.md`, `adr-readme.md`.
   Interview: where do docs live (offer the repo's existing convention),
   and is there a *real* recent decision to backfill as ADR-0001? An
   invented example ADR is banned; no real decision → the directory
   ships with only its README.
3. **CI gate skeleton** — "claims that nothing checks go stale
   silently." Frame: `ci-frame.yml`. Interview applies the routing test:
   *"which invariants, if silently broken, would be expensive?"* — each
   answer becomes one named gate step. Pollen offer: `truth-gate-ci`.
   If a CI workflow already exists, offer to extend it instead; "already
   present" is a valid recorded answer.
4. **Session-memory convention** — "sessions that start from zero pay
   the re-orientation tax every time." Frame:
   `memory-convention-frame.md`. Pollen offer: `layered-session-memory`.
   This stamps a convention *doc*, never tooling — harness-specific
   tooling is out of scope by design.
5. **Constraints file + drift gate** — "hand-copied constraints blocks
   rot independently; drift is a measured vector, not a hypothetical."
   Frame: `constraints-frame.md`. Interview: which exact-valued
   constraints (version floors, naming/copy rules, platform
   requirements, API contracts) must every downstream doc carry? Stamps
   `docs/constraints.md`; copies
   `${CLAUDE_PLUGIN_ROOT}/scripts/check-constraints-drift.sh` into the
   repo's `scripts/` and adds one named CI step running it (checkout
   needs `fetch-depth: 0` — pinned-sha reads fail on shallow clones).
   Downstream docs copy the block verbatim under
   `constraints-copy: docs/constraints.md @ <sha>`; the gate fails
   drift, and stale pins are the digest's concern, not CI's. No CI
   workflow accepted or present → stamp the file, state loudly that the
   gate awaits a workflow.

## 3. Pollen consumption

For each accepted part, search the configured hives' registries for
records whose `form` and content match the part (raw-fetch `pollen/` as
primary, clone as fallback — the pollinate skill's own order). Offer
matches with their provenance line. **An acceptance is a transplant**:
record it through recursive-spine-pollinate's pull-mode procedure —
comment on the pollen issue, append the target repo to the record's
`transplants:` list. This skill implements no recording path of its own.
Nothing relevant in the hives → say so and fill from the interview alone.

## 4. Kin offers (never requirements)

- plumb-line installed (a `plumb-line-bootstrap` skill exists)? Offer its
  guard wiring for the stamped gates.
- A tokenomics playbook in the repo? Offer to point the codex's CI/lane
  language at it for semantics.
Both are offers; both answers land in the dialect note.

## 5. Stamp and record

- Dry-run first: run the whole interview, show every generated file, write
  nothing until the builder approves the set.
- Idempotent: re-running proposes diffs against what exists; it never
  duplicates sections, ADR numbers, or workflow steps.
- Record every part's answer — accepted (with what filled it), declined
  (with the builder's reason, one line), or already-present — in the
  dialect note under `## scaffold`.

## 6. Report

End with: parts stamped (files written), parts declined or already
present (and why), pollen offered vs. accepted (transplants recorded),
kin offers and answers, and the repo's next natural moments: "when
something here proves itself, recursive-spine-pollinate captures it;
when your first unit of work closes, recursive-spine-handover assembles
the closing record; recursive-spine-digest sweeps this repo on its
cadence."
Honest denominator throughout — skipped means listed.

## Never

- Never invent content for a frame slot the interview left empty.
- Never overwrite an existing codex, workflow, or ADR silently.
- Never stamp a part the builder declined, or record a decline as
  anything but a decline.
- Never bypass the pollinate skill's recording procedure for transplants.
- Never require plumb-line or tokenomics for any function.
