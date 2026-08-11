---
id: pollen-independent-review-layer
form: pattern
source: slopstopper/plumb-line#213
captured: 2026-08-11
stage: seedling
transplants: []
---

# An independent review layer catches what the author's own tests cannot

Run a **separate** reviewer over each unit of work before it lands — a subagent
with its own context, not the one that wrote the code. Not because the author
was careless, but because tests written by the author encode the author's
assumptions, and the defects that survive are precisely the ones those
assumptions hide.

## What worked

Seven PRs in one session on plumb-line, each written carefully, each green on a
full CI matrix before review. The layers, and what each caught that the previous
one structurally could not:

| Layer | Found |
| --- | --- |
| Unit tests | the cases the author thought of |
| Differential harness (two implementations, same inputs) | a Unicode-digit divergence the shared conformance table missed |
| Adversarial false-positive pass | two *valid* inputs a checker wrongly rejected |
| Mutation (break it, expect red) | a code path with **no observable effect**, so no black-box test could cover it |
| Independent review agent | 9, 5, 4 and 11 findings on four PRs — including two crashes and a validator that printed "conforms" on non-conforming input |

The four reviewed PRs were all believed finished. Three of the four had defects
that would have reached users.

## Why it worked — the part worth transplanting

The reviewer did not merely find *more* bugs. It found a **different kind**.

The author's own harnesses are good at behaviour: differential runs, fuzzing,
mutation. What they cannot see are **claims** —

- a README teaching a `require` path that crashes, in the same file as prose
  about having fixed that crash;
- "proven end-to-end" about two tests that both call the function in-process and
  never touch the shipped CLI path;
- "wired into the onboarding path" for a step that edits a file no other step
  copies;
- a test whose docstring describes a guarantee it does not provide.

A harness checks behaviour against expectations. These are defects *in the
expectations*, so no harness can catch them: the only place they exist is the
artefact stating them, and the only reader who can see them is one who does not
already believe them. That is what an independent context supplies.

## How to transplant it

1. Review **each unit** as it completes, not in a batch at the end. Batching
   loses the correspondence between finding and reasoning, and by then the next
   change is already built on the defect.
2. Give the reviewer an **explicit scope**: a commit range, not "the current
   state". Two runs in this session silently reviewed the working tree instead
   of the intended PR, produced plausible findings about the wrong code, and
   were only caught because the findings named files the target could not
   contain. Verify the target before trusting the output.
3. **Verify every finding before acting.** One review's supporting table
   over-listed which characters diverged; the finding was real, its evidence was
   not. Reviewers are also authors.
4. Feed confirmed findings back as **regression tests**, so the same class
   cannot return quietly.
5. Expect the uncomfortable ones. The most valuable finding of the session was
   that a fix for an overstatement had introduced a *new* overstatement — which
   only an outside reader would phrase that way.

## Caveats

- **Cost is real**: each review consumed comparable tokens to writing the change.
  Worth it per-PR on a correctness-critical repo; probably not per-commit.
- **Requires a host with subagents.** Where that is unavailable the pattern
  degrades to a fresh session with the diff and no memory of writing it — weaker,
  because shared context is exactly what is being removed, but not nothing.
- It does not replace the author's harnesses. Every layer above found something
  the others missed; the review is the outermost, not a substitute.
