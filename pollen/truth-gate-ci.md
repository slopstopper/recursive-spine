---
id: pollen-truth-gate-ci
form: pattern
source: slopstopper/recursive-spine#3
captured: 2026-07-11
stage: seedling
transplants: []
---

# Truth-gate CI

CI steps that grep/`jq` the repo's own claims and fail loud when a claim
goes stale — treating documentation honesty as a testable invariant, not
a review-time hope.

## What worked

Small bash steps in a plain GitHub Actions workflow, one named step per
invariant. In live use in two repos:

- `slopstopper/recursive-spine` `.github/workflows/validate.yml`:
  manifest parses and names the plugin (`jq -e`), every skill carries
  `name:` + `description:` frontmatter, README never overstates maturity
  (`! grep -inE 'battle-tested|production-ready'`), every pollen record
  carries the schema keys and enum values.
- `slopstopper/tokenomics` `.github/workflows/gates.yml`: bans model
  names (`Fable|Opus|Sonnet|Haiku`) everywhere except the one file
  allowed to name them — lane vocabulary stays model-agnostic by force.

## Why it worked

Stale claims are the cheapest thing to ship and the most expensive to
discover socially ("the README lied"). Each gate costs one grep at CI
time and turns a silent drift into a red X. The gate is also a recorded
decision: reading the workflow tells you exactly which claims the repo
considers load-bearing.

## How to transplant

1. Identify claims that are expensive if silently wrong (counts of
   shipped things, maturity words, banned vocabulary, schema promises).
2. One named workflow step per claim; the step name states the claim
   ("Pollen records carry the required front-matter").
3. Express the check as grep/`jq` against the repo's own files; collect
   failures into a `fail` flag and `exit $fail` — report every miss, not
   just the first.
4. Never gate on things a human must judge; gates hold *mechanical*
   truth (presence, count, enum, absence) and leave judgment to review.
