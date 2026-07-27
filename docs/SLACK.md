# Sending loop nudges to Slack (optional)

**You probably don't need this.** The loop already notifies you: it posts the
digest and nudges as a comment on your tracking issue that **@mentions you**, so
GitHub emails/pushes you every week. Set up Slack only if you *also* want the
nudges pushed into a Slack channel.

Slack can't be automated (you have to create the app yourself), but it's a
five-minute, one-time setup.

## Get an incoming webhook URL

1. Go to **https://api.slack.com/apps** and click **Create New App** → **From
   scratch**.
2. Name it (e.g. `spine-nudges`) and pick your workspace → **Create App**.
3. In the sidebar, open **Incoming Webhooks** and toggle **Activate Incoming
   Webhooks** to **On**.
4. Click **Add New Webhook to Workspace**, choose the channel the nudges should
   land in, and **Allow**.
5. Copy the **Webhook URL** — `https://hooks.slack.com/services/` followed by
   three slash-separated IDs (`<workspace-id>/<channel-id>/<secret>`).

## Test it before trusting it

Paste your URL in place of `<URL>` and run:

    curl -sf -X POST -H 'Content-Type: application/json' \
      -d '{"text":"spine test — delete me"}' "<URL>"

A **spine test — delete me** message should appear in the channel. If it does,
the webhook works.

## Store it as the loop's secret

    gh secret set SLACK_WEBHOOK_URL -R <owner>/<repo>

Paste the URL when prompted (this keeps it out of your shell history). That's the
`SLACK_WEBHOOK_URL` the loop workflow reads for Tier 3 — done.

## Two things to know

- **This is a webhook, not the claude.ai Slack connector.** A webhook posts as an
  app and actually notifies you. The claude.ai connector posts *as you*, and
  Slack never notifies you of your own messages — so it can't be the loop's push
  channel.
- **If your loop sweeps private repos, use a private channel.** The digest can
  contain private issue titles; a private digest in a public Slack channel is the
  same leak class the loop's visibility guard blocks for issue delivery. Point the
  webhook at a channel only the right people can see.

## Turning it off

Delete the secret: `gh secret remove SLACK_WEBHOOK_URL -R <owner>/<repo>`. The
loop keeps delivering to your tracking issue as before.
