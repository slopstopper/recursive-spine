---
name: recursive-spine-pollinate
description: Use when something just proved itself in real work and should be carried to other projects — captures it as a pollen record in the builder's hive (registry file + paired issue), or, in pull mode, reads every configured hive and offers relevant transplants into the current repo, recording each transplant back onto the record. Interview-driven hive config; never ships a default hive; routes private-proof pollen to a private hive only.
---

# recursive-spine: pollinate

Two modes. **Capture** files a proven element into a hive; **pull** brings
hive pollen into the current work. Ask which the user wants if the
invocation doesn't say. Read `${CLAUDE_PLUGIN_ROOT}/pollen/README.md` for
the record schema before writing any record.

## Hive configuration (both modes, first)

Read the invoking repo's dialect note (`docs/tracking-dialect.md` or
equivalent) for a `pollinate:` section listing hive repos and each hive's
visibility. If absent, interview — never assume:

1. "Which repo is your hive (where pollen records live)?" Accept several;
   record each as `owner/repo (public|private)`.
2. If the builder works across public and private projects, recommend one
   hive per visibility scope (the two-hive model): private-proof pollen
   must never enter a hive whose readers can't see its source.
3. Write the answers to the dialect note before proceeding. No default
   hive ships with this skill — the hive is the builder's own answer.

Degraded modes, always loud: no `gh` auth or not in a repo → draft the
record locally, print it, and tell the builder exactly what to file where.
Hive unreachable → report the error and stop; never guess.

## Capture mode

1. **Interview (brief — target under a minute):**
   - What worked? (one sentence)
   - What form is it? `snippet` / `pattern` / `skill-candidate` / `config`
   - Where's the proof? (repo + issue/PR — the `source:` field; the proof
     must exist, per the no-invented-pollen doctrine)
2. **Route by proof visibility:** `gh repo view <source-repo> --json
   visibility`. Private proof → a private hive; public proof → the public
   hive. If no hive of the required visibility is configured, say so and
   offer to add one to the dialect note.
3. **Dedup check:** search the target hive's registry
   (`gh search code --repo <hive> --filename '*.md' <keywords>` or a raw
   fetch of `pollen/`) and its `pollen`-labeled issues
   (`gh issue list -R <hive> --label pollen --search <keywords>`). Near
   match → offer "record a transplant on the existing pollen" instead of
   filing a twin.
4. **File the record:** branch + PR to the hive adding
   `pollen/<slug>.md` per the schema (stage `seedling`, `transplants: []`),
   plus artifact files under `pollen/<slug>/` when the pollen is a file.
   Then file the paired issue in the hive: label `pollen`, title
   `pollen: <slug> — <one-line what-worked>`, body linking the record file
   and the proof. Public hive rule: every reference in record and issue
   must resolve for every reader — if a link would point at a repo the
   hive's readers can't see, the pollen belongs in a private hive (or the
   reference must be abstracted).
5. **Report:** record path, issue URL, stage, and anything skipped and why.

## Pull mode

1. Read `pollen/` from **every** configured hive (clone or raw fetch).
2. Match records against the current work context (the repo's language,
   the task at hand, labels in play). Offer only genuine fits with a
   one-line "why this applies here". Nothing relevant → say so and stop;
   no forced suggestions.
3. On acceptance, perform the transplant: copy and adapt the artifact, or
   apply the pattern. Show the diff before writing.
4. Record the transplant, both halves:
   - append the target repo to the record's `transplants:` list (PR to
     the hive; flip `stage:` to `transplanted` if it was `seedling`);
   - comment on the paired pollen issue: which repo, what was adapted,
     link to the receiving commit/PR.
5. If a record now has ≥2 transplants, note it is graduation-eligible and
   name the kin repo that owns the concern — but graduation is the
   builder's deliberate act, never automatic.

## Declassification (deliberate, never automatic)

To publish a private-hive pollen: re-file it into the public hive with
scrubbed provenance ("proven in a private production app" — no name, no
link), a fresh paired issue, and a note in the private record pointing to
its public sibling. Offer this only when the builder asks.

## What this skill never does

No transplants without approval, no auto-graduation, no default hive, no
private references in a public hive. Pushing "consider adopting X" issues
into target repos is deliberately out of scope: deferred as
recursive-spine#38.
