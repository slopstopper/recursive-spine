#!/usr/bin/env bash
# Tier-2 nudge step: feed the digest + nudge runbook to Claude, print selected nudges.
# Degrades loudly: any failure prints a note and exits 0 so the digest still delivers.
set -uo pipefail
KEY="${ANTHROPIC_API_KEY:-}"
RUNBOOK="${SPINE_NUDGE_RUNBOOK:?SPINE_NUDGE_RUNBOOK path required}"
DIGEST="$(cat)"

if [ -z "$KEY" ]; then
  echo "_Nudge step skipped: no ANTHROPIC_API_KEY configured (digest-only tier)._"
  exit 0
fi
if [ ! -f "$RUNBOOK" ]; then
  echo "_Nudge step unavailable: runbook not found at $RUNBOOK._"; exit 0
fi

system="$(cat "$RUNBOOK")"
user="You are running the nudge step of this repo's own weekly loop. Below is this week's deterministic digest. Apply the runbook to select at most 3 conversation-starting nudges, each ending in a question, honoring the suppression and shape rules. Output ONLY the nudges as a numbered Markdown list, or the single line 'none' if nothing qualifies.

DIGEST:
${DIGEST}"

req="$(jq -Rn --arg s "$system" --arg u "$user" \
  '{model:"claude-sonnet-5",max_tokens:1200,system:$s,messages:[{role:"user",content:$u}]}')"

resp="$(curl -sf https://api.anthropic.com/v1/messages \
          -H "x-api-key: ${KEY}" -H "anthropic-version: 2023-06-01" \
          -H "content-type: application/json" -d "$req" 2>/dev/null)" \
  || { echo "_Nudge step unavailable: Anthropic API call failed; digest delivered without nudges._"; exit 0; }

text="$(echo "$resp" | jq -r '.content[]? | select(.type=="text") | .text' 2>/dev/null)"
[ -z "$text" ] && { echo "_Nudge step returned no content._"; exit 0; }
[ "$(printf '%s' "$text" | tr -d '[:space:]')" = "none" ] && exit 0
printf '%s\n' "$text"
