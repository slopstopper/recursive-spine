#!/usr/bin/env bash
# Tier-2 nudge step: feed the digest + nudge runbook to Claude, print selected nudges.
# Degrades loudly: any failure prints a note and exits 0 so the digest still delivers.
set -uo pipefail
KEY="${ANTHROPIC_API_KEY:-}"
RUNBOOK="${SPINE_NUDGE_RUNBOOK:-}"
LEDGER="${SPINE_LEDGER:-}"
DIGEST="$(cat)"
TODAY="$(date -u +%Y-%m-%d)"

if [ -z "$KEY" ]; then
  echo "_Nudge step skipped: no ANTHROPIC_API_KEY configured (digest-only tier)._"
  exit 0
fi
if [ ! -f "$RUNBOOK" ]; then
  if [ -z "$RUNBOOK" ]; then
    echo "_Nudge step unavailable: runbook not found (SPINE_NUDGE_RUNBOOK unset or missing)._"
  else
    echo "_Nudge step unavailable: runbook not found at $RUNBOOK._"
  fi
  exit 0
fi

system="$(cat "$RUNBOOK")"

ledger_repo=""
ledger_path=""
ledger_content=""
ledger_sha=""
ledger_note=""
if [ -n "$LEDGER" ]; then
  ledger_repo="${LEDGER%%:*}"
  ledger_path="${LEDGER#*:}"
  ledger_json="$(gh api "repos/$ledger_repo/contents/$ledger_path" 2>/dev/null)"
  if [ -n "$ledger_json" ]; then
    ledger_raw="$(printf '%s' "$ledger_json" | jq -r .content 2>/dev/null)"
    ledger_sha="$(printf '%s' "$ledger_json" | jq -r .sha 2>/dev/null)"
    if [ -n "$ledger_raw" ] && [ "$ledger_raw" != "null" ]; then
      ledger_content="$(printf '%s' "$ledger_raw" | base64 -d 2>/dev/null)"
    fi
    [ "$ledger_sha" = "null" ] && ledger_sha=""
  fi
  if [ -z "$ledger_content" ] || [ -z "$ledger_sha" ]; then
    ledger_content=""
    ledger_sha=""
    ledger_note="_Ledger unreachable at $LEDGER; proceeding without suppression._"
  fi
fi

user="You are running the nudge step of this repo's own weekly loop. Below is this week's deterministic digest. Apply the runbook to select at most 3 conversation-starting nudges, each ending in a question, honoring the suppression and shape rules. Today's date is ${TODAY}.

Output the nudges as a numbered Markdown list (or the single line 'none' if nothing qualifies), then a literal delimiter line '===LEDGER===', then one ledger line per SELECTED nudge in the exact format '${TODAY} | <owner/repo#N> | <trigger> | outcome: pending' — or nothing after the delimiter if zero nudges were selected.

DIGEST:
${DIGEST}"

if [ -n "$LEDGER" ]; then
  user="${user}

LEDGER (apply the runbook's suppression rules — never re-send an unanswered nudge without a state change; declined stays declined):
${ledger_content}"
fi

req="$(jq -Rn --arg s "$system" --arg u "$user" \
  '{model:"claude-haiku-4-5-20251001",max_tokens:4096,system:$s,messages:[{role:"user",content:$u}]}')"

resp="$(curl -s https://api.anthropic.com/v1/messages \
          -H "x-api-key: ${KEY}" -H "anthropic-version: 2023-06-01" \
          -H "content-type: application/json" -d "$req" 2>/dev/null)"
if [ -z "$resp" ] || [ "$(echo "$resp" | jq -r '.type // empty' 2>/dev/null)" = "error" ]; then
  echo "nudge-debug: api-error=$(echo "$resp" | jq -rc '.error // .' 2>/dev/null | head -c 300)" >&2
  echo "_Nudge step unavailable: Anthropic API call failed; digest delivered without nudges._"; exit 0
fi

text="$(echo "$resp" | jq -r '.content[]? | select(.type=="text") | .text' 2>/dev/null)"
if [ -z "$text" ]; then
  echo "nudge-debug: stop_reason=$(echo "$resp" | jq -rc '.stop_reason // "?"') types=$(echo "$resp" | jq -rc '[.content[]?.type]' 2>/dev/null) error=$(echo "$resp" | jq -rc '.error // empty' 2>/dev/null) model=$(echo "$resp" | jq -rc '.model // "?"')" >&2
  echo "_Nudge step returned no content._"; exit 0
fi

human="${text%%===LEDGER===*}"
if [ "$text" != "$human" ]; then
  ledger_lines="${text#*===LEDGER===}"
else
  ledger_lines=""
fi
# Trim leading/trailing whitespace from the split parts.
human="$(printf '%s' "$human" | sed -e 's/[[:space:]]*$//')"
ledger_lines="$(printf '%s' "$ledger_lines" | sed -e '/^[[:space:]]*$/d')"

human_is_none="$([ "$(printf '%s' "$human" | tr -d '[:space:]')" = "none" ] && echo yes || echo no)"

if [ -n "$LEDGER" ]; then
  nudge_count="0"
  if [ -n "$ledger_lines" ]; then
    nudge_count="$(printf '%s\n' "$ledger_lines" | grep -c .)"
  fi
  if [ -n "$ledger_sha" ]; then
    appended_content="${ledger_content}
## run ${TODAY} — sent ${nudge_count} nudges

${ledger_lines}"
    encoded="$(printf '%s' "$appended_content" | base64 | tr -d '\n')"
    if ! gh api "repos/$ledger_repo/contents/$ledger_path" -X PUT \
           -f message="chore(nudge): ledger append ${TODAY} (#93)" \
           -f content="$encoded" -f sha="$ledger_sha" >/dev/null 2>&1; then
      ledger_note="_Ledger append failed; nudges delivered but not recorded._"
    fi
  elif [ -z "$ledger_note" ]; then
    ledger_note="_Ledger append failed; nudges delivered but not recorded._"
  fi
fi

if [ -n "$ledger_note" ]; then
  echo "$ledger_note"
fi

[ "$human_is_none" = "yes" ] && exit 0
printf '%s\n' "$human"
