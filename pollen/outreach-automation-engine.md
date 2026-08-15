---
id: pollen-outreach-automation-engine
form: pattern
source: slopstopper/plumb-line#260
captured: 2026-08-15
stage: seedling
transplants: []
---

# Outreach automation engine — gated drafts, never direct publishes

## What worked

A repo that ships real work generates its own outreach material as a
by-product; the engine turns that into drafted-only outbound with the owner
as the sole publisher, and every guardrail defined once on a parent issue
(plumb-line#260) that the routines reference instead of restating.

Three routines, two proven in a day of real use:

- **Release-to-content** (plumb-line#255, PR plumb-line#272): a GitHub
  Action on `release: published` opens a "content draft due" issue; the
  piece is drafted in-session from shipped artifacts only (changelog,
  validation records), passes four gates, publishes to a `docs/content/`
  directory, and is embedded in full in the release body with a
  canonical-copy link back.
- **Opportunity watcher** (plumb-line#256, contract in the repo, weekly
  scheduled cloud agent): sweeps papers/listings/discussions/community and
  files one digest issue with 0–3 *drafted* actions. First live run
  (plumb-line#275) held the null-result spine — zero actions, stated
  denominator, self-reported coverage gap.
- **Monthly strategy digest** (plumb-line#257): same shape, monthly, metrics
  with honest denominators. Not yet built at capture time.

## Why it worked

- **Drafts only + owner approval last** removes the brand risk that kills
  automated outreach; the cap (≤4 published items/month across routines)
  bounds it structurally.
- **The audit gate on marketing prose** is the project's own discipline
  aimed at its own outbound — overstated maturity in a promo is a finding
  like any code finding. The language check is a *flagger*, deliberately
  not a CI gate: banning strings in CI invites synonym evasion and false
  confidence (decision recorded on plumb-line#260 thread and in
  `scripts/check_content_language.py`'s docstring).
- **Digests are skippable by design**: state accumulates in issues, so an
  owner with bursty capacity loses nothing by not reading for weeks.
- **A zero-action digest is valid.** The watcher's first run proved the
  quota pressure can be refused; without that rule the routine becomes an
  opportunity-inventing machine.

## How to transplant

Prerequisites: the repo ships releases (or notable merges), has an issue
tracker in the spine convention, and the owner wants outbound they approve
rather than write.

1. File the parent issue with the shared gates (copy plumb-line#260's six:
   drafts-only, audit gate, language standard, AI-provenance disclosure,
   outbound cap, no astroturfing). Adjust the audit gate to whatever
   review discipline the repo practices if it lacks plumb-line.
2. Copy `docs/content/TEMPLATE.md` and `scripts/check_content_language.py`
   (+ its test) from plumb-line; adapt the disclosure wording to the
   owner's approved line.
3. Copy `.github/workflows/release-content.yml` (release event → draft-due
   issue; hardcoded strings only, release fields via quoted env vars).
4. Write the watcher contract (copy `docs/content/WATCHER.md`, swap sweep
   targets for the repo's own channels) and schedule the weekly cloud
   agent whose prompt points at the contract and whose only permitted
   write is the digest issue.
5. Adopt at the right moment: this pollen is for a repo that already has
   something shipping — an engine on a repo with nothing to say drafts
   noise.
