---
name: migrate
description: Use when converting a repo's existing prose work-ledgers (status files, queue tables, gap/debt registers, follow-up files, deferral tails) into GitHub issues and milestones under the recursive-spine convention. Dry-run by default — inventories and proposes, writes nothing. Live mode files issues with back-links and produces a retirement checklist; never deletes history, never migrates closed work.
---

# recursive-spine: migrate

Default mode is DRY-RUN. Live mode only when the user explicitly says so,
and only after they have reviewed a dry-run report.

## Dry-run mode

1. **Inventory.** Find every prose artifact holding live work state: status
   files, playbook queue tables, gap/debt registers, follow-up files,
   "outstanding" sections, TODO tails in docs. Ask the user to confirm the
   list and name anything missed. Read each one fully.
2. **Classify every row** as one of: open work item / open gap / open debt /
   open deferral / closed-or-shipped (NOT migrated — git and archives remain
   the record for the past) / not-work-state (method text that stays).
3. **Propose the mapping** as a table: source (file + section) → proposed
   issue title, labels, milestone (existing or proposed-new with its
   narrative description), and the back-link line that will go in the issue
   body. Sliced in-flight work maps to a milestone with slice issues.
4. **Honest denominator.** End the report with: files read in full, files
   skipped (and why), rows classified vs. rows total per file. Never imply a
   complete sweep you didn't do.
5. Write the report to a file the user names (default
   `migrate-dry-run.md` in the repo's plan/docs area) and STOP. Writes to
   GitHub in dry-run mode are a violation of this skill.

## Live mode

Preconditions: dry-run report reviewed by the user; repo already stamped by
`bootstrap` (labels exist).

1. File each approved mapping row via `gh issue create` / `gh api` for
   milestones. Every issue body starts with
   `Migrated from: <file>#<section> (<commit-ish>)`. Nothing is filed
   without a back-link.
2. Every dry-run row must land as: filed issue (record the number in the
   mapping table) OR an explicit won't-file decision with a one-line reason.
   No silent drops — the completed table goes in the migration PR
   description.
3. Produce a **retirement checklist** for the prose artifacts (archive
   location, terminal-header text pointing at the replacement queries,
   deletion step) — but DO NOT execute retirement; that belongs to the
   repo's own cutover plan with its owner checkpoint.
4. Never delete or rewrite source documents. Never file issues for
   closed/shipped rows. Never touch runtime code.
