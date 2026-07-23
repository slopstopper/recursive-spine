#!/usr/bin/env bash
# Fail-closed visibility guard for the collaborative loop (recursive-spine#103).
# Refuses delivery when a private-visibility repo would be exposed through a
# PUBLIC tracking issue. A digest that aggregates any private repo is private-
# scope (two-hive doctrine, #40) and must not be posted to a public location.
#
# Inputs (env): SPINE_REPOS (space-separated owner/repo), SPINE_TRACKING_ISSUE
#   (owner/repo#N), SLACK_WEBHOOK_URL (optional), GH_TOKEN (for gh).
# Exit 0 = safe to deliver. Exit 1 = mismatch — DO NOT deliver (loud reason).
#
# Fail-closed: if a repo's visibility can't be determined, it is treated as the
# unsafe case (a swept repo -> assume private; a target -> assume unverifiable
# and refuse). Better a loud refusal than a silent leak.
set -uo pipefail

REPOS="${SPINE_REPOS:?SPINE_REPOS (space-separated owner/repo) required}"
ISSUE="${SPINE_TRACKING_ISSUE:?SPINE_TRACKING_ISSUE (owner/repo#N) required}"

vis() { # echo public | private | unknown for a repo (gh returns UPPERCASE)
  local v
  v="$(gh repo view "$1" --json visibility --jq .visibility 2>/dev/null)" || { echo unknown; return; }
  [ -z "$v" ] && { echo unknown; return; }
  printf '%s' "$v" | tr 'A-Z' 'a-z'
}

# Is any swept repo non-public? (unknown counts as non-public — fail-safe)
any_private=0
for r in $REPOS; do
  v="$(vis "$r")"
  if [ "$v" != "public" ]; then
    any_private=1
    [ "$v" = "unknown" ] && echo "guard: cannot determine visibility of swept repo $r; treating as private (fail-safe)" >&2
  fi
done

target_repo="${ISSUE%%#*}"
target_vis="$(vis "$target_repo")"

fail=0
if [ "$any_private" = 1 ] && [ "$target_vis" = "public" ]; then
  echo "GUARD REFUSED: the sweep includes private (or unverifiable) repos, but the tracking issue ${ISSUE} lives in a PUBLIC repo (${target_repo}). Posting the digest there would leak private issue titles. Move the tracking issue to a private repo (two-hive doctrine, #40)." >&2
  fail=1
elif [ "$any_private" = 1 ] && [ "$target_vis" = "unknown" ]; then
  echo "GUARD REFUSED: private (or unverifiable) repos are swept and the visibility of the tracking-issue repo ${target_repo} cannot be determined; refusing to post private content to an unverifiable target (fail-closed)." >&2
  fail=1
fi

if [ "$any_private" = 1 ] && [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  echo "guard WARNING: private repos are swept and a Slack webhook is configured. A webhook's channel visibility cannot be verified via API — ensure that channel is private. (Not blocking; the channel is your responsibility.)" >&2
fi

if [ "$fail" = 0 ]; then
  echo "guard: OK — delivery targets are safe for the swept visibility."
else
  exit 1
fi
