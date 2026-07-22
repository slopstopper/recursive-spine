# recursive-spine loop (GitHub Action)

Weekly deterministic digest + optional LLM nudges, posted to your tracking
issue and (optionally) Slack. Capabilities tier up by the secrets you set:

| Tier | Secret | You get |
| --- | --- | --- |
| 0 | none | Digest of this repo, commented on your tracking issue, @mentioning you |
| 1 | `SPINE_SWEEP_TOKEN` (PAT/App token) | Sweep several repos |
| 2 | `ANTHROPIC_API_KEY` | LLM nudges (<=3, question-shaped) |
| 3 | `SLACK_WEBHOOK_URL` | Also push to Slack |

## Caller workflow

    name: spine-loop
    on:
      schedule: [{ cron: "0 8 * * 6" }]   # Saturday 08:00 UTC
      workflow_dispatch: {}
    jobs:
      loop:
        runs-on: ubuntu-latest
        steps:
          - uses: slopstopper/recursive-spine/loop@v1
            with:
              repos: "you/repo-a you/repo-b"
              tracking-issue: "you/repo-a#1"
              mention: "@you"
              ledger: "you/repo:.spine/nudge-ledger.md"
              sweep-token: ${{ secrets.SPINE_SWEEP_TOKEN }}
              anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
              slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}

- **ledger**: `owner/repo:path` of a markdown file used to suppress nudges
  already raised in a prior week. Leave empty to skip suppression.
