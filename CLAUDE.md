# recursive-spine — rules codex

Stamped by recursive-spine-scaffold (recursion test, #32). Every rule
below was already on this repo's record; nothing here is new.

## Mission

A portable project spine, recursively self-applied — vertebra by
vertebra (tracking, scaffold, connective tissue, pollination), every
vertebra built under the convention it enforces.

## House rules

- State lives where it is queryable (issues + milestones), never in
  prose ledgers (`reference/principles.md`, principle 1).
- Honest denominators: report what was skipped and why; never overstate
  maturity (README status style; the CI maturity gate).
- Interview-driven, never shipped defaults: lanes, hives, and scaffold
  parts are the builder's answers, recorded in the dialect note
  (house rule from #19/#22).
- Offers, never requirements: kin wiring (plumb-line, tokenomics) lives
  in the dialect note as data, never in skill text
  (`reference/principles.md`, Boundaries).
- Nothing invented ships: worked examples and pollen are
  structure-faithful abstractions of real use (recursion doctrine).
- Diffs before writes; idempotent stamps; degrade loudly, never
  silently (bootstrap/scaffold house style).

## Tracking (recursive-spine convention)

Work state lives in GitHub issues and milestones, not in prose files.
- What's in flight: `gh issue list --assignee @me`
- Deferred work: `gh issue list --label deferred`
- Branches: `<prefix>/<issue>-<slug>`; PRs say `Closes #N`.
- Deferral requires a filed issue. Handover files its debts before closing.
Dialect and modules for this repo: [docs/tracking-dialect.md](docs/tracking-dialect.md)

## CI gates

`.github/workflows/validate.yml` holds the repo's mechanical truth
claims: manifest parses, skill frontmatter present, no overstated
maturity in the README, pollen records carry the schema.

## Moments map

- postponing something → file it with the deferral label (recursive-spine-method)
- something just proved itself → capture it (recursive-spine-pollinate)
- closing a unit of work → file debts + ask the pollen question (principle 4)
- "where does work stand?" → recursive-spine-digest
- stamping a new repo → recursive-spine-bootstrap, then recursive-spine-scaffold
