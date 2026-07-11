# Contributing

This repo runs on its own convention — contributing here *is* using the
product. The short version:

- **Issues before code.** Every unit of work is a GitHub issue; nothing
  lands without one. Check `gh issue list` before filing — the record
  is the source of truth, not this file.
- **Branches and PRs cite the record:** branch `<prefix>/<issue>-<slug>`,
  PR body says `Closes #N`.
- **Deferral requires a filed issue.** If your PR leaves an edge
  incomplete, file the debt before the PR merges — the handover skill
  exists for exactly this moment.
- **CI is the truth gate.** `.github/workflows/validate.yml` checks the
  manifest, skill frontmatter, README maturity claims, pollen schema,
  and constraints drift. Green is a merge precondition.
- **Nothing invented ships.** Pollen records and worked examples must
  abstract something that actually worked somewhere, with provenance.
  This is enforced culturally and in review, not just in CI.

The repo's dialect (labels, lanes, modules) is recorded in
[docs/tracking-dialect.md](docs/tracking-dialect.md). The five
principles live in [reference/principles.md](reference/principles.md).

By contributing you agree your contributions are licensed under the
repo's licence map ([LICENSE](LICENSE)): CC BY 4.0 for prose,
Apache-2.0 for scripts and CI — inbound the same as outbound.
