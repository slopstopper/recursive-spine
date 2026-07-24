# Releasing recursive-spine

Releases are automatic. **You never tag by hand.**

## To cut a release

1. Bump `"version"` in `.claude-plugin/plugin.json` (strict `X.Y.Z`) in a PR —
   usually the same PR as the change it ships.
2. Merge to `main`.

That's it. On merge, `.github/workflows/release.yml` fires because
`plugin.json` changed, and:

- reads the version and **no-ops if `v<version>` already exists** (so re-runs
  and old versions are safe);
- **gates** on the full suite — manifest validity + every `scripts/test-*.sh`
  (a release never passes a narrower gate than a PR);
- creates tag `v<version>` and a **GitHub release** with auto-generated notes
  (the PRs merged since the last release);
- **advances `loop@v1`** to the release commit, so
  `uses: slopstopper/recursive-spine/loop@v1` always points at the latest.

The slopstopper website pulls these releases via the GitHub API — nothing to
push.

## Notes

- **Idempotent:** merging a change that does *not* touch `plugin.json` does not
  release; a duplicate version no-ops.
- **Yanking** (rare): delete the GitHub release and its tag manually
  (`gh release delete v<x> --cleanup-tag`), and move `loop@v1` back if needed.
- **The pattern is portable** — package-publishing repos (plumb-line) stay
  tag-triggered with a human gate before the irreversible npm/PyPI publish;
  plugin/docs repos use this auto-on-bump flow. See the `release-harness`
  pollen record.
