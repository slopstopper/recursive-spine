---
name: bootstrap
description: Use when installing the recursive-spine tracking convention onto a repo — interviews for modules and dialect, then stamps labels, issue/PR templates, a CLAUDE.md/AGENTS.md tracking section, and cross-project board membership. Idempotent; degrades loudly on missing gh scopes; offers (never forces) plumb-line and tokenomics wiring.
---

# recursive-spine: bootstrap

Stamp the convention onto the current repo. Read
`${CLAUDE_PLUGIN_ROOT}/reference/principles.md` first. If the user hasn't
seen the convention before, offer the `method` skill before stamping.

## 1. Preflight (fail loud, not silent)

- `gh auth status` — must be authenticated.
- `gh repo view --json nameWithOwner` — must be a GitHub repo.
- Board membership needs project scope: run `gh auth status` and check for
  `project` scope. If absent: DO NOT silently skip. Tell the user exactly
  what's missing (`gh auth refresh -s project`) and file a repo issue titled
  "spine: board membership pending (missing gh project scope)" so the gap is
  a record, not a memory.

## 2. Interview (one question at a time)

1. Which modules? Deferral is mandatory (offer alias naming, default
   `deferred`). Offer gap / debt / lane with one-line failure-mode pitches.
2. Dialect: what does this repo call a unit of work? Any existing label
   conventions to respect?
3. Board: add this repo to the user-level "Spine" Projects board? (Needs the
   scope from preflight.)
4. If the plumb-line plugin is installed (check for a `plumb-line-bootstrap`
   skill): offer it for epistemic enforcement — separate concern, their
   choice. If a tokenomics playbook exists in the repo: offer to point the
   tracking section at it for lane semantics. Offers only.

## 3. Stamp (idempotent — re-runs must not duplicate)

- Labels via `gh label create <name> --description "<desc>" --color <hex> --force`
  (`--force` updates existing — this is the idempotency mechanism):
  - deferral label (chosen name), color `D93F0B`,
    desc "Postponed with a record — principle 3".
  - if gap module: `gap`, `B60205`, "Finding from an assessment".
  - if debt module: `inherited-debt`, `FBCA04`,
    "Known-incomplete edge handed over from a closed unit".
  - if lane module: `lane:fable` `1D76DB`, `lane:mid` `5319E7`,
    `lane:small` `C5DEF5`, desc "Model-routing lane".
- Copy templates from `${CLAUDE_PLUGIN_ROOT}/reference/templates/`:
  `work-item.md` and `deferral.md` → `.github/ISSUE_TEMPLATE/` (substitute
  the chosen deferral label into deferral.md's `labels:` line);
  `pull_request_template.md` → `.github/`. If a PR template already exists,
  show a merged proposal — never overwrite silently.
- Tracking section: append `tracking-section.md` (with `<DEFERRAL_LABEL>` and
  `<DIALECT_NOTE_LINK>` substituted) to CLAUDE.md or AGENTS.md — ask which,
  show the diff, get approval before writing.
- Dialect note: write the interview answers to
  `docs/tracking-dialect.md` (or the repo's docs convention).
- Board: `gh project item-add <SPINE_BOARD_NUMBER> --owner effythealien
  --url <repo issue URL>` is per-item; for whole-repo aggregation prefer the
  board's built-in auto-add workflow — open the board settings URL for the
  user and confirm they enabled it for this repo.

## 4. Report

End with: modules stamped, labels created/updated (names), files written,
board status (added / pending-scope issue #N), and the exact queries the
repo now answers (`gh issue list --label <deferral>` etc.). List anything
skipped and why — honest denominator.
