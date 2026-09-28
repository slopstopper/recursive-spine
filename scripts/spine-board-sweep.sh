#!/usr/bin/env bash
# Board membership sweep — keeps a Projects v2 board current when auto-add
# cannot (#128). Reads config from env; writes a Markdown section to stdout.
#
# Why this exists: auto-add cannot cross an owner boundary, and the
# workflow count is capped per project, so a board covering more than one
# repo — or a user-owned board covering org repos — has no built-in way to
# stay current. Membership silently becomes a point-in-time snapshot.
#
# Membership is read from each ISSUE's projectItems, not from the project's
# item list: the project-side read path lags writes (observed reporting 29
# items where the issue-side query saw 41), so it cannot be trusted to
# decide whether an add is needed.
#
# Exit 0 if >=1 repo swept, 2 if all failed. Never fails the caller for an
# add that did not land — those are reported and counted.
set -uo pipefail

REPOS="${SPINE_REPOS:?SPINE_REPOS (space-separated owner/repo) is required}"
BOARD="${SPINE_BOARD:?SPINE_BOARD (owner/number, e.g. acme/3) is required}"
DRY_RUN="${SPINE_BOARD_DRY_RUN:-0}"

BOARD_OWNER="${BOARD%/*}"
BOARD_NUMBER="${BOARD##*/}"
if [ -z "$BOARD_OWNER" ] || [ -z "$BOARD_NUMBER" ] || [ "$BOARD_OWNER" = "$BOARD" ]; then
  echo "## Board sweep"
  echo
  echo "FAILED: SPINE_BOARD must be owner/number (got \`${BOARD}\`)."
  exit 2
fi
case "$BOARD_NUMBER" in
  ''|*[!0-9]*)
    echo "## Board sweep"
    echo
    echo "FAILED: board number must be numeric (got \`${BOARD_NUMBER}\`)."
    exit 2
    ;;
esac

# Open issues plus their project membership, paginated. Emits "<number> <on-board>"
# per line. Pagination matters: a silent first:100 cap would under-report the
# denominator, and under-reporting is the failure this whole sweep exists to fix.
issues_with_membership() {
  local repo="$1" owner="${1%%/*}" name="${1##*/}"
  local cursor="null" page out
  while :; do
    page="$(gh api graphql \
      -f query='query($owner:String!,$name:String!,$after:String){
        repository(owner:$owner,name:$name){
          issues(first:100,states:OPEN,after:$after){
            pageInfo{hasNextPage endCursor}
            nodes{number projectItems(first:20){nodes{project{number owner{... on Organization{login} ... on User{login}}}}}}
          }
        }
      }' -F owner="$owner" -F name="$name" -F after="$cursor" 2>/dev/null)" || return 1
    [ -z "$page" ] && return 1

    out="$(printf '%s' "$page" | jq -r --arg bo "$BOARD_OWNER" --argjson bn "$BOARD_NUMBER" '
      .data.repository.issues.nodes[]
      | "\(.number) \(
          if ([.projectItems.nodes[] | select(.project.number == $bn and .project.owner.login == $bo)] | length) > 0
          then "yes" else "no" end)"' 2>/dev/null)" || return 1
    [ -n "$out" ] && printf '%s\n' "$out"

    if [ "$(printf '%s' "$page" | jq -r '.data.repository.issues.pageInfo.hasNextPage')" != "true" ]; then
      break
    fi
    cursor="$(printf '%s' "$page" | jq -r '.data.repository.issues.pageInfo.endCursor')"
  done
  return 0
}

# Visibility, fail-closed. Adding a private repo's issues to a public board
# publishes their titles to anyone who can see the board. Unknown visibility
# is treated as private: the sweep refuses rather than guesses.
BOARD_PUBLIC="$(gh project view "$BOARD_NUMBER" --owner "$BOARD_OWNER" \
                --format json --jq '.public' 2>/dev/null)"
[ -z "$BOARD_PUBLIC" ] && BOARD_PUBLIC="unknown"

repo_is_public() {
  local v
  v="$(gh repo view "$1" --json visibility --jq '.visibility' 2>/dev/null)"
  [ "$v" = "PUBLIC" ]
}

swept=0; failed=0; body=""; fails=""
total_open=0; total_present=0; total_added=0; total_failed_add=0; total_missing=0

for repo in $REPOS; do
  if [ "$BOARD_PUBLIC" = "true" ] && ! repo_is_public "$repo"; then
    fails="${fails}- REFUSED: ${repo} is not public and the board is — adding would publish its issue titles
"
    continue
  fi

  rows="$(issues_with_membership "$repo")"
  if [ $? -ne 0 ]; then
    failed=$((failed+1))
    fails="${fails}- FAILED: ${repo} (unreachable / auth)
"
    continue
  fi
  swept=$((swept+1))

  open=0; present=0; added=0; failed_add=0; missing=0; added_list=""; failed_list=""
  while read -r num on_board; do
    [ -z "$num" ] && continue
    open=$((open+1))
    if [ "$on_board" = "yes" ]; then
      present=$((present+1))
      continue
    fi
    missing=$((missing+1))
    if [ "$DRY_RUN" = "1" ]; then
      continue
    fi
    if gh project item-add "$BOARD_NUMBER" --owner "$BOARD_OWNER" \
         --url "https://github.com/${repo}/issues/${num}" >/dev/null 2>&1; then
      added=$((added+1)); added_list="${added_list} #${num}"
    else
      failed_add=$((failed_add+1)); failed_list="${failed_list} #${num}"
    fi
  done <<< "$rows"

  total_open=$((total_open+open)); total_present=$((total_present+present))
  total_added=$((total_added+added)); total_failed_add=$((total_failed_add+failed_add))
  total_missing=$((total_missing+missing))

  if [ "$DRY_RUN" = "1" ]; then
    body="${body}| ${repo} | ${open} | ${present} | ${missing} (dry run) | — |
"
  else
    body="${body}| ${repo} | ${open} | ${present} | ${added} | ${failed_add} |
"
  fi
  [ -n "$failed_list" ] && fails="${fails}- ${repo}: could not add${failed_list}
"
done

echo "## Board sweep — ${BOARD_OWNER} project ${BOARD_NUMBER}"
echo
if [ "$swept" -gt 0 ]; then
  if [ "$DRY_RUN" = "1" ]; then
    echo "| repo | open | on board | missing | — |"
  else
    echo "| repo | open | already on | added | add failed |"
  fi
  echo "| --- | --- | --- | --- | --- |"
  printf '%s' "$body"
  echo
  if [ "$DRY_RUN" = "1" ]; then
    echo "Dry run: ${total_missing} of ${total_open} open issues are not on the board. Nothing was changed."
  elif [ "$total_added" -eq 0 ] && [ "$total_failed_add" -eq 0 ]; then
    echo "Board already current: ${total_present}/${total_open} open issues present, nothing to add."
  else
    echo "Added ${total_added} of ${total_missing} missing; ${total_present} were already present (${total_open} open total)."
  fi
fi

if [ -n "$fails" ]; then
  echo
  echo "**Not swept or not added** — honest denominator:"
  printf '%s' "$fails"
fi

[ "$swept" -eq 0 ] && exit 2
exit 0
