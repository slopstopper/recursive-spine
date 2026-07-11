# Vertebra 2: Scaffold — design

**Date:** 2026-07-11
**Issue:** #32 (milestone: The whole spine)
**Status:** approved design, pre-implementation

## Purpose

Bootstrap stamps tracking — the first vertebra. The scaffold stamps
everything else a project needs to survive infancy: a rules codex, an ADR
directory, a CI gate skeleton, and a session-memory convention. It is the
second vertebra of the portable project spine, and the first consumer of
the pollen registry: where a configured hive holds proven content for a
part, the scaffold offers it instead of inventing anything.

## Decisions made at design time

- **Sibling skill, not grown bootstrap.** New skill
  `recursive-spine-scaffold`. Bootstrap stays small and proven; the
  dependency points at the proven thing: scaffold's preflight checks for a
  dialect note and *offers* to run bootstrap first when tracking is not
  stamped. Scaffold never re-implements tracking.
- **Content = frames + interview + pollen.** The skill ships only neutral
  structural frames (file shapes, named empty sections). The interview
  fills in the builder's actual discipline. Configured hives supply proven
  fillings where they have them. Nothing invented ships; structure ships.
  This extends the house rule that killed shipped defaults for lanes
  (#22) and hives (#43).
- **Two seed pollen records ship with this vertebra** (owner-approved), so
  first-run offers are real:
  - `truth-gate-ci` — the grep/jq CI gates that ban stale claims and
    enforce schemas. Proof: this repo's `validate.yml` and tokenomics'
    `gates.yml`. slopstopper scope → this hive, plain capture.
  - `layered-session-memory` — the now/today/recent/archive layered memory
    convention with rotation rules. Proof: the owner's live session
    environment — enters as a **declassified** record per the routing rule
    in `docs/tracking-dialect.md`: structure-faithful layout only,
    scrubbed provenance ("proven in the builder's live session
    environment"), no personal content.
- **Every part is optional; declines are recorded.** The interview offers
  each part with a one-line failure-mode pitch; a decline lands in the
  dialect note (same convention as kin offers). "Already present" is a
  valid, recorded answer.

## The four parts

Each part follows the same cycle: **offer → interview → pollen check →
stamp (diff shown first) → record in dialect note.**

1. **Rules codex.** Frame: a CLAUDE.md or AGENTS.md outline with named
   empty sections — mission, house rules, tracking (bootstrap's existing
   tracking section slots in here unchanged), session memory, CI. The
   interview asks for the builder's actual rules per section; empty
   sections are omitted, not filled with boilerplate. If a codex already
   exists, show a merged proposal — never overwrite silently (bootstrap's
   rule, reused verbatim).
2. **ADR directory.** Frame: `docs/adr/NNNN-<slug>.md` with
   Status / Context / Decision / Consequences headings, plus a one-page
   `docs/adr/README.md` stating the numbering and immutability rule
   (superseded, never edited). Interview asks: location (offer the repo's
   existing docs convention), and whether to backfill ADR-0001 from a
   *real* recent decision. An invented example ADR is banned by the
   recursion doctrine.
3. **CI gate skeleton.** Frame: a `.github/workflows/` workflow shell with
   named, empty gate steps and a fail-loud exit pattern. The interview
   applies tokenomics' routing test to select gates: *"which invariants,
   if silently broken, would be expensive?"* Pollen offer: `truth-gate-ci`.
   If the plumb-line plugin is installed, offer its guard wiring for the
   gates — offer only, never required.
4. **Session-memory convention.** Frame: a short convention doc naming
   where memory lives, its layers, and rotation rules. Pollen offer:
   `layered-session-memory`. Deliberately a convention *doc*, not tooling
   installation — harness-specific tooling would cut against cross-model
   portability (#46).

## Pollen consumption (the day-one seam)

For each accepted part, the scaffold reads the hives configured in the
target repo's dialect note (`pollinate:` section; if none is configured,
it runs the pollinate skill's hive interview or proceeds pollen-less with
a loud note — never a shipped default hive). It matches records by `form`
and part relevance and offers them. An acceptance **is a transplant** and
is recorded through the pollinate skill's existing pull-mode procedure —
comment on the pollen issue plus `transplants:` append. One canonical
recording path; the scaffold implements no second one.

## Kin boundaries

Same contract as bootstrap: plumb-line guard wiring and tokenomics
playbook pointers are offers, never requirements. All wiring answers land
in the dialect note as data; no skill text names a dependency.

## Recursion test (acceptance criteria)

- The skill exists, self-prefixed, in the plugin manifest (sixth skill,
  v0.5.0), passing manifest + frontmatter CI.
- Both seed pollen records exist, pass the pollen front-matter CI check,
  and have paired `pollen`-labeled issues.
- **First target is this repo, answering the interview honestly:**
  - ADR directory: expected accept — ADR-0001 backfills today's real
    "sibling skill vs. grow bootstrap" decision (this spec is its source).
  - Rules codex: interview runs for real; accept or decline per the
    owner's answer at execution time.
  - CI gates: decline as already present (`validate.yml`), recorded.
  - Session memory: decline (repo-level memory not in use here), recorded.
  - No fake transplants: this repo is the source of both seed pollen, so
    "already present" is the truthful pull-mode answer here. First real
    transplants remain deferred work (#42).
- The dialect note gains a `## scaffold` section recording every answer,
  including declines.
- README flips vertebra 2 to shipped only after the recursion test has
  actually run.

## Out of scope

- Push distribution of scaffold parts (#38, deferred).
- Any harness-specific memory tooling (#46 direction).
- Vertebra 3's generated spec/plan/handover docs (#33) — the codex frame
  leaves no slot for them; #33 adds its own seam when built.

## Testing

Dry-run first, per house convention: the full interview runs and the
generated files are shown without writing. CI additions: none beyond the
existing frontmatter/manifest checks picking up the sixth skill; the two
pollen records are covered by the existing pollen schema gate.
