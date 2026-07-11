# recursive-spine

A portable project spine, recursively self-applied.

The name is literal. **Spine:** the plugin grows a backbone for a project,
vertebra by vertebra — tracking, scaffold, connective tissue, pollination.
**Recursive:** every vertebra is built under the convention it enforces,
and since pollination shipped, the system feeds what its own use proves
back into itself — self-applied became self-improving.

The first vertebra is tracking: work state lives in GitHub issues and
milestones — queryable, conflict-free — never in prose ledger files that
merge as text and lose rows. This plugin teaches the convention
(`recursive-spine-method`), stamps it onto repos
(`recursive-spine-bootstrap`), converts existing prose ledgers to it
(`recursive-spine-migrate`), and sweeps every conforming repo for aging
deferrals and stalled work (`recursive-spine-digest`). The fourth vertebra
is pollination: `recursive-spine-pollinate` captures elements that proved
themselves in one project and pulls them into others.

The second vertebra is the scaffold: `recursive-spine-scaffold` stamps
the rest — rules codex, ADR directory, CI gate skeleton, session-memory
convention — from frames, the builder's interview, and proven pollen.

**Status, with an honest denominator: three of four vertebrae shipped.**

- **Vertebra 1 — tracking: shipped.** The five principles
  (reference/principles.md) and four of the six skills, extracted from
  live practice in two repos (plumb-line, Veska Index). A practice report,
  not a benchmark.
- **Vertebra 4 — pollination: shipped** (built out of order, deliberately:
  it captures learnings from building the other two). The pollinate skill,
  the `pollen/` registry, and the graduation ladder.
- **Vertebra 2 — scaffold: shipped.** `recursive-spine-scaffold` stamps
  rules codex, ADRs, CI gates, and session memory from frames + the
  builder's interview + proven pollen. Recursion test run against this
  repo (see `docs/tracking-dialect.md`, "scaffold").
- **Vertebra 3 — connective tissue: planned**, tracked as #33 — generated
  spec/plan/handover docs, constraints from one canonical source.

The remaining work is tracked in this repo's own issues — that's the
point. Operational loose ends live in the open too: the Spine
cross-project board exists (created 2026-07-08) but its auto-add is
UI-only and pending (#35), the scheduled digest is deferred (#21), and
the public visibility flip is pending (#10).

## The recursion

This repo's issues and milestones existed before its first commit. Its
labels were stamped by its own bootstrap skill. Its deferrals age on its own
digest. If the convention ever feels too heavy here, that is a bug in the
convention — filed as an issue, of course.

## The five principles

See [reference/principles.md](reference/principles.md). In one line each:
state lives where it's queryable; issues are units, milestones are
narratives; deferral requires a record; handover files its debts before it
closes; branches and PRs cite the record.

## Install

**As a Claude Code plugin (recommended).** The repository is its own
plugin marketplace. From inside Claude Code:

```
/plugin marketplace add slopstopper/recursive-spine
/plugin install recursive-spine@recursive-spine
```

The first command registers the repo as a marketplace; the second installs
the six skills. Updates come through `/plugin`. Start with the
`recursive-spine-method` skill; run `recursive-spine-bootstrap` when you're
ready to stamp a repo.

**Manually.** Clone the repository and point Claude Code at the plugin
directory (`skills/` + `.claude-plugin/plugin.json`), or add it under
`plugins` in your `.claude/settings.json`.

## Tracking (recursive-spine convention)

Work state lives in GitHub issues and milestones, not in prose files.
- What's in flight: `gh issue list --assignee @me`
- Deferred work: `gh issue list --label deferred`
- Branches: `<prefix>/<issue>-<slug>`; PRs say `Closes #N`.
- Deferral requires a filed issue. Handover files its debts before closing.
Dialect and modules for this repo: [docs/tracking-dialect.md](docs/tracking-dialect.md)

## Kin

- [plumb-line](https://github.com/slopstopper/plumb-line) — whether claims
  are honest (provenance, epistemic enforcement).
- [tokenomics](https://github.com/slopstopper/tokenomics) — which model does
  the work (session economics, lanes).
- recursive-spine — where tracked state lives.

MIT.
