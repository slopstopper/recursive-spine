#!/usr/bin/env bash
# Deliver a digest/nudge body: tracking-issue comment (+@mention) and optional Slack webhook.
set -uo pipefail
ISSUE="${SPINE_TRACKING_ISSUE:?SPINE_TRACKING_ISSUE (owner/repo#N) required}"
MENTION="${SPINE_MENTION:-}"
BODY="$(cat)"
[ -z "$BODY" ] && { echo "empty body; nothing to deliver" >&2; exit 3; }

repo="${ISSUE%%#*}"; num="${ISSUE##*#}"
full_body="${MENTION:+$MENTION }$BODY"

url="$(printf '%s' "$full_body" | gh issue comment "$num" -R "$repo" --body-file - 2>/dev/null)" \
  || { echo "FAILED to post comment to $ISSUE" >&2; exit 3; }
echo "$url"

if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  payload="$(jq -Rn --arg t "$full_body" '{text:$t}')"
  curl -sf -X POST -H 'Content-Type: application/json' -d "$payload" "$SLACK_WEBHOOK_URL" >/dev/null \
    && echo "slack: delivered" >&2 \
    || echo "slack: FAILED (webhook error) — comment still posted" >&2
fi
