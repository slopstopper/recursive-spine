# recursive-spine loop (GitHub Action)

Weekly deterministic digest + optional LLM nudges, posted to your tracking
issue and (optionally) Slack. Capabilities tier up by the secrets you set:

You always get notified without any secrets: the digest/nudges are commented on
your tracking issue and **@mention you**. Slack (Tier 3) is a bonus — see
[docs/SLACK.md](../docs/SLACK.md) if you want it.

| Tier | Secret | You get |
| --- | --- | --- |
| 0 | none | Digest of this repo, commented on your tracking issue, @mentioning you |
| 1 | `SPINE_SWEEP_TOKEN` (PAT/App token) | Sweep several repos |
| 2 | `ANTHROPIC_API_KEY` | LLM nudges (<=3, question-shaped) |
| 3 | `SLACK_WEBHOOK_URL` | *(optional)* Also push to a Slack channel — setup: [docs/SLACK.md](../docs/SLACK.md) |

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
              slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}  # optional; see docs/SLACK.md

- **ledger**: `owner/repo:path` of a markdown file used to suppress nudges
  already raised in a prior week. Leave empty to skip suppression.

## Board sweep (optional)

Keeps a Projects v2 board's membership current. Set `board` to enable it;
leave it empty and the step is skipped entirely.

              board: "you/3"                    # owner/number
              board-repos: "you/repo-a"         # optional; defaults to `repos`
              board-dry-run: "0"                # "1" to report drift without adding

**Why this is needed.** GitHub's built-in auto-add workflow cannot keep a
multi-repo board current ([#128](https://github.com/slopstopper/recursive-spine/issues/128)):
it does not list organisation repositories in a user-owned project's picker,
and the workflow count is capped per project. So a board covering more than
one repo, or a personal board covering org repos, has no built-in way to stay
current — and the drift is invisible, because a stale board looks exactly like
a current one. One board was found at 15 of 41 open issues with nothing
reporting it.

Notes:

- **Membership is read from each issue's `projectItems`, not the project's
  item list.** The project-side read path lags writes — observed reporting 29
  items where the issue-side query saw 41 — so it cannot be trusted to decide
  whether an add is needed.
- **Fail-closed on visibility.** A private repo is never added to a public
  board, since that would publish its issue titles; the refusal is reported
  rather than silent.
- **Idempotent.** A current board produces "nothing to add" and no writes.
- Use `board-dry-run: "1"` to measure drift without changing anything — useful
  for deciding whether a board is worth keeping.
