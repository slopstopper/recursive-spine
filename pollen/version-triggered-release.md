---
id: pollen-version-triggered-release
form: pattern
source: slopstopper/recursive-spine#109
captured: 2026-07-24
stage: seedling
transplants: []
---

# Version-triggered release harness

A repo's release fires automatically when its manifest version changes on the
main branch — no manual tagging. Bump the version in a PR, merge, and a
workflow cuts the tag + GitHub release (auto-generated notes) and advances any
moving major tag. A releases-pulling website updates itself for free.

## What worked

recursive-spine ([#109](https://github.com/slopstopper/recursive-spine/pull/109),
v0.12.0) replaced a session's worth of by-hand releases (bump `plugin.json` →
`git tag` → `gh release create` → `git tag -f v1`, which drifted behind the
manifest twice) with a `release.yml` that triggers on pushes to `main` touching
the version manifest. It reads the version, no-ops if the tag already exists
(idempotent), gates on the full test suite (a release must never pass a narrower
gate than a PR), creates the tag + release with auto notes, and force-advances
the moving major tag (`loop@v1`) to the release commit. Verified by dogfood: the
PR that shipped the harness bumped the version, and its own merge auto-created
v0.12.0 — the newly-added workflow firing on its own adding commit.

## Why it worked

Releases are a recurring, mechanical ceremony that humans do inconsistently —
the drift (tags behind the manifest) is the tell. Anchoring the trigger to the
one file that must change for a release (the version manifest) makes the release
a *consequence* of the version bump, not a separate remembered step. Idempotency
(no-op if released) makes it safe to re-run and safe against unrelated pushes.
Gating on the full suite closes the "release passes a weaker check than a PR"
gap.

## How to transplant it

1. **Pick the trigger by irreversibility.** Non-publishing repos (plugins,
   docs, sites): auto-on-bump — `on: push: { branches: [main], paths:
   [<version-manifest>] }`. Repos that publish to an irreversible registry
   (npm/PyPI): stay **tag-triggered** with a human gate before publish — same
   guard+gate+release shape, but a human pushes the tag (see plumb-line's
   `release.yml`).
2. **Guard:** read + validate the manifest version; no-op if the tag already
   exists (check both the release and the git ref).
3. **Gate:** run the repo's full test suite — no narrower than a PR's.
4. **Release:** `gh release create v<version> --generate-notes` — the durable,
   API-pullable record a website consumes with no coupling.
5. **Advance any moving major tag** (`@v1`) to the release commit.
6. **Document it** in a `RELEASING.md`: *bump the manifest, merge, never tag by
   hand.*

Per-repo bits (manifest path, major-tag name, publish steps) vary; the shape is
the pattern.
