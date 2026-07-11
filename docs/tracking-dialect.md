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
  place on this repo and `effythealien/Veska_Index_App`, so existing
  issues carried over automatically.)

## Dialect

Unit of work = **issue**. No local alias — this repo uses the convention's
vocabulary as-is (no repo-specific renaming of "issue", "milestone", etc.).

## Offers declined

- **plumb-line wiring** (epistemic enforcement offer): declined for this
  repo. recursive-spine owns *where tracked state lives*; plumb-line owns
  *whether claims are honest* — kept as separate, un-wired concerns per
  the boundaries section of `reference/principles.md`.
- **tokenomics wiring** (lane-semantics pointer offer): declined for this
  repo, same reasoning — lane labels are stamped (module choice above) but
  not wired to a tokenomics playbook doc.

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
| `effythealien/Veska_Index_App` | 45 |
| `slopstopper/tokenomics` | 0 — no open issues, so nothing to add |

Honest denominator: tokenomics contributes zero items because it has zero
open issues, not because it was skipped. Membership is a point-in-time
snapshot; see "Auto-add" below for why it does not stay current by itself.

**Board visibility: private, and it must stay private.** The board
aggregates issues from private repos (`Veska_Index_App`, and this repo
until its #10 flip). A public board would expose their issue titles.
Anyone making this board public must first confirm every member repo is
public.

## Private-repo caveat (recorded per owner decision, issue #10) — RESOLVED

Previously recorded as an open question: whether a private repo's issues
could be added to a Projects v2 board on this account's plan tier. **They
can.** All 84 items, including those from the private `Veska_Index_App`
and this private repo, were added without error on 2026-07-08. The
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
- **Private hive:** not yet created — tracked as
  [#40](https://github.com/slopstopper/recursive-spine/issues/40). Until
  it exists, capture of personal/private-scope pollen (the #40 hive's
  scope) degrades loudly: draft locally, do not file into this repo.
  This loud-degrade rule does not apply to slopstopper-scope proofs,
  which route to the public hive per above regardless of #10's status.

Routing rule: pollen inherits the visibility scope of its proof
(slopstopper-scope → public hive; personal-scope → private hive #40).
Declassification into the public hive is a deliberate, scrubbed act.
