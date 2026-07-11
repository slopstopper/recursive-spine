---
id: pollen-dialect-note-as-config
form: pattern
source: slopstopper/recursive-spine#19
captured: 2026-07-10
stage: seedling
transplants: []
---

## What worked

Skills stay owner/config-neutral **text**; installation-specific data
(board owner, repo set, hive locations) lives in the invoking repo's
dialect note (`docs/tracking-dialect.md` or equivalent) as **data**. A
skill reads the dialect note at run time instead of hardcoding an
account, org, or repo list.

## Why it worked

PR [#19](https://github.com/slopstopper/recursive-spine/pull/19) found
that `skills/bootstrap/SKILL.md` and `skills/digest/SKILL.md` hardcoded
`--owner effythealien` and the founding four-repo set directly into
portable skill instructions. Running bootstrap or digest against
someone else's repo would silently target the author's personal board —
a config leak baked into supposedly-generic instructions. The fix moved
board owner/number and the repo set out of skill text and into the
dialect note: bootstrap now asks (on first stamp) which account/org owns
the board and records the answer there; digest reads owner/number from
that recorded context and falls back to the repo set documented there,
describing any four-repo default as *this installation's* documented
default rather than a hardcoded list.

The same shape reappeared while building pollination itself (this
branch): `skills/recursive-spine-pollinate/SKILL.md` never names a hive
repo — it interviews for hive repos and visibility, then requires the
answers be written to the dialect note (`## pollinate: hives` section)
before proceeding, exactly mirroring the board-owner interview added in
#19. Two independent skills converged on the same fix for the same class
of bug, which is what makes this a pattern rather than a one-off patch.

## How to transplant

1. Identify any skill instruction that names a specific owner, org, repo,
   label set, or other installation-specific value directly in its
   `SKILL.md` prose.
2. Replace the hardcoded value with an instruction to read it from the
   target repo's dialect note (or equivalent tracked-config doc); if
   the note doesn't have the section yet, interview once and write the
   answer there before proceeding — never assume a default silently.
3. Keep the skill's own text owner-neutral: it should read the same
   whether it's stamped against this installation or a stranger's repo.
4. If a skill ships an installation's own default value (e.g. "the
   founder's four-repo set"), document that default as *this
   installation's documented default*, recorded as data in the dialect
   note, not as an assumption embedded in skill text meant to be portable.

## Nuance on visibility routing (honest note)

Per the skill's capture-mode step 2, proof visibility should route the
pollen to a hive of matching visibility: `gh repo view
slopstopper/recursive-spine --json visibility` returns `PRIVATE` — this
repo is private by owner decision (issue #10). Strictly followed, this
pollen (private-proof) should go to a private hive, and none exists yet
(tracked as [#40](https://github.com/slopstopper/recursive-spine/issues/40)).

This capture is filed into `pollen/` in this same repo anyway, because
the proof source *is* this repo's own registry-in-progress — the
recursion case the skill's dialect note already calls out ("this repo
configures itself first"). `docs/tracking-dialect.md` labels this
directory the installation's "public hive" (for pollen whose proof is
public), which read at first like a mismatch: the repo's GitHub
visibility is PRIVATE while issue #10's flip is pending. That tension is
now resolved by owner decision, codified in `docs/tracking-dialect.md`'s
"pollinate: hives" section: the public hive is scoped to the slopstopper
ecosystem (recursive-spine, plumb-line, tokenomics), not to this repo's
current GitHub setting — "public" names the scope, not the visibility
flag. This pollen's proof (slopstopper/recursive-spine#19) is
slopstopper-scope, so it routes here correctly regardless of #10's
status. The loud-degrade rule in that section applies only to
personal/private-scope proofs (the #40 hive's scope), which this is not.
