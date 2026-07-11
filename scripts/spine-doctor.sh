#!/usr/bin/env bash
# Spine doctor — installed-spine health, report-only (#64).
#
# Bootstrap and scaffold are idempotent stampers; nothing verified the
# stamp stays true as time passes. This script reads the dialect note as
# the installation's manifest and checks each recorded answer against
# observable reality: labels intact, board membership current, stamped
# parts present, CI gates wired. It never fixes anything — each finding
# names the skill that owns the repair (bootstrap for labels, scaffold
# for parts). ALWAYS exits 0: it is the digest's instrument, not a gate.
#
# Dialect-note parsing is best effort against the conventions the
# bootstrap skill records; anything unparseable is a loud NOTE and a
# skipped check, never a silent pass. SPINE_GH overrides the gh binary
# (used by the test harness).
set -u

GH=${SPINE_GH:-gh}
DIALECT=${SPINE_DIALECT:-docs/tracking-dialect.md}

repo=$($GH repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
if [ -z "$repo" ]; then
  echo "SPINE-DOCTOR NOTE: not a GitHub repo or gh unauthenticated — nothing checked"
  exit 0
fi

warns=0
warn() { echo "SPINE-DOCTOR WARN: $*"; warns=$((warns + 1)); }
note() { echo "SPINE-DOCTOR NOTE: $*"; }

# --- 1. Dialect note ------------------------------------------------------
if [ ! -f "$DIALECT" ]; then
  warn "no dialect note at $DIALECT — the installation has no manifest (recursive-spine-bootstrap records it); label/board checks run against defaults only"
fi

# --- 2. Labels vs the record ---------------------------------------------
# The deferral module is mandatory; lane labels are checked when the
# dialect note names them (backtick-quoted `lane:*` tokens).
existing_labels=$($GH label list --repo "$repo" --limit 100 --json name -q '.[].name' 2>/dev/null)
if [ -z "$existing_labels" ]; then
  note "could not list labels — label checks skipped"
else
  printf '%s\n' "$existing_labels" | grep -qx 'deferred' \
    || warn "label 'deferred' missing — the mandatory deferral module has no home (recursive-spine-bootstrap stamps it)"
  if [ -f "$DIALECT" ]; then
    # Lines recording a rename ("from `lane:x`") are provenance, not
    # current config — flagging a retired lane every run is alarm fatigue.
    while IFS= read -r lane; do
      printf '%s\n' "$existing_labels" | grep -qx "$lane" \
        || warn "label '$lane' named in $DIALECT but missing from the repo (recursive-spine-bootstrap stamps labels)"
    done < <(grep -E '`lane:[a-z-]+`' "$DIALECT" 2>/dev/null | grep -v 'from `lane:' \
             | grep -oE '`lane:[a-z-]+`' | tr -d '\`' | sort -u)
  fi
fi

# --- 3. Board membership vs open issues ----------------------------------
# Reads SPINE_BOARD_NUMBER and the board owner from the dialect note. A
# board that stopped tracking open issues is the failure this repo
# actually lived (auto-add is UI-only); staleness here is a finding, not
# a surprise.
board_num=""
board_owner=""
if [ -f "$DIALECT" ]; then
  board_num=$(grep -oE '`SPINE_BOARD_NUMBER`[^0-9]*[0-9]+' "$DIALECT" 2>/dev/null | grep -oE '[0-9]+' | head -1)
  board_owner=$(grep -A2 -i 'board owner' "$DIALECT" 2>/dev/null | grep -oE '`[A-Za-z0-9-]+`' | head -1 | tr -d '\`')
fi
if [ -z "$board_num" ] || [ -z "$board_owner" ]; then
  note "no parseable board (SPINE_BOARD_NUMBER + board owner) in $DIALECT — board check skipped"
else
  board_items=$($GH project item-list "$board_num" --owner "$board_owner" \
    --format json --limit 500 2>/dev/null \
    | jq -r --arg repo "$repo" \
      '.items[] | select((.content.repository // "") | ascii_downcase == ($repo | ascii_downcase)) | .content.number' 2>/dev/null)
  if [ -z "$board_items" ] && ! $GH project view "$board_num" --owner "$board_owner" >/dev/null 2>&1; then
    note "board $board_owner/projects/$board_num unreadable — token may lack the project scope (gh auth refresh -s project,read:project); board check skipped"
  else
    missing=0
    while IFS= read -r num; do
      [ -z "$num" ] && continue
      printf '%s\n' "$board_items" | grep -qx "$num" || missing=$((missing + 1))
    done < <($GH issue list --repo "$repo" --state open --limit 200 --json number -q '.[].number' 2>/dev/null)
    if [ "$missing" -gt 0 ]; then
      warn "$missing open issue(s) in $repo are not on board $board_owner/projects/$board_num — membership has gone stale (auto-add is UI-only; see the dialect note)"
    fi
  fi
fi

# --- 4. Stamped parts still present ---------------------------------------
[ -d .github/ISSUE_TEMPLATE ] \
  || note "no .github/ISSUE_TEMPLATE directory — templates were either never stamped or removed"
if [ -f scripts/check-constraints-drift.sh ]; then
  [ -x scripts/check-constraints-drift.sh ] \
    || warn "scripts/check-constraints-drift.sh present but not executable — the drift gate cannot run"
  if ls .github/workflows/*.yml >/dev/null 2>&1; then
    grep -rq 'check-constraints-drift' .github/workflows/ \
      || warn "drift checker present but no workflow runs it — the gate is disconnected (recursive-spine-scaffold wires it)"
  else
    warn "drift checker present but no CI workflow exists — the gate awaits a workflow (recursive-spine-scaffold, CI part)"
  fi
fi

# --- Summary ----------------------------------------------------------------
echo "SPINE-DOCTOR SUMMARY: $repo — $warns finding(s)." \
  "Checked: dialect note, labels vs the record, board membership," \
  "stamped parts. Skipped checks are NOTE lines above, never silent." \
  "Report-only: exit is always 0."
exit 0
