# Architecture decision records

One file per decision, numbered `NNNN-<slug>.md`, append-only.

- Numbering is sequential and never reused.
- A recorded ADR is immutable: to change course, write a new ADR and mark
  the old one `superseded by ADR-<NNNN>`. Never edit a decision into
  something it wasn't.
- An ADR records a *real* decision that was actually taken — backfilled
  examples must be real history, never invented demos.
