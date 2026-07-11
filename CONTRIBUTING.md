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

This file carries a real, checked copy of the global constraints —
proof the gate protects something, not just a documented format:

<!-- constraints-copy: docs/constraints.md @ 3522737e47e37786a5e40830297efb3f38feac90 -->
<!-- constraints:begin -->
- Nothing invented ships: worked examples, pollen, and frames are structure-faithful abstractions of real use.
- Kin wiring (plumb-line, tokenomics) is data in the dialect note, never skill text; offers, never requirements.
- Every skill's `description:` frontmatter opens with its moment of use.
- Skill names are self-prefixed: `recursive-spine-<name>`.
- GitHub Actions checkout stays pinned to `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5`.
- README status claims carry honest denominators; the maturity gate bans "battle-tested" and "production-ready".
<!-- constraints:end -->

- **Nothing invented ships.** Pollen records and worked examples must
  abstract something that actually worked somewhere, with provenance.
  This is enforced culturally and in review, not just in CI.

The repo's dialect (labels, lanes, modules) is recorded in
[docs/tracking-dialect.md](docs/tracking-dialect.md). The five
principles live in [reference/principles.md](reference/principles.md).

By contributing you agree your contributions are licensed under the
repo's licence map ([LICENSE](LICENSE)): CC BY 4.0 for prose,
Apache-2.0 for scripts and CI — inbound the same as outbound.
