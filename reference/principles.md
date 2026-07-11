# The recursive-spine convention

**Status:** current (the principles; the plugin tooling around them is
tracked in the repo's issues) — extracted from live practice in two repos
(plumb-line, Veska Index). Nothing here is speculative; everything here is
in use.

## The recursion doctrine

A tracking convention must survive being applied to the system that defines
it. If a rule is too heavy to follow while building the tool that states the
rule, the rule is wrong. This repo is the first test: its issues and
milestones existed before its first commit, its labels were stamped by its
own bootstrap skill, and its deferrals age on its own digest. Worked examples
in this repo are structure-faithful abstractions of real, in-use tracking —
never invented demos.

## The five principles

1. **Tracked state lives where it is queryable, not where it merges.**
   Work state belongs in issues and milestones; prose files hold thought
   (specs, plans, method), never live state. The failure mode this retires:
   state-as-prose merges as text and loses rows.

2. **A unit of work is an issue; a narrative of work is a milestone.**
   An issue is sized to roughly one working session. When a unit needs
   slicing, promote it to a milestone and file its slices as issues in it.
   Parallel long-running tracks are milestones without due dates; the
   milestone description carries the narrative.

3. **Deferral requires a record.** Nothing is postponed without an issue
   carrying the deferral label. Aging must be measurable, or the deferral
   did not happen.

4. **Handover files its debts before it closes.** A finished unit's
   known-incomplete edges become issues before the unit's issue closes.
   A closing comment that names a debt without a filed issue is a violation.
   Where the pollination module is installed, closing asks the sibling
   question too: any pollen to capture?

5. **Branches and PRs cite the record.** Branch names carry the issue number
   (`<prefix>/<issue>-<slug>`), PRs close it (`Closes #N`), and "what is in
   flight" is a query (`gh issue list --assignee @me`), not a file.

## Modules

The bootstrap stamps the mandatory module and offers the rest; repos choose.

- **Deferral label (mandatory)** — default `deferred`; a repo may alias it
  (plumb-line uses `audit-deferral`). Required by principle 3.
- **Gap module** — `gap` label for findings from periodic assessments; work
  issues cite the gaps they close.
- **Debt module** — `inherited-debt` label; handover debts are filed against
  the *next* unit's milestone.
- **Lane module** — `lane:<tier>` labels carrying model-routing economics
  (see the tokenomics project). Tier names come from the builder's own
  interview answers (or their repo's tokenomics playbook, when one exists) —
  never shipped defaults.
- **Dialect note** — a short in-repo doc naming the repo's local vocabulary
  and how it maps to these principles.
- **Pollination module** — a `pollen` label in the hive repo plus a
  `pollen/` registry: elements that proved themselves in one project,
  captured as records and pulled into others by the
  `recursive-spine-pollinate` skill. The graduation ladder: *seedling*
  (captured, never transplanted — the digest ages these) → *transplanted*
  (took root in ≥1 other project) → *graduated* (≥2 transplants, promoted
  to a real skill in whichever kin repo owns the concern). Hives are the
  builder's own answer, one per visibility scope; private-proof pollen
  never enters a hive whose readers cannot see its source. Capture points:
  in-flow on noticing, at handover (see principle 4's sibling question),
  and retrospective sweep.

## Boundaries

recursive-spine owns *where tracked state lives*. plumb-line owns *whether
claims are honest*. tokenomics owns *which model does the work*. The skills
reference each other only through offers, never requirements.
