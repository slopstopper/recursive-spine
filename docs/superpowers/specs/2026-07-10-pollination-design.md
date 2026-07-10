# Vertebra 4: Pollination — design

**Date:** 2026-07-10
**Issue:** #37 (milestone: The whole spine)
**Status:** approved design, pre-implementation

## Purpose

The existing skills move structure *into* projects (bootstrap stamps,
scaffold will stamp more). Pollination is the return path: capture elements
that proved themselves in one project and carry them into others. It is the
feedback loop that makes the spine self-improving rather than merely
self-applied — the missing direction that turns recursive-spine from a
tracking convention into a recursive system.

## Decisions made at design time

- **Pollen unit is polymorphic.** A captured learning takes the form
  appropriate to what it is: a config/code snippet, a pattern record, an
  issue-shaped note, or (after graduation) a full Claude Code skill.
- **Capture is layered.** Three capture points, all producing the same
  record type: in-flow on noticing (primary), at handover/close (safety
  net, extends principle 4), and retrospective sweep (backstop).
- **The hive is this repo.** Pollen records live in recursive-spine;
  graduated skills ship through the marketplace this repo already is.
- **Distribution is pull-on-demand.** Push (sweep-proposed transplants in
  target repos) is deferred: #38.
- **Structured registry from day one.** Records carry machine-readable
  front-matter so future automation needs no migration.

## The pollen record

One capture produces two linked artifacts:

**1. Registry file** at `pollen/<slug>.md`:

```yaml
---
id: pollen-<slug>            # stable identifier
form: snippet | pattern | skill-candidate | config
source: owner/repo#N         # repo + issue/PR where it proved itself
captured: YYYY-MM-DD
stage: seedling | transplanted | graduated
transplants: []              # repos it took root in, appended over time
---
```

Body: what worked, why it worked, and how to transplant it. When the pollen
is an actual file (CI gate, hook, template), the file lives alongside at
`pollen/<slug>/` and the record points to it. Worked examples must be
structure-faithful abstractions of real use — invented demo pollen is
banned by the recursion doctrine.

**2. A `pollen`-labeled issue in this repo** — the queryable half, per
principle 1. The issue links the registry file. Transplant events land as
issue comments *and* as appends to the record's `transplants:` list. The
issue closes only on graduation or retirement (dead pollen).

## The skill: `recursive-spine-pollinate`

One skill, two modes.

**Capture** (invoked in any repo, mid-flow or at handover):

1. Brief interview: what worked, what form is it, where is the proof
   (repo + issue/PR).
2. Dedup check: search the existing registry by keyword; if a near-match
   exists, offer "record a transplant on the existing pollen" instead of
   filing a twin.
3. Open a PR to the hive adding the registry file (and artifact files, if
   any); file the paired `pollen` issue.
4. Target cost: under a minute of the builder's attention.

**Pull** (invoked in any target repo):

1. Read the registry (clone or raw-fetch of `pollen/`).
2. Match records against the current work context; offer relevant
   transplants. Nothing relevant → say so and stop; no forced suggestions.
3. On acceptance: perform the transplant (copy + adapt the artifact, or
   apply the pattern), then record it — comment on the pollen issue,
   append to the record's `transplants:` list.

**Degraded modes:** no `gh` auth or non-repo work → draft the registry file
locally and tell the builder what to file. Registry unreachable → report,
don't guess.

## Graduation ladder (documented, manual in this iteration)

- **seedling** — captured, never transplanted.
- **transplanted** — took root in ≥1 other project.
- **graduated** — ≥2 transplants and promoted to a real skill.

Graduation asks **which kin repo owns the skill**: epistemic-honesty pollen
graduates into plumb-line, model-economics pollen into tokenomics,
tracking/scaffold pollen stays here. The hive stores pollen; graduated
skills go to their rightful home, so recursive-spine does not absorb its
siblings.

## Integration seams (named now, built with their vertebra)

- **Principles:** pollination becomes a documented module in
  `reference/principles.md`, including the graduation rule.
- **Handover discipline:** principle-4 text and the method skill gain the
  sibling question: "any debts to file, any pollen to capture?"
- **Digest:** one extension — surface pollen aging in `seedling` with no
  transplants, the same way it ages deferrals.
- **Vertebra 2 (scaffold, #32):** bootstrap/scaffold offers relevant pollen
  when stamping a repo. Built with vertebra 2, consuming this registry.
- **Vertebra 3 (connective tissue, #33):** the generated handover template
  carries the capture prompt — same seam as the handover discipline above;
  word the question once.
- **Identity (#34):** README + principles rewrite states the four-vertebra
  mission and happens after this design lands, so it names all four
  accurately.

## Build order (approved)

1. Vertebra 4 (this design) — self-contained, and the feedback loop that
   captures learnings from building vertebrae 2 and 3.
2. #34 identity rewrite.
3. Vertebra 2 (scaffold), consuming pollen at bootstrap from day one.
4. Vertebra 3 (connective tissue), carrying the capture prompt.
5. Ops debts (#35 board workflows, #21 digest schedule, #10 visibility) —
   owner-paced, independent.

## Acceptance criteria (the recursion test)

- The skill exists, self-prefixed, packaged in the plugin manifest, passing
  the manifest/frontmatter CI.
- The first real pollen record is captured *from building pollination
  itself* (or from an already-proven element in plumb-line/Veska Index) —
  no invented pollen.
- Pull mode exercised at least once against a real sibling repo, with the
  transplant recorded on the pollen issue and in the record front-matter.
- `reference/principles.md` documents the pollination module and
  graduation ladder.
- Digest sweeps seedling-age. Push distribution remains deferred (#38).

## Testing

Skill-level: dry-run capture (interview → generated record shown, nothing
filed) before live filing, mirroring recursive-spine-migrate's dry-run-first
convention. CI already validates manifest parse + skill frontmatter; the
registry adds a check that every `pollen/*.md` front-matter parses and
carries the required keys.
