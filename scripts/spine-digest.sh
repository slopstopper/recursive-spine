#!/usr/bin/env bash
# Deterministic recursive-spine digest sweep (Tier 0/1). No LLM.
# Reads config from env; writes a Markdown digest to stdout.
# Exit 0 if >=1 repo swept, 2 if all failed.
set -uo pipefail

REPOS="${SPINE_REPOS:?SPINE_REPOS (space-separated owner/repo) is required}"
LABEL="${SPINE_DEFERRAL_LABEL:-deferred}"
STALL_DAYS="${SPINE_STALL_DAYS:-21}"
NOW_EPOCH="$(date -u +%s)"
TODAY="$(date -u +%Y-%m-%d)"

days_since() { # ISO8601 -> integer days
  local iso="$1" ep
  ep="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso" +%s 2>/dev/null \
       || date -u -d "$iso" +%s 2>/dev/null)"
  [ -z "$ep" ] && { echo 0; return; }
  echo $(( (NOW_EPOCH - ep) / 86400 ))
}

swept=0; failed=0; body=""; fails=""
for repo in $REPOS; do
  if ! gh api "repos/$repo" --jq .full_name >/dev/null 2>&1; then
    failed=$((failed+1)); fails="${fails}- FAILED: ${repo} (unreachable / auth)\n"; continue
  fi
  swept=$((swept+1))
  section="## ${repo}\n"

  # Aging deferrals, oldest first.
  defer_json="$(gh issue list -R "$repo" --label "$LABEL" --state open \
                --json number,title,createdAt --limit 100 2>/dev/null || echo '[]')"
  defer_rows="$(echo "$defer_json" | jq -r '.[] | "\(.number)\t\(.createdAt)\t\(.title)"' \
                | while IFS=$'\t' read -r n created title; do
                    printf '| #%s | %sd | %s |\n' "$n" "$(days_since "$created")" "$title"
                  done | sort -t'|' -k3 -rn)"
  if [ -n "$defer_rows" ]; then
    section="${section}\n**Aging deferrals** (label \`${LABEL}\`, oldest first):\n"
    section="${section}| issue | age | title |\n| --- | --- | --- |\n${defer_rows}\n"
  else
    section="${section}\n_No open deferrals._\n"
  fi

  # Stalled milestones: open issues, no update in STALL_DAYS.
  ms_json="$(gh api "repos/$repo/milestones?state=open" 2>/dev/null || echo '[]')"
  ms_rows="$(echo "$ms_json" | jq -c '.[] | select(.open_issues > 0)' \
             | while read -r m; do
                 t="$(echo "$m" | jq -r .title)"; u="$(echo "$m" | jq -r .updated_at)"
                 age="$(days_since "$u")"
                 [ "$age" -ge "$STALL_DAYS" ] && printf '| %s | %sd idle |\n' "$t" "$age"
               done)"
  if [ -n "$ms_rows" ]; then
    section="${section}\n**Stalled milestones** (>=${STALL_DAYS}d idle):\n| milestone | idle |\n| --- | --- |\n${ms_rows}\n"
  fi

  body="${body}${section}\n"
done

# Assemble. Denominator always last.
printf '# Spine digest — %s\n\n' "$TODAY"
printf '%b' "$body"
printf '\n## Denominator\n\nswept %d/%d\n' "$swept" "$((swept+failed))"
[ -n "$fails" ] && printf '%b' "$fails"

[ "$swept" -ge 1 ] && exit 0 || exit 2
