#!/usr/bin/env bash
# Spine audit — convention adherence, report-only (#63).
#
# The convention says: closed units carry a handover record, merged PRs
# cite their issue, branches are named <prefix>/<issue>-<slug>. Nothing
# verified any of it until this script. It reads repo state via gh and
# prints loud WARN lines; it ALWAYS exits 0 — issue and branch state is
# not in a PR author's control, so this is the digest's instrument, not
# a CI gate. Run it from the repo to audit; parameterized by `gh repo
# view`, never hardcoded to one installation.
#
# Honest denominators: every check states what it looked at and what it
# skipped. SPINE_GH overrides the gh binary (used by the test harness).
set -u

GH=${SPINE_GH:-gh}
CLOSED_LIMIT=${SPINE_AUDIT_CLOSED_LIMIT:-15}
PR_LIMIT=${SPINE_AUDIT_PR_LIMIT:-20}

repo=$($GH repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
if [ -z "$repo" ]; then
  echo "SPINE-AUDIT NOTE: not a GitHub repo or gh unauthenticated — nothing audited"
  exit 0
fi

warns=0
warn() { echo "SPINE-AUDIT WARN: $*"; warns=$((warns + 1)); }

# --- 1. Closed issues without a handover record -------------------------
# Issues closed as NOT_PLANNED (dupes, wontfix) are skipped: they are not
# completed units of work, so the convention asks nothing of them.
checked_closed=0
skipped_not_planned=0
while IFS=$'\t' read -r num reason; do
  [ -z "$num" ] && continue
  if [ "$reason" = "NOT_PLANNED" ]; then
    skipped_not_planned=$((skipped_not_planned + 1))
    continue
  fi
  checked_closed=$((checked_closed + 1))
  if ! $GH issue view "$num" --repo "$repo" --json comments \
      -q '.comments[].body' 2>/dev/null | grep -q '^## Handover'; then
    warn "issue #$num closed as completed without a '## Handover' closing record (recursive-spine-handover owns this moment)"
  fi
done < <($GH issue list --repo "$repo" --state closed --limit "$CLOSED_LIMIT" \
  --json number,stateReason -q '.[] | [.number, (.stateReason // "")] | @tsv' 2>/dev/null)

# --- 2. Merged PRs citing no issue ---------------------------------------
checked_prs=0
while IFS= read -r num; do
  [ -z "$num" ] && continue
  warn "PR #$num merged without citing an issue (PRs say 'Closes #N')"
done < <($GH pr list --repo "$repo" --state merged --limit "$PR_LIMIT" \
  --json number,body -q '.[] | select((.body // "") | test("#[0-9]+") | not) | .number' 2>/dev/null)
checked_prs=$($GH pr list --repo "$repo" --state merged --limit "$PR_LIMIT" \
  --json number -q 'length' 2>/dev/null || echo 0)

# --- 3. Branches off the naming convention -------------------------------
default_branch=$($GH repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
checked_branches=0
while IFS= read -r br; do
  [ -z "$br" ] && continue
  [ "$br" = "$default_branch" ] && continue
  checked_branches=$((checked_branches + 1))
  if ! printf '%s\n' "$br" | grep -qE '^[a-z]+/[0-9]+-[A-Za-z0-9._-]+$'; then
    warn "branch '$br' does not match <prefix>/<issue>-<slug>"
  fi
done < <($GH api "repos/$repo/branches" --paginate -q '.[].name' 2>/dev/null)

# --- Summary --------------------------------------------------------------
echo "SPINE-AUDIT SUMMARY: $repo — $warns finding(s)." \
  "Checked: $checked_closed closed issues (limit $CLOSED_LIMIT," \
  "$skipped_not_planned closed-as-not-planned skipped)," \
  "$checked_prs merged PRs (limit $PR_LIMIT)," \
  "$checked_branches branches. Report-only: exit is always 0."
exit 0
