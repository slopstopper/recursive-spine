# recursive-spine

A portable project spine, recursively self-applied.

The name is literal. **Spine:** the plugin grows a backbone for a project,
vertebra by vertebra — tracking, scaffold, connective tissue, pollination.
**Recursive:** every vertebra is built under the convention it enforces,
and since pollination shipped, the system feeds what its own use proves
back into itself — self-applied became self-improving.

**Status, with an honest denominator: four of four vertebrae shipped.**

- **Vertebra 1 — tracking:** work state lives in GitHub issues and
  milestones — queryable, conflict-free — never in prose ledgers that
  merge as text and lose rows. The five principles
  (reference/principles.md) and the method, bootstrap, migrate, and
  digest skills. A practice report, not a benchmark.
- **Vertebra 2 — scaffold:** stamps the rest of a repo's spine from
  frames + the builder's interview + proven pollen — rules codex with a
  moments map, ADR directory, CI gate skeleton, session-memory
  convention, constraints file.
- **Vertebra 3 — connective tissue:** `docs/constraints.md` as the one
  canonical source of global constraints, a sha-pinned drift gate in CI
  (hand-copies were a measured drift vector), and the closing record
  posted on each issue when a unit of work ends.
- **Vertebra 4 — pollination:** captures elements that proved themselves
  in one project and pulls them into others — the `pollen/` registry and
  the graduation ladder (seedling → transplanted → graduated).

Build order was deliberately non-sequential (4 → 2 → 3: pollination
first, so it could capture learnings from building the other two). The
numbering is the spine's anatomy, not its history.

Seven skills, each surfacing at its moment:

- Learning the convention → `recursive-spine-method`
- Stamping tracking onto a repo → `recursive-spine-bootstrap`
- Converting an existing prose ledger → `recursive-spine-migrate`
- Growing the rest of the spine → `recursive-spine-scaffold`
- Closing a unit of work → `recursive-spine-handover`
- Something just proved itself → `recursive-spine-pollinate`
- "Where does work stand?" → `recursive-spine-digest`

The remaining work is tracked in this repo's own issues — that's the
point. Operational loose ends live in the open too: the Spine board's
auto-add is UI-only and pending (#35), the scheduled digest is deferred
(#21), the public visibility flip is pending (#10), and the private-hive
migration is in flight (#40).

## The recursion

This repo's issues and milestones existed before its first commit. Its
labels were stamped by its own bootstrap skill. Its codex and ADR
directory were stamped by its own scaffold skill. Its deferrals age on
its own digest, and its constraints drift-gate runs on its own docs. If
the convention ever feels too heavy here, that is a bug in the
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
the seven skills. Updates come through `/plugin`. Start with the
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

## Licence

Credit-first: all prose — skills, docs, principles, pollen, frames —
is **CC BY 4.0**: take it anywhere, adapt it, use it commercially; the
one-line credit travels with every copy. Scripts and CI are MIT. The
scope map and the requested attribution format live in
[LICENSE](LICENSE). Using the plugin as a plugin requires nothing —
these terms bind republishing, not use.
