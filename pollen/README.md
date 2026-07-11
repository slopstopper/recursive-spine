# The pollen registry

Captured, transplantable learnings — each proven in real use before it was
filed (invented demo pollen is banned by the recursion doctrine). Records
are written by the `recursive-spine-pollinate` skill; this directory is
the **public-scope hive** for this installation. Private-proof pollen
lives in a private hive and never appears here — every reference in this
directory must resolve for every reader.

## Record schema

One file per pollen: `pollen/<slug>.md`. Artifact files (a CI gate, a
hook, a template) live alongside in `pollen/<slug>/` and the record links
them.

    ---
    id: pollen-<slug>            # stable identifier, matches filename
    form: snippet | pattern | skill-candidate | config
    source: owner/repo#N         # repo + issue/PR where it proved itself
    captured: YYYY-MM-DD
    stage: seedling | transplanted | graduated
    transplants: []              # repos it took root in, appended over time
    ---

Body: what worked, why it worked, how to transplant it.

## Lifecycle

- **seedling** — captured, never transplanted. The digest ages these.
- **transplanted** — took root in ≥1 other project (recorded in
  `transplants:` and as a comment on the paired `pollen` issue).
- **graduated** — ≥2 transplants and promoted to a real skill, in
  whichever kin repo owns the concern (epistemic honesty → plumb-line,
  model economics → tokenomics, tracking/scaffold → here). The paired
  issue closes on graduation or retirement.

Every record is paired with a `pollen`-labeled issue in this repo — the
queryable half, per principle 1.
