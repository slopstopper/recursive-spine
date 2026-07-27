# Slack onboarding — design

**Date:** 2026-07-27
**Scope:** smooth the collaborative loop's optional Tier-3 Slack setup (#93 follow-up, resolves the onboarding friction noted at #80)
**Lane:** small · **Target:** v0.12.1

## Intent

Enabling the loop's optional Slack push requires creating a Slack app + incoming
webhook — fiddly, and the spine gave zero guidance (loop/README only names the
`SLACK_WEBHOOK_URL` secret). Slack app creation can't be automated, so the fix is
clear guidance + honest framing that Slack is an optional bonus: the loop already
notifies via the tracking-issue @mention.

## Components

1. **`docs/SLACK.md`** — a tight step-by-step guide:
   - Framing header: Slack is optional; the @mention already notifies.
   - Exact clicks: api.slack.com/apps → Create New App (From scratch) → name +
     workspace → Incoming Webhooks → toggle On → Add New Webhook to Workspace →
     pick channel → Authorize → copy the `https://hooks.slack.com/services/…` URL.
   - Store it: `gh secret set SLACK_WEBHOOK_URL -R <owner>/<repo>` (paste when
     prompted).
   - Test before trusting: a one-line `curl` posting "spine test — delete me" to
     the webhook, so a message is confirmed in the channel first.
   - Two warnings: (a) this is a *webhook* (posts as an app, actually notifies) —
     NOT the claude.ai Slack connector that posts as you and never notifies (the
     #80 lesson); (b) if the digest sweeps private repos, use a **private** Slack
     channel — a private digest to a public channel is the leak class the guard
     (#103) exists for.

2. **`loop/README.md` reframing** — the Tier-3 row + caller example gain
   "optional; see `docs/SLACK.md`", and a line noting the @mention already
   notifies so Slack is a bonus, not a requirement.

3. **`reference/templates/scaffold/loop-workflow-frame.yml`** — the
   `slack-webhook-url` comment points at `docs/SLACK.md`, so a stamped user finds
   the guide.

4. **Version** — bump `plugin.json` to `0.12.1`; the release harness auto-releases
   it and the site reflects the improvement.

## Testing

- Read-through: a newcomer can enable Slack from `docs/SLACK.md` alone; the test
  `curl` and the two warnings are present.
- No behavioral code changes (delivery script already handles the webhook +
  degrades loudly); nothing to unit-test. The v0.12.1 bump exercises the release
  harness end-to-end again.

## Out of scope

Automating Slack app creation (impossible); a guided in-session setup skill
(over-machinery for a one-time task); any change to the delivery script.
