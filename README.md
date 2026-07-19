# recursive-spine

*A project backbone for Claude Code that grows from its own use.*

Most of what a project knows about itself lives in prose files that go
stale the week they're written. recursive-spine puts that state where it
stays true — in GitHub issues and milestones — then stays in a loop with
you: sensing where work stands, surfacing what's next, and keeping what
proves out. A backbone you build on that grows as you use it.

## What it is

A Claude Code plugin — eight skills that give a project a backbone and
help you keep it. In plain terms, it:

- **tracks your work as GitHub issues and milestones** — queryable, with
  none of the merge conflicts or silent row-loss a prose ledger hits;
- **tells you where things stand** — a weekly sweep reports what's aging,
  stalled, or newly unblocked, in plain language;
- **starts the conversation** — nudges you about what's ready to pick up
  next; every nudge ends in a question, never in work done behind your
  back;
- **carries what proves out to other projects** — a pattern, a CI gate, a
  convention that worked once becomes reusable instead of dying where it
  was born;
- **scaffolds house conventions and gates drift** — a rules codex, an ADR
  trail, a constraints file that CI won't let rot.

## Install

**As a Claude Code plugin (recommended).** The repository is its own
plugin marketplace. From inside Claude Code:

```
/plugin marketplace add slopstopper/recursive-spine
/plugin install recursive-spine@recursive-spine
```

The first command registers the repo as a marketplace; the second
installs the eight skills. Updates come through `/plugin`. Start with
the `recursive-spine-method` skill; run `recursive-spine-bootstrap`
when you're ready to stamp a repo.

**Manually.** Clone the repository and point Claude Code at the plugin
directory (`skills/` + `.claude-plugin/plugin.json`), or add it under
`plugins` in your `.claude/settings.json`.

## The recursive part

The name is literal on both sides. **Spine:** the backbone a project
stands on. **Recursive:** a loop you stay in, with the system in it too.

The loop runs like this. Work lives as issues; the system sweeps them and
senses what's drifting; it nudges you about what's unblocked and next; you
decide and build; it records what closed and captures what proved out —
and that record is what the next sweep reads. Nothing runs away from you:
every cycle passes back through your judgment. The system keeps
referencing its own state and growing from its own use, in your service.

It runs this loop on itself, which is the honest test. This repo's issues
and milestones existed before its first commit; its labels were stamped by
its own bootstrap skill, its conventions by its own scaffold, its
deferrals age on its own digest, its constraints gate on its own docs.
Self-applied became self-improving — what building it proved fed back in
as the next thing built. If the convention ever feels too heavy here,
that's a bug in the convention, filed as an issue.

## What's in it

Four parts, each a working module:

- **Tracking** — work state in issues and milestones, never prose. Issues
  also carry depth: macro/micro sub-issue trees, created only at a real
  moment — a plan lands, a handover files its debts, a sequence is
  recorded — never as busywork.
- **Scaffold** — stamps the rest of a repo's spine from frames + your
  interview + proven pollen: rules codex, ADR directory, CI skeleton,
  session-memory convention, constraints file. Every part optional;
  declines recorded.
- **Constraints & records** — one canonical `docs/constraints.md`, a
  sha-pinned drift gate in CI, and the closing record posted on each issue
  when a unit of work ends.
- **Pollination** — the propagation layer: the `pollen/` registry, capture
  and pull, and a graduation ladder (seedling → transplanted → graduated)
  measured by real reuse, not ambition. Nothing invented ships — every
  record abstracts something that actually worked, and says where.

Eight skills, each surfacing at its moment:

- Learning the convention → `recursive-spine-method`
- Stamping tracking onto a repo → `recursive-spine-bootstrap`
- Converting an existing prose ledger → `recursive-spine-migrate`
- Growing the rest of the spine → `recursive-spine-scaffold`
- Closing a unit of work → `recursive-spine-handover`
- Something just proved itself → `recursive-spine-pollinate`
- "Where does work stand?" → `recursive-spine-digest`
- The system starts the conversation → `recursive-spine-nudge`

## Principles

See [reference/principles.md](reference/principles.md). In one line each:
state lives where it's queryable; issues are units, milestones are
narratives; deferral requires a record; handover files its debts before it
closes; branches and PRs cite the record. Issues also carry **depth** —
macro/micro sub-issue trees, created only at a real moment, never
speculatively.

In practice: what's in flight is `gh issue list --assignee @me`; deferred
work is `gh issue list --label deferred`; branches are
`<prefix>/<issue>-<slug>` and PRs say `Closes #N`. This file never
enumerates the deferred work itself — it would go stale the week it was
written, which is the whole point. Dialect and modules for this repo:
[docs/tracking-dialect.md](docs/tracking-dialect.md)

## Kin

- [plumb-line](https://github.com/slopstopper/plumb-line) — whether claims
  are honest (provenance, epistemic enforcement).
- [tokenomics](https://github.com/slopstopper/tokenomics) — which model does
  the work (session economics, lanes).
- recursive-spine — where tracked state lives.

## Licence

Credit-first, per the slopstopper family formula: all prose — skills,
docs, principles, pollen, frames — is **CC BY 4.0**: take it anywhere,
adapt it, use it commercially; the one-line credit travels with every
copy. Scripts and CI are Apache-2.0. The scope map and the requested
attribution format live in [LICENSE](LICENSE). Using the plugin as a
plugin requires nothing — these terms bind republishing, not use.
