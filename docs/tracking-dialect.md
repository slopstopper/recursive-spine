# Tracking dialect — recursive-spine

Recorded by the bootstrap skill, run against this repo (recursion point 2:
the repo stamped by its own bootstrap skill). Interview answers below.

## Modules

All four modules stamped — this repo dogfoods everything the skill offers:

- **Deferral (mandatory):** label `deferred`, no alias.
- **Gap:** label `gap`.
- **Debt:** label `inherited-debt`.
- **Lane:** labels `lane:fable`, `lane:mid`, `lane:small`.

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

**Board owner:** `effythealien` — this installation's designated board
owner, recorded here (data) so the skills stay owner-neutral (text).

**Status: not created.** `gh project create --owner effythealien --title
"Spine"` failed:

```
error: your authentication token is missing required scopes [project read:project]
To request it, run:  gh auth refresh -s project,read:project
```

The active `gh` token has scopes `gist, read:org, repo, workflow` — no
`project` scope. `gh auth refresh -s project` requires an interactive
browser/device-code confirmation this automation session could not
complete. This gap is recorded, not silently skipped, per the bootstrap
skill's preflight step: see issue
[#14](https://github.com/slopstopper/recursive-spine/issues/14) ("spine:
board membership pending (missing gh project scope)").

**To unblock:** run `gh auth refresh -s project,read:project` interactively,
then:

```sh
gh project create --owner effythealien --title "Spine"
gh project list --owner effythealien --format json --jq '.projects[] | select(.title=="Spine") | .number'
```

Record the returned number here as `SPINE_BOARD_NUMBER`, then add each
repo's open issues:

```sh
for url in $(gh issue list --repo effythealien/<repo> --json url --jq '.[].url'); do
  gh project item-add <SPINE_BOARD_NUMBER> --owner effythealien --url "$url"
done
```
for `recursive-spine`, `plumb-line`, `tokenomics`, `Veska_Index_App`.

`SPINE_BOARD_NUMBER`: **not assigned** — board does not exist yet.

## Private-repo caveat (recorded per owner decision, issue #10)

This repo is private by owner decision (issue #10). Whether a private
repo's issues can be added to a user-owned Projects v2 board depends on the
GitHub plan tier for the account — this was not reachable to test in this
session because board creation itself failed on the missing scope above.
Whoever runs the unblock steps should check this explicitly: if
`gh project item-add` errors on private-repo issue URLs, record that error
here rather than silently omitting items.

## Views

Not configured. Views (by repo, by lane, by deferral age) are UI-only
configuration on the Projects v2 board itself and cannot be created via
`gh` CLI. Same for the board's auto-add workflow (workflows → auto-add per
repo) — also UI-only. Both remain to be done by hand once the board exists.

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
