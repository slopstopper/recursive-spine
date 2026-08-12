---
name: recursive-spine-bootstrap
description: Use when installing the recursive-spine tracking convention onto a repo — interviews for modules and dialect, then stamps labels, issue/PR templates, a CLAUDE.md/AGENTS.md tracking section, and Projects board membership. Idempotent; degrades loudly on missing gh scopes; offers (never forces) plumb-line and tokenomics wiring.
---

# recursive-spine: bootstrap

Stamp the convention onto the current repo. Read
`${CLAUDE_PLUGIN_ROOT}/reference/principles.md` first. If the user hasn't
seen the convention before, offer the `recursive-spine-method` skill before
stamping.

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
   If lane is chosen: ask the builder to NAME their own tiers — offering the
   tier names found in the repo's tokenomics playbook when one exists. Ship
   no default lane names — tokenomics' rule; the tiers are the builder's own
   words.
2. Dialect: what does this repo call a unit of work? Any existing label
   conventions to respect?
3. Board: give this repo **its own** Projects board? One board per repo is
   the default, because it is the only shape auto-add can keep current
   (step 3 states the limits). A shared cross-project board is still
   available, but offer it as a thing that must be swept or hand-curated —
   never as automatic. (Needs the scope from preflight.)
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
  - if lane module: `lane:<tier>` for exactly the tier names the builder
    named in the interview (never shipped defaults). Color by rank: top
    tier `1D76DB`, mid tier(s) `5319E7`, smallest tier `C5DEF5` — desc
    "Model-routing lane". If more than three tiers, note the extra tiers'
    colors sensibly (e.g. reuse `5319E7` for all middle tiers) rather than
    inventing new hex values ad hoc.
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
- Board: read the board owner and `SPINE_BOARD_NUMBER` from the target repo's
  `docs/tracking-dialect.md` (or equivalent dialect note) if present. If this
  is the first repo being stamped and no dialect note yet records a board
  owner, ask the user which account/org owns the board and record the answer
  in the dialect note before proceeding. With owner and number known,
  `gh project item-add <SPINE_BOARD_NUMBER> --owner <BOARD_OWNER> --url
  <repo issue URL>` adds items; it works across owners.

  **State these two limits before the builder chooses (#128).** Neither is
  lifted by a paid plan, and both were confirmed in the UI:
  1. **Auto-add cannot cross an owner boundary** — a user-owned project's
     auto-add repository picker does not list organisation repos at all.
     Manual `item-add` *does* cross owners, which is what makes this
     convincing: the board fills up and looks aggregated right until you
     try to automate it.
  2. **The workflow count is capped per project**, observed as one on both
     a free org and a paid personal account.

  So: **a single-repo board can keep itself current via auto-add; a
  multi-repo board cannot.** Offer the auto-add settings URL for the
  single-repo case. For any board covering more than one repo — or a
  user-owned board covering org repos — say plainly that membership will
  silently go stale, and point at the loop Action's `board` input, which
  sweeps it. Do not describe auto-add as the aggregation mechanism.

  Verify membership by reading each **issue's** `projectItems`, never the
  project's item list: the project-side read path lags writes (observed
  reporting 29 items where the issue-side query saw all 41).

- Board views: propose them from the modules just stamped — do not invent a
  layout, and do not ship one the repo's own rules do not imply. A repo that
  followed the interview already specifies its views:
  - **Now** — current milestone, grouped by status.
  - **Release plan** — grouped by milestone.
  - **Unscheduled** — the repo's deliberately-unscheduled convention, if it
    has one (e.g. a `track:*` label family). Where the repo's rule is
    "exactly one of a milestone or an unscheduled label", this view and the
    previous one are mutually exclusive by construction: anything in both,
    or in neither, is a tracking bug the board surfaces.
  - **Outbox** — the deferral label, sorted oldest-first. Where the repo has
    a drain rule (e.g. "older than N days is scheduled or waived"), the sort
    is what makes it unignorable.
  - **Lane** views only if the lane module was taken.

  Ship **no priority field** by default. Milestones already encode order; a
  second ranking restates it and creates a way for the two to disagree. Add
  one only if the builder ranks *within* a milestone, and then in their
  words.

## 4. Report

End with: modules stamped, labels created/updated (names), files written,
board status (added / pending-scope issue #N), and the exact queries the
repo now answers (`gh issue list --label <deferral>` etc.). List anything
skipped and why — honest denominator.

If the repo now wants the rest of its spine — rules codex, ADRs, CI
gates, session memory — offer `recursive-spine-scaffold` as the natural
next step (offer, not upsell: one line, their choice).
