---
id: pollen-moment-based-skill-surfacing
form: pattern
source: slopstopper/recursive-spine#32
captured: 2026-07-11
stage: transplanted
transplants: [slopstopper/tokenomics]
---

# Moment-based skill surfacing

Skills must not rely on the builder remembering what to use, when, and
where. The more skills a plugin ships, the less likely anyone thinks to
look for them — so each skill surfaces when its purpose warrants, through
the machinery that is already read at the right moment.

## What worked

Three mechanisms, layered (in live use across the recursive-spine skills;
codified as a requirement in #32's scaffold design):

1. **Moment-tuned descriptions.** A skill's `description` frontmatter is
   its only automatic trigger surface — the model matches it against what
   is happening in the session. Write it to name the *moment* ("Use when
   closing a unit of work…", "Use when something just worked well…"),
   never just the feature.
2. **Cross-skill referral seams.** Each skill offers its neighbor at the
   natural boundary (bootstrap offers method to newcomers; scaffold
   offers bootstrap when tracking is missing; closing a unit asks the
   pollen question via principle 4). One surfaced skill carries the
   builder to the rest.
3. **Stamped surfacing.** Repo files that agents read every session
   (CLAUDE.md/AGENTS.md) carry a *moments map* — one line per
   moment → skill. The repo's own walls do the surfacing, so discovery
   scales with repos stamped instead of degrading as the catalogue grows.

## Why it worked

Discovery-by-memory fails at exactly the moment a skill would help: the
builder is mid-task, not browsing a catalogue. All three mechanisms move
the trigger into artifacts that are *already in front of the model* at the
relevant moment — the session context (1), the currently-running skill
(2), the repo's codex (3).

## How to transplant

For any repo or plugin that ships skills:

- Audit every skill's `description`: does it open with the moment of use?
  Rewrite any that name only the feature.
- At each skill's natural entry/exit boundary, name the sibling skill a
  builder would want next — offer, never require.
- If the target ecosystem stamps or owns a rules file read at session
  start, add a moments map section to it (mechanism 3 is design-stage in
  recursive-spine#32 at capture time; mechanisms 1–2 are proven in live
  use across its five shipped skills).

## Transplants

- **slopstopper/tokenomics** (2026-07-23, tokenomics PR
  [#16](https://github.com/slopstopper/tokenomics/pull/16)): the W9
  skills wiring binds surfacing to the v0.4 switchpoint taxonomy —
  mode headings name their moments outright ("Mode A: Route + hand off
  (the Dispatch switchpoint)", "Mode B: Session close (the Close
  switchpoint)"), a Return subsection covers the early-return moment,
  and the method skill's `description` names the four switchpoints.
  Scope note, for honest lineage: tokenomics' descriptions were already
  moment-tuned before this pollen was captured (2026-07-06 vs
  2026-07-11), so mechanism 1's *prose* half is prior art there; what
  transplanted is the named-moment binding — surfacing keyed to a
  formal moment taxonomy. Mechanism 3 (a moments map in session-start
  files) is pending in the receiving repo: its W10 SessionStart hook
  and W11 recursive-spine interop are the natural carriers.
