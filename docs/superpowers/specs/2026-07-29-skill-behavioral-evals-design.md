# Skill behavioral evals — design

**Date:** 2026-07-29
**Scope:** recursive-spine #68; unblocks #87 · milestone *The spine watches itself*
**Lane:** flagship · **First cut:** two-skill pilot (handover, digest)

## Intent

The skills are prose. A model reads `SKILL.md` and does what it says, so the
document *is* the program — but nothing verifies it. `validate.yml` checks that
frontmatter exists, that pollen records carry their enums, and that constraints
copies match their pinned sha. Everything below a skill's frontmatter — every
degrade path, ordering rule, and Never — runs on trust.

#68 names the failure: *a prose edit that reorders a degrade path or drops a
Never rule sails through green.* Concretely, `recursive-spine-handover` today
says "Show the finished comment and get approval **before** posting". A tidy-up
that rewrote this as "Post the comment, showing it to the builder" reads fine,
passes every existing gate, and ships a skill that writes to a public tracker
unreviewed.

This is the truth-gate ethos applied to the one layer that has never had one.

## Two tiers, at two cadences

**Tier 1 — static assertions.** Anchored claims about the prose: a rule's text
must exist, and rules must appear in the required order. No model, no network,
no secrets. Runs on every PR because it is free and deterministic.

**Tier 2 — behavioral scenarios.** A real model runs the skill against a fixture
and the harness asserts on what it *did*. Costs tokens and varies between runs,
so it fires only at named moments — release, milestone close, manual dispatch.
Heavy machinery at named moments, never continuously (the pattern under #108).

## Drift: why assertions are anchored

An eval file that restates a skill's rules is a second copy of live state in
prose — the failure principle 1 retires. Two copies drift, and the eval then
certifies a rule that no longer exists while reporting green.

The counter is the **anchor**: every assertion names a fragment of text that must
still be present in the `SKILL.md`. If a rewrite removes it, the assertion does
not quietly pass — it reports `UNRESOLVED` and fails the build. Drift remains
possible; silent drift does not.

Assertions live in `evals/*.json` rather than as inline markers in `SKILL.md`,
because the skills ship to users' plugin caches and their prose should stay
clean. The cost of that choice is exactly the drift risk above, which the anchor
mechanism converts into a loud failure.

Anchor matching normalizes whitespace and case before searching. The skills are
hard-wrapped at ~72 columns, so most interesting rules span a line break; a
naive substring match would report every multi-line rule as `UNRESOLVED` on day
one. The matcher is one line — `tr '\n' ' ' | tr -s ' ' | grep -qi` — and was
verified against all eleven pilot anchors before this spec was written.

## Assertion format

Two kinds, each mapping to a failure class #68 names:

| kind | asserts | guards against |
|---|---|---|
| `contains` | anchor text is present | a dropped Never rule |
| `precedes` | anchor A appears before anchor B | a reordered degrade path |

A third kind, `forbids` (a phrase must not appear), is **deliberately cut from
the pilot**: the phrases worth forbidding legitimately appear in the skills as
named anti-patterns, so it needs a negation heuristic that is too fragile to be
load-bearing in a harness whose only asset is credibility. Filed as a debt, not
forgotten.

Every assertion carries a `why`. When an anchor goes `UNRESOLVED` a year from
now, the `why` is what tells the next reader whether to re-anchor the assertion
or conclude the rule was deliberately dropped. Without it the cheapest fix is
always "delete the failing assertion", and the gate erodes to nothing.

```json
{
  "skill": "recursive-spine-handover",
  "assertions": [
    { "id": "approval-precedes-post",
      "kind": "precedes",
      "anchor": "get approval",
      "before": "gh issue comment",
      "why": "diff-first; the skill must never post unreviewed to a public tracker" },

    { "id": "record-is-comment-never-file",
      "kind": "contains",
      "anchor": "never a file",
      "why": "principle 1 — a docs/handovers/ directory would be a prose ledger" },

    { "id": "debts-precede-close",
      "kind": "precedes",
      "anchor": "becomes an issue",
      "before": "closing comment is posted",
      "why": "principle 4 — the ordering IS the principle" }
  ],
  "scenarios": [ ... ]
}
```

## Scenarios and the call log

Every skill reaches GitHub through `gh`, in machine-readable mode. So the
behavioral tier stubs `gh` and asserts on the recorded call sequence — facts
about what the skill did, not judgments about how it phrased itself. That is
what makes a model-driven test nearly deterministic: the wording varies between
runs, the order of actions does not.

The git repo in a fixture is **real** (`git init` in a temp dir, real commits,
a real `<prefix>/<issue>-<slug>` branch). Only `gh` is stubbed, because `gh` is
the only part that talks to a server.

```json
"scenarios": [
  { "id": "handover-refuses-untracked-work",
    "fixture": "handover-no-issue",
    "invoke": "recursive-spine-handover",
    "expect_calls":  [ { "matches": "issue list", "present": true } ],
    "expect_absent": [ "issue comment", "issue create" ],
    "judge_note": "should offer bootstrap, and say why it stopped",
    "why": "a unit without an issue was never tracked — must stop, not improvise" },

  { "id": "handover-files-debts-before-posting",
    "fixture": "handover-two-debts",
    "invoke": "recursive-spine-handover",
    "expect_order": [ "issue create", "issue create", "issue comment" ],
    "judge_note": "closing comment should cite both debts by number",
    "why": "principle 4 in executable form" }
]
```

**Approval gates.** `handover` requires human approval before posting. The
fixture supplies scripted answers (`"approvals": ["yes"]`), and at least one
scenario answers `"no"` to assert the skill does *not* post.

**Pass criterion.** Call-log assertions gate: they alone set exit status. A
judge model reads the transcript and reports on qualities a call log cannot see
— whether a degrade was announced *loudly*, whether a report reads as a briefing
— and its verdict is **advisory only, never gating**. The judge's own
instructions are untested prose; letting untested prose fail a build would
reproduce the problem this project exists to solve.

That advisory tier is what makes `digest` testable at all: "recursive-spine is
in its own sweep" is a visible call, but "reports honest denominators" and #87's
indented-aging-child are properties of the report's *shape*, which is text.

## No new GitHub repos

Nothing here creates, writes to, or touches any repo on GitHub. The behavioral
tier runs in a temp directory and `fake-gh` opens no network connection. Tier 2
needs a model credential and nothing else — no `GITHUB_TOKEN` write scope.

A disposable throwaway repo was considered as a higher-fidelity alternative and
rejected **for the pilot**, on merits: it would need a write-scoped token, add
minutes per run, orphan repos when a run dies, and still could not simulate the
failure paths (missing scopes, attachment failure) that are a large share of
what #68 guards. It is not ruled out permanently; if fixture drift becomes real,
that door reopens.

The accepted risk is that canned responses drift from what `gh` actually
returns. Filed as a debt.

## Components

Following the established `scripts/<name>.sh` + `scripts/test-<name>.sh`
convention (seven such pairs already), bash throughout, `jq` for JSON — the same
tools `validate.yml` already depends on. No new runtime dependency.

- **`scripts/spine-eval.sh`** — tier 1. Reads `evals/*.json`, resolves each
  anchor against the matching `SKILL.md`, checks `contains`/`precedes`. Exits
  non-zero on `FAIL` or `UNRESOLVED`. `--coverage --min-covered N` runs the
  ratchet instead.
- **`scripts/spine-eval-behavior.sh`** — tier 2. Builds the fixture, puts the
  stub first on `PATH`, invokes the skill, asserts on the call log, collects
  advisory judge notes.
- **`evals/stub/gh`** — logs every invocation to `$SPINE_EVAL_CALL_LOG`, replays
  canned JSON from the fixture, honours a fixture-declared exit status so
  failure paths are reachable. Named `gh` because it is found by `PATH`.
- **`evals/handover.json`, `evals/digest.json`** — the pilot's assertions and
  scenarios. `digest.json` carries #87's leak scenario.
- **`evals/fixtures/<id>/`** — per scenario: `git/` seed commands, `gh/` canned
  responses, `approvals`.
- **`scripts/test-spine-eval.sh`** — tests the runner itself: a known-good
  skill passes, a doctored copy with an inverted order fails, a doctored copy
  with the anchor deleted reports `UNRESOLVED` and not `FAIL`. The harness is
  prose-adjacent tooling and gets the same treatment it imposes.

## CI wiring

Tier 1 joins the existing `validate.yml` as two steps — same class of check
(cheap, always, no secrets), and a separate workflow would fragment the signal:

```yaml
      - name: Skill assertions hold
        run: scripts/spine-eval.sh

      - name: Eval coverage has not regressed
        run: scripts/spine-eval.sh --coverage --min-covered 2
```

`--min-covered 2` is a ratchet, not a target. It does not demand coverage of all
eight skills; it fails if the count *drops*. Raising it later is a deliberate
act visible in a diff.

Tier 2 is a new workflow, `.github/workflows/evals-behavioral.yml`:

```yaml
on:
  workflow_dispatch:
  release:   { types: [published] }
  milestone: { types: [closed] }
```

It fires *on* release rather than gating it: blocking a release on a
nondeterministic run is the flakiness trap the two-tier split exists to avoid.
Third-party actions pinned by sha, per family convention.

## Reporting

```
spine-eval — 2/8 skills covered

recursive-spine-handover        4 assertions
  ✓ approval-precedes-post
  ✓ record-is-comment-never-file
  ✓ debts-precede-close
  ⚠ UNRESOLVED  no-orphan-debt
      anchor:  "never posts one"
      not found in skills/recursive-spine-handover/SKILL.md
      why:     principle 4 — a comment naming an unfiled debt is a violation
      last seen at commit b7af64b

      This is not a test failure. The prose this assertion guards was
      edited or removed. Either re-anchor it to the rule's new wording,
      or — if the rule was dropped on purpose — delete the assertion in
      the same commit and say why in the message.

recursive-spine-digest          6 assertions   all pass

uncovered: bootstrap, method, migrate, nudge, pollinate, scaffold
```

Three deliberate properties:

- **`UNRESOLVED` reads differently from `FAIL`.** One says the skill misbehaves;
  the other says the harness lost its grip on the skill. Collapsing them trains
  the reader to treat both as noise.
- **The `why` prints at the point of failure**, so "was this rule dropped on
  purpose?" is answerable from the CI log alone.
- **The uncovered list always prints, including on success.** A green run
  saying `2/8` cannot be mistaken for one meaning "everything is guarded" — the
  honest-denominator discipline `digest` promises, turned on the harness itself.

`last seen at commit` comes from `git log -S` on the anchor text, which usually
hands the reader the commit that removed the rule.

## Scope and what follows

The pilot covers `handover` (the sharpest ordering and Never rules; it writes to
a public tracker) and `digest` (unblocks #87). The remaining six skills get
sub-issues under #68 — moment-triggered depth: the tree appears because
something real attached beneath it.

Debts to file before #68 closes:

1. `forbids` assertion kind, cut from the pilot as too heuristic.
2. Fixture drift — canned `gh` responses can diverge from real `gh` output.
3. Six uncovered skills, one sub-issue each.
4. Tier 2 reporting to #20 as a comment (needs `issues: write`; prints to the
   job log for now).

## Reusability / pollen

Candidate pattern, to capture only after it proves itself in a real prose edit:
*prose that a model executes is testable — anchor each rule to a fragment of its
own text, and a rewrite that removes the rule fails loudly instead of passing
green.* Portable to any prose-as-program repo: plumb-line's principles,
tokenomics' lanes, any skill collection. Not captured yet; nothing has been
proven.
