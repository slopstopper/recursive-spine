# recursive-spine

A tracking convention that survives being applied to itself.

Work state lives in GitHub issues and milestones — queryable, conflict-free —
never in prose ledger files that merge as text and lose rows. This plugin
teaches the convention (`method`), stamps it onto repos (`bootstrap`),
converts existing prose ledgers to it (`migrate`), and sweeps every
conforming repo for aging deferrals and stalled work (`digest`).

**Status: partial.** Extracted from live practice in two repos (plumb-line,
Veska Index). This is a practice report, not a benchmark. Currently shipped:
the principles (reference/principles.md). Planned (tracked in this repo's
own issues — that's the point): method, bootstrap, migrate, digest skills.

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

Claude Code plugin: `skills/` + `.claude-plugin/plugin.json`. Start with the
`method` skill; run `bootstrap` when you're ready to stamp a repo.

## Tracking (recursive-spine convention)

Work state lives in GitHub issues and milestones, not in prose files.
- What's in flight: `gh issue list --assignee @me`
- Deferred work: `gh issue list --label deferred`
- Branches: `<prefix>/<issue>-<slug>`; PRs say `Closes #N`.
- Deferral requires a filed issue. Handover files its debts before closing.
Dialect and modules for this repo: [docs/tracking-dialect.md](docs/tracking-dialect.md)

## Kin

- [plumb-line](https://github.com/effythealien/plumb-line) — whether claims
  are honest (provenance, epistemic enforcement).
- tokenomics — which model does the work (session economics, lanes).
- recursive-spine — where tracked state lives.

MIT.
