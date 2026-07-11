# Vertebra 3: connective tissue — design (#33)

Approved in brainstorm with the owner, 2026-07-11. Closes the design seam
named in #33's text: tokenomics' handoff-spec owns the down-tier work
spec; this module splits ownership rather than consuming or wrapping it.

## What this vertebra owns — and what it doesn't

Vertebra 3 is **two thin pieces connected by one file**, not a document
generator.

It owns:

1. **The canonical constraints source** — `docs/constraints.md`, the one
   place a project's global constraints are authored.
2. **The handover record** — the structured closing comment posted on an
   issue when a unit of work closes.

It does **not** own spec/plan authoring. Repos using this spine may
already have an authoring flow (superpowers here; anything elsewhere).
Those flows keep producing specs and plans — but they pull their global
constraints block from the canonical source instead of hand-copying it.
The module adds the connective layer and kills the named drift vector
without duplicating an authoring process that already works.

**Kin seam, settled (split ownership):** spine **handover** = a closing
*record* (principle 4: debts filed, pollen question asked, state
pointers). Tokenomics **handoff** = a dispatch *contract* for down-tier
execution. Two documents for two moments; the vocabulary stays unmerged
(as the dialect note already records). The handover template carries a
kin *offer* — "if the next step is down-tier work, tokenomics'
handoff-spec owns that doc" — as data via the dialect note, never a
dependency. Both documents quote `docs/constraints.md`.

## Component 1: `docs/constraints.md` (canonical source)

A small, single-purpose file. The dialect note stays about tracking
config; the codex stays about rules of conduct; this file holds *project
constraints*: version floors, naming and copy rules, platform
requirements, API contracts — exact values.

Shape:

- Opens with a one-line contract comment: canonical source — downstream
  docs copy the block below verbatim.
- One delimited block is the copyable unit:

  ```markdown
  <!-- constraints:begin -->
  - Node >= 20; pnpm, never npm
  - All user-facing copy in sentence case
  - No new runtime dependencies without an ADR
  <!-- constraints:end -->
  ```

- Prose outside the markers (rationale, history) is free-form and never
  checked.

## Component 2: drift gate (copy + provenance + CI)

Downstream docs stay **self-contained** (a subagent or receiving tier
reads one file) by copying the block verbatim, marked with a provenance
line:

```markdown
<!-- constraints-copy: docs/constraints.md @ <commit-sha> -->
```

A checker script, wired into `validate.yml`, finds every
`constraints-copy` marker in the repo and compares the copied block
against the canonical file **at the pinned sha**
(`git show <sha>:docs/constraints.md`), failing CI on any mismatch.

**Why sha-pinning:** it makes the gate historically stable. A spec
written in March stays green forever, because it truthfully copied what
was canonical then. Un-pinned checking would retroactively fail every
merged doc each time constraints evolve — forcing history rewrites, a
worse drift vector than the one being killed.

**Staleness is a digest concern, not a CI failure.** The digest sweep
gains one line-item: constraints copies pinned to superseded shas in
docs belonging to still-open issues, aged the way deferrals age.

Checker failure output names the doc, the pinned sha, and the exact
diff — degrade loudly.

## Component 3: scaffold's fifth part (stamps)

The existing `recursive-spine-scaffold` skill gains a fifth optional
part: **connective tissue** — the constraints file frame plus the
drift-gate CI skeleton. Same contract as the other four parts:

- Offered with a failure-mode pitch (the drift vector: hand-copied
  constraints blocks that rot independently).
- Interview fills the builder's actual constraints — frames are
  structure; nothing invented ships.
- Diff before write; idempotent re-runs; declines recorded in the
  dialect note.

## Component 4: `recursive-spine-handover` (seventh skill)

Owns the recurring closing moment. When a unit of work closes (issue
closing, PR merging, session ending with work complete), the skill
assembles, **previews** (diff-first ethos: show before posting), and
posts a structured closing comment **on the issue** — not a file;
principle 1 says state lives where it's queryable, and a
`docs/handovers/` directory would be a prose ledger.

Comment template:

```markdown
## Handover — closing #N
**Debts filed:** #A (what), #B (what) — or "none; checked <how>"
**Pollen:** captured <slug> / "nothing proved itself this unit; checked"
**State:** branch, PR, key commits
**Constraints at close:** docs/constraints.md @ <sha>
**Down-tier next?** → tokenomics handoff-spec owns that doc (offer, per dialect note)
```

Rules:

- The pollen question uses **principle 4's exact wording** — worded
  once, per the pollination design (its committed requirement on this
  vertebra).
- Honest denominators: "none" always says how it was checked.
- No constraints file → offer scaffold's fifth part and omit the
  constraints line; never invent one.
- No `gh` auth → print the finished comment for manual posting.
- The down-tier line appears as an offer only; whether tokenomics is
  wired is read from the dialect note (data, never skill-text
  dependency).

## Surfacing (all three mechanisms, per the moment-based-skill-surfacing pollen)

1. **Moment-tuned description.** The handover skill's `description`
   opens with the moment: "Use when closing a unit of work: an issue is
   about to close, a PR is about to merge, a session is ending with work
   complete." Scaffold's fifth part surfaces through scaffold's existing
   offer walk — no new description needed.
2. **Referral seams.** Method's principle-4 text points to the handover
   skill at the closing moment; the handover skill's pollen question
   refers to pollinate; scaffold's Report gains "when your first unit of
   work closes, `recursive-spine-handover` assembles the closing
   record"; digest's stale-pin line names the handover skill.
3. **Stamped surfacing.** The codex frame's moments map gains one line —
   "closing a unit of work → recursive-spine-handover" — and this repo's
   own CLAUDE.md moments map gets the same line (it currently routes the
   closing moment at pollinate/principle 4 only).

## Packaging

- Plugin v0.6.0; seven skills; `.claude-plugin/plugin.json` and
  `marketplace.json` updated; keywords gain handover/constraints terms.
- README recounted honestly. "Four of four vertebrae shipped" becomes
  true only when this lands; skill denominators are **recalculated at
  write time, not assumed**.

## README full-pass refresh (owner request, this unit)

Beyond the mechanical recount, the README gets a freshness run-through:

- Every status claim re-verified against the record at write time (issue
  states, board facts, pending ops debts) — stale claims fixed or
  removed, not hedged.
- The vertebra list restored to a consistent shape: presented in spine
  order (1–4) with per-vertebra one-liners in parallel form, build-order
  history condensed to a single note rather than interleaved.
- The skill walk updated to seven skills, each introduced at the moment
  it serves (matching the surfacing pollen), not as a flat feature list.
- Structure held: identity → status (honest denominator) → recursion →
  principles → install → tracking → kin. Anything that has drifted out
  of that shape moves back or gets cut.
- The maturity CI gate must still pass; no claim strengthens without a
  record to point to.

## Recursion test (against this repo; honest declines allowed)

- **Constraints file:** interview run against this repo's own record.
  This repo's stated rules (state lives where queryable; honest
  denominators; offers-never-requirements; nothing invented ships) may
  turn out to be rules of conduct (codex material) rather than project
  constraints. The honest outcome may be a minimal constraints file or a
  recorded decline — the test is that the answer is truthful, not that
  every part stamps.
- **Drift gate:** checker wired into `validate.yml`, running on this
  repo's real docs from day one.
- **First live handover comment closes #33 itself.** The vertebra's own
  closing issue receives the vertebra's own closing record — the
  module's first act is recording its own completion.
- **Dialect note:** gains a "handover (this installation)" section
  recording the interview, including any declines.

## Acceptance criteria

1. `docs/constraints.md` frame exists in `reference/templates/scaffold/`;
   scaffold offers it as the fifth part with pitch, interview, diff,
   decline path.
2. The drift checker exists, is wired into `validate.yml`, and fails on
   a deliberately drifted copy (verified in the recursion test), passing
   on the repo's real docs.
3. `skills/recursive-spine-handover/SKILL.md` ships with the
   moment-tuned description, the comment template above, the pollen
   question in principle 4's wording, and every degrade path listed.
4. All referral seams and both moments-map lines are in place.
5. Plugin v0.6.0 packaging valid (CI manifest check green); seven
   skills listed in both manifests.
6. README refreshed per the full-pass section; maturity gate green.
7. Recursion test recorded in the dialect note; #33 closed with the
   first live handover comment.

## Out of scope

- Spec/plan authoring or generation (owned by whatever flow the builder
  uses).
- The tokenomics handoff-spec document itself (kin-owned; offered, never
  produced here).
- Push distribution of constraints to other repos (#38 territory).
- Retroactively adding provenance markers to already-merged historical
  docs.
