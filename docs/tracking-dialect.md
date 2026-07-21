# Tracking dialect — recursive-spine

Recorded by the bootstrap skill, run against this repo (recursion point 2:
the repo stamped by its own bootstrap skill). Interview answers below.

## Modules

All four modules stamped — this repo dogfoods everything the skill offers:

- **Deferral (mandatory):** label `deferred`, no alias.
- **Gap:** label `gap`.
- **Debt:** label `inherited-debt`.
- **Lane:** labels `lane:flagship`, `lane:mid`, `lane:small`. (Renamed
  2026-07-11 from `lane:fable` per owner decision: lane names stay
  model-agnostic so routing survives model changes — matching the
  tokenomics portable method, whose top tier is already named "Flagship"
  and whose CI bans model names in lane vocabulary. Labels renamed in
  place on this repo and the owner's private repos (recorded in the
  private hive's dialect note), so existing issues carried over
  automatically.)

## Dialect

Unit of work = **issue**. No local alias — this repo uses the convention's
vocabulary as-is (no repo-specific renaming of "issue", "milestone", etc.).

## Kin offers, as answered

- **plumb-line wiring** (epistemic enforcement offer): declined for this
  repo. recursive-spine owns *where tracked state lives*; plumb-line owns
  *whether claims are honest* — kept as separate, un-wired concerns per
  the boundaries section of `reference/principles.md`.
- **tokenomics wiring** (lane-semantics pointer offer): **accepted
  2026-07-11**, flipped from the original decline (#44) once the backlog
  was actually routed under the method (rationale comment on #20). Lane
  semantics for the `lane:*` labels above are defined by the tokenomics
  method: the routing test ("if this is done slightly wrong, is it
  expensive?") and the lane definitions in
  [tokenomics' `reference/portable-method.md`](https://github.com/slopstopper/tokenomics/blob/main/reference/portable-method.md).

  **Independence contract:** the pointer is semantics documentation, not
  a dependency. recursive-spine functions fully without tokenomics
  installed — no skill reads the tokenomics repo, and the lane labels
  remain plain labels for anyone who ignores the pointer.

  **Pollination seam:** in tokenomics' cycle terms, a pollen record is a
  candidate compression artifact, and a graduated skill is a macro-cycle
  exit artifact. Vocabulary seams stay explicit: spine **handover**
  (principle 4 — filing debts before a unit closes) is not tokenomics
  **handoff** (its session-boundary artifact); the two words are kept
  unmerged on purpose.

## Spine board

**Board owner:** `slopstopper` (the org) — changed from `effythealien` when
the three plugins moved into the org. Recorded here as data so the skills
stay owner-neutral (text).

**`SPINE_BOARD_NUMBER`: 2** — <https://github.com/orgs/slopstopper/projects/2>
Created 2026-07-08 once the owner ran `gh auth refresh -s project,read:project,admin:org`
interactively. Issue #14 (board pending) is closed.

**Membership, as added:** 84 open issues, 84/84 `item-add` calls succeeded.

| repo | open issues added |
| --- | --- |
| `slopstopper/recursive-spine` | 7 |
| `slopstopper/plumb-line` | 32 |
| `slopstopper/tokenomics` | 0 — no open issues, so nothing to add |

Personal-repo membership moved to the private hive's board
(`effythealien/private-hive`, #40); this board is public-scope
(slopstopper repos).

Honest denominator: tokenomics contributes zero items because it has zero
open issues, not because it was skipped. Membership is a point-in-time
snapshot; see "Auto-add" below for why it does not stay current by itself.

**Board visibility: private for now.** The board no longer aggregates
personal-repo issues — the split completed 2026-07-11 (#40): the 45
personal-repo items were added to the private hive's board and then
removed from this one. What keeps this board private today is this repo's
own pending visibility flip ([#10](https://github.com/slopstopper/recursive-spine/issues/10)).
Anyone making this board public must first confirm every member repo is
public.

## Private-repo caveat (recorded per owner decision, issue #10) — RESOLVED

Previously recorded as an open question: whether a private repo's issues
could be added to a Projects v2 board on this account's plan tier. **They
can.** All 84 items, including those from the owner's private repos
(recorded in the private hive's dialect note) and this private repo, were
added without error on 2026-07-08. The
question is settled; the answer is recorded rather than the question
quietly deleted.

## Views and auto-add — still to do, by hand

Views (by repo, by lane, by deferral age) and the board's **auto-add
workflows** (Project → Settings → Workflows → "Auto-add to project", one
per repo) are UI-only configuration on Projects v2 and cannot be created
via the `gh` CLI or the public GraphQL API.

**Consequence, stated plainly:** until auto-add is switched on in the UI,
the board does **not** pick up newly-filed issues. Its membership is the
2026-07-08 snapshot above and will silently go stale. The digest skill's
repo-set fallback (this dialect note) is unaffected and remains correct.
This is tracked as issue #35.

## pollinate: hives (this installation)

Recorded per the pollinate skill's interview (recursion: this repo
configures itself first).

- **Public hive:** `slopstopper/recursive-spine` (this repo, `pollen/`) —
  pollen whose proof is public (plumb-line, tokenomics, this repo).
  Must stay self-contained: no references readers can't resolve. This
  hive is scoped to the slopstopper ecosystem's repos, not to this
  repo's own GitHub setting: proofs from recursive-spine, plumb-line, or
  tokenomics route here even while this repo's own visibility flip is
  pending ([#10](https://github.com/slopstopper/recursive-spine/issues/10)) —
  "public" names the scope, not this repo's current GitHub setting.
- **Private hive:** `effythealien/private-hive` (created 2026-07-11,
  [#40](https://github.com/slopstopper/recursive-spine/issues/40)) —
  pollen whose proof is personal/private-scope files there, never into
  this repo. Its board, digest configuration for the owner's private
  repos, and record schema live in that repo's own dialect note and
  `pollen/README.md`.

Routing rule: pollen inherits the visibility scope of its proof
(slopstopper-scope → public hive; personal-scope → private hive #40).
Declassification into the public hive is a deliberate, scrubbed act.

## scaffold (this installation)

Recorded per the scaffold skill's interview, run against this repo
(recursion: the module's first target is the repo that ships it).

- **Rules codex:** accepted — minimal, from the record: `CLAUDE.md`
  stamped with mission, house rules already stated on the record,
  tracking section (bootstrap's, unchanged), CI pointer, and the moments
  map. Session-memory section omitted (that part declined).
- **ADR directory:** accepted — `docs/adr/`, ADR-0001 backfilled from
  the real sibling-skill decision (#32).
- **CI gates:** already present — `.github/workflows/validate.yml` is
  this repo's gate set and the source proof of the `truth-gate-ci`
  pollen. Nothing stamped.
- **Session memory:** declined — repo-level session memory is not in use
  here; the builder's memory convention lives at the environment level
  (see the `layered-session-memory` pollen record).
- **Pollen pulls:** none recorded — this repo is the source of both seed
  records; "already present" is the truthful answer. First real
  transplants remain #42.
- **Kin offers:** plumb-line guard wiring and tokenomics playbook
  pointer — both already answered in "Kin offers, as answered" above;
  not re-asked.

## loop (this installation)

Recorded per the portable GitHub-Action loop (#93), run against this repo
(recursion: the module dogfoods itself via `.github/workflows/spine-loop.yml`,
calling the composite action at `./loop`).

- **Swept repos (the family):** `slopstopper/recursive-spine`,
  `slopstopper/plumb-line`, `slopstopper/tokenomics`,
  `effythealien/Veska_Index_App`.
- **Tracking issue:** `slopstopper/recursive-spine#20` — the digest comment
  target.
- **Notify:** `@effythealien`.
- **Ledger:** `effythealien/private-hive:nudges/ledger.md` — nudge records
  append here, same split as the pollinate private hive above.
- **Schedule:** Saturday 08:00 UTC (`cron: "0 8 * * 6"`), plus
  `workflow_dispatch` for manual runs.
- **Token requirement:** the family sweep needs the `SPINE_SWEEP_TOKEN` PAT
  because it spans two owners (`slopstopper` and `effythealien`) — a
  same-owner `GITHUB_TOKEN` cannot read across both.
- **Stopgap replaced:** this workflow replaces the personal `launchd`
  stopgap (`com.slopstopper.spine-loop.plist`) once the owner adds the repo
  secrets and verifies a live run; retirement of the launchd job is owner-
  gated and tracked separately, not assumed done by this record.

## connective tissue (this installation)

Recorded per the connective-tissue vertebra (#33), run against this repo
(recursion: the module's first target is the repo that ships it).

- **Constraints file:** accepted — `docs/constraints.md`, every line
  from the record (principles, dialect note, CI gates, surfacing
  pollen); nothing invented.
- **Drift gate:** wired — `scripts/check-constraints-drift.sh` runs in
  `.github/workflows/validate.yml` (checkout at `fetch-depth: 0`).
  Sha-pinned: merged docs stay green when the canonical file evolves;
  stale pins in open-issue docs are the digest's concern.
- **Handover:** `recursive-spine-handover` ships with this vertebra; its
  first live record is #33's own closing comment, posted when the
  vertebra's PR merges — the module's first act is recording its own
  completion.
- **Kin seam (settled at design time):** split ownership. Spine
  handover = closing record; tokenomics handoff = dispatch contract.
  The handover template offers the handoff-spec pointer as data (see
  "Kin offers, as answered" above); no dependency.
