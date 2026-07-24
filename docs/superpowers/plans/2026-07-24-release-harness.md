# Release Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`). NOTE: local git is currently blocked (macOS Documents-folder permission), so this build commits through the GitHub Contents API to a branch, then PR+merge — the `git` commands below are the logical intent; execute them as API `PUT`s to `feat/release-harness`.

**Goal:** A version bump merged to main auto-cuts the tag + GitHub release (auto-notes) and advances `loop@v1` — no manual release steps; the slopstopper site pulls the releases.

**Architecture:** A `release.yml` workflow triggers on pushes to main that touch `.claude-plugin/plugin.json`; it reads the version, no-ops if already released, gates on the full suite, then creates the release and force-moves `loop@v1`. A small offline-testable guard script validates the version is semver.

**Tech Stack:** GitHub Actions, `gh` CLI, `jq`, POSIX shell.

## Global Constraints

- Idempotent: never re-cut an existing tag/release (guard checks both).
- Release gate ⊇ PR gate — run every `scripts/test-*.sh` plus manifest validity.
- Third-party actions SHA-pinned (family convention); `permissions: contents: write` (least-privilege).
- Auto-generated release notes (no CHANGELOG gate).
- Advance `loop@v1` (the moving major tag) to the release commit on every release.
- Version format is strict `X.Y.Z` semver.
- Target version for the harness itself: `0.12.0` (its own bump is the first auto-release — the dogfood).

## File Structure

```
scripts/check-release-version.sh        # NEW guard: plugin.json .version -> semver check, prints version
scripts/test-check-release-version.sh   # NEW offline test
.github/workflows/release.yml           # NEW the release workflow
docs/RELEASING.md                       # NEW the human process
.claude-plugin/plugin.json              # bump 0.11.1 -> 0.12.0 (Task 4)
```

---

### Task 1: The version guard script + test

**Files:**
- Create: `scripts/check-release-version.sh`
- Create: `scripts/test-check-release-version.sh`

**Interfaces:**
- Consumes: `.claude-plugin/plugin.json` in the CWD.
- Produces: on success prints the bare version `X.Y.Z` to stdout and exits 0; on a missing/malformed version prints a loud reason to stderr and exits 1. The workflow (Task 2) captures the stdout version.

- [ ] **Step 1: Write the failing test**

Create `scripts/test-check-release-version.sh`:

```bash
#!/usr/bin/env bash
# Offline test for check-release-version.sh — semver accept/reject.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAIL=0
mk() { mkdir -p "$TMP/.claude-plugin"; printf '{"name":"recursive-spine","version":"%s"}' "$1" > "$TMP/.claude-plugin/plugin.json"; }

# valid semver -> exit 0, echoes the version
mk "0.12.0"
OUT="$(cd "$TMP" && bash "$HERE/check-release-version.sh")"; RC=$?
{ [ "$RC" = 0 ] && [ "$OUT" = "0.12.0" ]; } && echo "PASS: valid semver echoed" || { echo "FAIL: valid semver (rc=$RC out=$OUT)"; FAIL=1; }

# malformed -> non-zero
for bad in "1.2" "v1.2.3" "1.2.3.4" "" "1.2.x" "1.2.3-rc1"; do
  mk "$bad"
  ( cd "$TMP" && bash "$HERE/check-release-version.sh" ) >/dev/null 2>&1; RC=$?
  [ "$RC" != 0 ] && echo "PASS: rejected '$bad'" || { echo "FAIL: accepted '$bad'"; FAIL=1; }
done

[ "$FAIL" = 0 ] && echo "PASS: all check-release-version scenarios" || exit 1
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash scripts/test-check-release-version.sh`
Expected: FAIL (script not created yet).

- [ ] **Step 3: Write the guard script**

Create `scripts/check-release-version.sh`:

```bash
#!/usr/bin/env bash
# Reads .claude-plugin/plugin.json .version (from CWD), asserts strict X.Y.Z
# semver, and prints it. Loud failure otherwise. Used by the release workflow.
set -uo pipefail

VER="$(jq -r '.version // empty' .claude-plugin/plugin.json 2>/dev/null || true)"
if [ -z "$VER" ]; then
  echo "check-release-version: no .version in .claude-plugin/plugin.json (cwd=$(pwd))" >&2
  exit 1
fi
if ! printf '%s' "$VER" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "check-release-version: version '$VER' is not strict X.Y.Z semver" >&2
  exit 1
fi
printf '%s' "$VER"
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash scripts/test-check-release-version.sh`
Expected: `PASS: all check-release-version scenarios`

- [ ] **Step 5: Commit**

```bash
git add scripts/check-release-version.sh scripts/test-check-release-version.sh
git commit -m "feat(release): version guard script + test (semver, X.Y.Z) (release harness)"
```

---

### Task 2: The release workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: `scripts/check-release-version.sh` (Task 1), all `scripts/test-*.sh`, `.claude-plugin/plugin.json` / `marketplace.json`.
- Produces: on a qualifying push, a tag `v<version>`, a GitHub release, and an advanced `loop@v1`.

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/release.yml`:

```yaml
name: release
# Auto-release on a version bump: when .claude-plugin/plugin.json changes on
# main and its version has no tag yet, gate on the full suite, then create the
# tag + GitHub release (auto notes) and advance loop@v1. The slopstopper site
# pulls these releases via the API. Never tag by hand — see docs/RELEASING.md.
on:
  push:
    branches: [main]
    paths: [".claude-plugin/plugin.json"]

permissions:
  contents: write   # create tags + releases, and move the loop@v1 major tag

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4
        with:
          fetch-depth: 0

      - name: Read version + idempotency guard
        id: guard
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          VER="$(bash scripts/check-release-version.sh)"   # prints X.Y.Z or fails loud
          echo "version=$VER" >> "$GITHUB_OUTPUT"
          if gh release view "v$VER" >/dev/null 2>&1 \
             || gh api "repos/${GITHUB_REPOSITORY}/git/ref/tags/v${VER}" >/dev/null 2>&1; then
            echo "already=1" >> "$GITHUB_OUTPUT"
            echo "v$VER already released — nothing to do."
          else
            echo "already=0" >> "$GITHUB_OUTPUT"
            echo "Releasing v$VER."
          fi

      - name: Gate — full suite (a release must not pass a narrower gate than a PR)
        if: steps.guard.outputs.already == '0'
        run: |
          jq -e '.name == "recursive-spine" and (.description | length > 0)' .claude-plugin/plugin.json
          python3 -m json.tool .claude-plugin/marketplace.json > /dev/null
          fail=0
          for t in scripts/test-*.sh; do
            echo "== $t"; bash "$t" || fail=1
          done
          exit $fail

      - name: Tag + GitHub release (auto notes)
        if: steps.guard.outputs.already == '0'
        env:
          GH_TOKEN: ${{ github.token }}
          VER: ${{ steps.guard.outputs.version }}
        run: |
          gh release create "v$VER" \
            --target "$GITHUB_SHA" \
            --generate-notes \
            --title "recursive-spine v$VER"

      - name: Advance loop@v1 to this release
        if: steps.guard.outputs.already == '0'
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh api "repos/${GITHUB_REPOSITORY}/git/refs/tags/v1" -X PATCH \
            -f sha="$GITHUB_SHA" -F force=true \
          || gh api "repos/${GITHUB_REPOSITORY}/git/refs" \
            -f ref="refs/tags/v1" -f sha="$GITHUB_SHA"
```

- [ ] **Step 2: Lint the workflow YAML**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/release.yml')); print('release YAML OK')"`
Expected: `release YAML OK`

- [ ] **Step 3: Confirm the gate mirrors validate.yml's executable checks**

Read `.github/workflows/validate.yml`; verify the release gate runs at least the same executable coverage (the manifest jq check and every `scripts/test-*.sh`). The frontmatter/maturity/pollen inline checks already gate the merge via validate on the PR; the release gate re-runs the executable suite. If validate later gains a new `scripts/test-*.sh`, the glob picks it up automatically — no edit needed.
Expected: gate covers manifest validity + all `scripts/test-*.sh`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "feat(release): auto-release workflow — guard, gate, release, advance loop@v1 (release harness)"
```

---

### Task 3: The releasing doc

**Files:**
- Create: `docs/RELEASING.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the human process reference.

- [ ] **Step 1: Write `docs/RELEASING.md`**

Create `docs/RELEASING.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add docs/RELEASING.md
git commit -m "docs(release): RELEASING.md — the standardized release process (release harness)"
```

---

### Task 4: Ship it + dogfood (first auto-release)

**Files:**
- Modify: `.claude-plugin/plugin.json` (version `0.11.1` → `0.12.0`)

**Interfaces:**
- Consumes: Tasks 1–3 on the branch.
- Produces: v0.12.0 released automatically by the new workflow.

- [ ] **Step 1: Bump the version**

In `.claude-plugin/plugin.json`, set `"version": "0.12.0"`.

- [ ] **Step 2: Validate JSON**

Run: `python3 -m json.tool .claude-plugin/plugin.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit and open the PR**

```bash
git add .claude-plugin/plugin.json
git commit -m "chore: v0.12.0 — release harness (release automation)"
```
Open the PR for `feat/release-harness` → main (spec, plan, all four tasks).

- [ ] **Step 4: Merge and verify the first auto-release**

After CI passes, merge to main. The push (adds `release.yml` and bumps to
0.12.0, touching `plugin.json`) triggers `release.yml`. Verify:

Run: `gh run list -R slopstopper/recursive-spine --workflow release.yml --limit 1` → a run appears and succeeds.
Run: `gh release view v0.12.0 -R slopstopper/recursive-spine --json tagName,body --jq '.tagName'` → `v0.12.0`.
Run: `gh api repos/slopstopper/recursive-spine/git/refs/tags/v1 --jq .object.sha` and `gh api repos/slopstopper/recursive-spine/git/ref/heads/main --jq .object.sha` → the two SHAs match (loop@v1 advanced).

**Fallback** (only if the newly-added workflow did not fire on its own adding commit — a known GitHub edge case): trigger it once by pushing an empty-but-plugin.json-touching commit, or re-run via `gh workflow run release.yml`. Note whichever path was needed in the PR.

- [ ] **Step 5: Confirm idempotency**

Run: `gh workflow run release.yml -R slopstopper/recursive-spine` (or wait for the next unrelated main push) → the run no-ops on the guard (v0.12.0 already exists), creating no duplicate release.
Expected: run succeeds, "already released — nothing to do", no second v0.12.0.
