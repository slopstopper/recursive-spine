# Portable collaborative-loop substrate — design (#93)

**Date:** 2026-07-21
**Scopes:** #93 (portable runner + delivery); absorbs #82 (pluggable
delivery); resolves #80 (self-DM never notifies); relates #21 (scheduler),
#47 (origin)
**Lane:** flagship · **Target:** v0.10.0

## Intent

The collaborative loop's *nudge-selection logic* is real and shipped, but
its *automated runner and delivery* work only on the author's Mac after a
bespoke launchd workaround — while the README and v0.8.0 framing imply a
working weekly loop for anyone. This build makes the runner and delivery
genuinely portable across users, so the shipped-claim becomes true.

**What this build makes portable:** the **runner** (any user's own GitHub
Actions, first-party, no headless-injection refusal) and the **delivery**
(a channel that actually notifies). **What stays fixed, deliberately:** the
**platform** (GitHub — state is issues, runner is Actions) and the **model**
(nudge judgment calls Claude). Cross-forge and model-agnostic nudges are
#46, out of scope.

## Architecture — a reusable Action, adopted via a stamped workflow, tiered by secret

GitHub's default `GITHUB_TOKEN` reaches only the workflow's own repo.
Capabilities therefore tier up by what secret a user adds, and each
unconfigured capability **degrades loudly** rather than failing:

| Tier | Secret | Capability |
|---|---|---|
| 0 (default) | none | Deterministic digest of the **own** repo → comment on the tracking issue, **@mentioning the owner** (free GitHub notification) |
| 1 | a PAT / GitHub App token (`SPINE_SWEEP_TOKEN`) | **Cross-repo sweep** (a repo set / family) |
| 2 | `ANTHROPIC_API_KEY` | **LLM nudges** — ≤3 conversation-starters with judgment + ledger suppression |
| 3 | `SLACK_WEBHOOK_URL` | Nudges also pushed to a Slack **webhook** (a real bot/app — notifies, unlike the self-DM) |

The loop *meets a user where they are*: it upgrades by configuration, not
code change.

## Components

### 1. Deterministic digest script (Tier 0/1, no LLM)
A portable shell script (`gh` + POSIX tools) that runs the mechanical
sweep — aging deferrals (oldest first), stalled milestones, in-flight by
lane, assigned-but-untouched, honest denominators, and depth roll-up — and
posts ONE comment to the tracking issue, @mentioning the owner. Runs on
`GITHUB_TOKEN` (own repo) or `SPINE_SWEEP_TOKEN` (repo set).

**Trade-off (recorded):** the deterministic digest is tabular; #81's
LLM-authored "briefing voice" (plain-language glance) is **not** reproduced
in shell. When Tier 2 is enabled, the LLM step may add the glance
paragraph; without it, the digest is honest tables. Rebuilding the briefing
voice in shell is explicitly out of scope.

### 2. Optional nudge step (Tier 2, LLM)
When `ANTHROPIC_API_KEY` is present, a second job invokes Claude (Claude
Code Action or a small API script) to run the **recursive-spine-nudge**
logic against the digest output + the ledger: four triggers, ledger
suppression, shape gate (observation → why now → question), max 3. Appends
the ledger. Invoked as a named action step with the nudge skill as its
runbook — **not** a fat inline "obey this" prompt (which is what tripped the
headless injection guard, #21).

### 3. Delivery (pluggable, notifying)
- **Default:** the digest/nudge comment @mentions the repo owner → GitHub
  notification (email/mobile), zero setup, works for every user. This is
  the #80 resolution: no self-DM.
- **Optional Slack:** if `SLACK_WEBHOOK_URL` is set, also POST to it (a
  bot/webhook that genuinely notifies).
- Channel, threshold, repo set, tracking issue, ledger location: all read
  from the repo's dialect note or workflow inputs. Never hardcoded.

### 4. Reusable Action
`slopstopper/recursive-spine` publishes a composite/reusable action at a
stable path (e.g. `loop/action.yml`), versioned by tag (`loop@v1`). It runs
the digest always, the nudge step if the key is present, and delivery per
config. Users get updates via version bump — no per-user copy to drift.

### 5. Scaffold integration
`recursive-spine-scaffold` gains an optional **loop** part that stamps
`.github/workflows/spine-loop.yml` into a user's repo: a cron schedule +
`uses: slopstopper/recursive-spine/loop@v1` + the repo's config (tracking
issue, repo set, thresholds). Optional like every scaffold part; declines
recorded. The stamped file is thin — logic lives in the versioned action,
not the copy.

## House rules

Config-neutral (no owner/repo/channel baked into the action). Degrade
loudly: missing key → digest-only and says so; a repo that fails to sweep
is a line in the report, never omitted; missing tracking issue → loud error.
Honest denominators in every run.

## Dogfood (recursion doctrine)

recursive-spine retires the author's launchd stopgap and runs **this
Action** on its own family (recursive-spine, plumb-line, tokenomics,
Veska_Index_App, private hive) — which exercises Tier 1 (the `SPINE_SWEEP_TOKEN`
PAT, since the family spans repos and two owners) and Tier 2/3. The spine
runs its own loop through the artifact it ships. The launchd job is removed
once the Action is verified.

## Testing

- The digest script has unit-ish checks: given a fixture repo state, it
  emits the expected tabular sections and honest denominator.
- The Action is dogfooded on recursive-spine itself (a real scheduled run
  posting to #20), which is the end-to-end test.
- Tier degradation verified: run with no key (digest-only, says so), with
  key (nudges), with webhook (Slack post) — each observed.

## Out of scope

- The **honesty patch** (soften README/v0.8.0 claims) — a separate small
  change, done in parallel.
- **#46** cross-model nudges and cross-forge portability (platform stays
  GitHub, model stays Claude).
- Rebuilding #81's briefing voice in the deterministic digest.
- Retiring the local launchd path as an *option* — it remains a documented
  power-user substrate; only the author's personal instance is dogfood-
  replaced.

## Migration / claims

On ship: the README and release framing move from "a weekly cloud routine
sweeps and nudges you" (author-only today) to the true, tiered description.
The honesty patch bridges the gap until this lands.
