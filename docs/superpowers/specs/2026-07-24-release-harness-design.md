# Release harness — design

**Date:** 2026-07-24
**Scope:** recursive-spine release automation; captured as pollen for the family
**Lane:** small · **Target:** v0.12.0

## Intent

This session cut five releases by hand (v0.10.1 → v0.11.1): bump `plugin.json`,
`git tag`, `gh release create`, and `git tag -f v1`, every time. That's
error-prone (tags drifted behind the manifest twice) and doesn't scale to the
family. Automate it: a version bump, merged, becomes a complete release with no
manual steps. The slopstopper website already pulls GitHub Releases via the API,
so well-formed releases are all it needs — no website coupling.

## Flow

On push to `main` touching `.claude-plugin/plugin.json`:

1. **Read + guard** — parse `.version` from `plugin.json`; verify it is valid
   semver; if a tag `v<version>` already exists, **no-op** (idempotent — never
   re-cuts the hand-made past releases).
2. **Gate** — run the full check suite (manifest JSON validity + every
   `scripts/test-*.sh`). A release must never pass a narrower gate than a PR.
3. **Release** — create tag `v<version>` and a GitHub release with
   auto-generated notes (PRs since the last release), title
   `recursive-spine v<version>`. Idempotent (skip if the release exists).
4. **Advance `loop@v1`** — force-move the moving major tag to the release commit
   so `uses: slopstopper/recursive-spine/loop@v1` always points at the latest —
   automating the by-hand step.

## Components

- **`.github/workflows/release.yml`** — the workflow above.
  `permissions: contents: write`; third-party actions pinned by SHA (family
  convention, per plumb-line's release.yml). Trigger:
  `on: push: { branches: [main], paths: [".claude-plugin/plugin.json"] }`.
- **`scripts/check-release-version.sh`** — the guard, factored out and testable:
  reads `plugin.json` `.version`, asserts semver, and exits non-zero (with a
  loud reason) if the version is malformed. Prints the version on success. The
  tag-exists idempotency check stays in the workflow (needs `gh`/network).
- **`scripts/test-check-release-version.sh`** — offline test: valid semver
  passes and echoes the version; malformed (e.g. `1.2`, `v1.2.3`, empty) fails
  non-zero.
- **`docs/RELEASING.md`** — the standardized human process: *bump
  `plugin.json` in a PR, merge — the release fires itself; never tag by hand.
  Yanking = delete the release + tag manually (rare).* Documents the guard,
  the gate, and the `loop@v1` behavior.

## Reusability / pollen

After it is proven live, capture the pattern: *a repo's release fires
automatically when its manifest version changes on `main`, gated by the full
suite, producing a GitHub release (the durable, website-consumable record) and
advancing any moving major tag — no manual tagging.* Family variant to record:
package-publishers (plumb-line) stay **tag-triggered** with a human gate before
the irreversible npm/PyPI publish; plugin/docs repos (recursive-spine,
tokenomics) use **auto-on-bump**. The workflow file is per-repo (manifest path,
major-tag name); the pattern is the pollen. Transplanting to plumb-line /
tokenomics is a separate pull-mode act, not this build.

## Testing

- `check-release-version.sh` has an offline unit test (semver accept/reject).
- **Dogfood:** the v0.12.0 bump that ships this harness is itself the first
  auto-release — verified end-to-end (tag cut, release created with notes,
  `loop@v1` advanced, no manual step).
- Idempotency: a second push to `main` that doesn't change the version must
  not fire (path filter) — and if it did, the tag-exists guard no-ops.

## Constraints held

- Never re-cut an existing tag (idempotent).
- Release gate ⊇ PR gate (no weaker checks at release).
- Third-party actions SHA-pinned; least-privilege permissions.
- Config-neutral where reasonable, though the workflow is inherently
  repo-specific (manifest path, `loop@v1` name) — the *pattern* is what
  generalizes.

## Out of scope

The website itself (pulls releases, no coupling needed); applying the harness
to plumb-line/tokenomics (pollen transplant later); Slack onboarding (the
agreed next task); a curated CHANGELOG (auto-notes chosen for the low-friction
auto flow).
