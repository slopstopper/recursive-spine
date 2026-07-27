# Slack Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`). NOTE: local git is blocked (macOS Documents permission); execute as GitHub Contents-API PUTs to the `docs/slack-onboarding` branch (the spec is already there). Docs-only — no behavioral code, nothing to unit-test; the v0.12.1 bump's merge auto-releases via the release harness.

**Goal:** Give the loop's optional Slack push a clear setup guide + honest "it's a bonus" framing, so a user can enable it without hunting.

**Architecture:** One new guide (`docs/SLACK.md`), pointers to it from `loop/README.md` and the scaffold frame, and a v0.12.1 bump so the release harness ships it.

**Tech Stack:** Markdown.

## Global Constraints

- Slack is framed as optional — the tracking-issue @mention already notifies.
- Two honest warnings in the guide: (a) a *webhook* posts as an app and notifies, unlike the claude.ai connector that posts as you (the #80 lesson); (b) private-repo sweeps require a private Slack channel (the #103 leak class).
- No change to `scripts/spine-deliver.sh` (it already handles + degrades the webhook).
- Version becomes exactly `0.12.1`.

## File Structure

```
docs/SLACK.md                                         # NEW guide
loop/README.md                                        # Tier-3 row + caller comment + bonus note
reference/templates/scaffold/loop-workflow-frame.yml  # slack-webhook-url comment -> guide
.claude-plugin/plugin.json                            # 0.12.0 -> 0.12.1
```

---

### Task 1: The Slack guide + pointers + bump (single cohesive docs unit)

**Files:**
- Create: `docs/SLACK.md`
- Modify: `loop/README.md`
- Modify: `reference/templates/scaffold/loop-workflow-frame.yml`
- Modify: `.claude-plugin/plugin.json`

**Interfaces:** none (docs).

- [ ] **Step 1: Write `docs/SLACK.md`**

Create `docs/SLACK.md` with exactly:

```markdown
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
5. Copy the **Webhook URL** — it looks like
   `https://hooks.slack.com/services/<workspace-id>/<channel-id>/<secret>` (three
   slash-separated IDs).

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
```

- [ ] **Step 2: Reframe the Tier-3 row + link the guide in `loop/README.md`**

In `loop/README.md`, replace the table row:

```markdown
| 3 | `SLACK_WEBHOOK_URL` | Also push to Slack |
```

with:

```markdown
| 3 | `SLACK_WEBHOOK_URL` | *(optional)* Also push to a Slack channel — setup: [docs/SLACK.md](../docs/SLACK.md) |
```

And replace the caller-workflow comment line:

```markdown
              slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

with:

```markdown
              slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}  # optional; see docs/SLACK.md
```

Then, immediately after the intro sentence that ends "Capabilities tier up by the secrets you set:", add a new paragraph:

```markdown

You always get notified without any secrets: the digest/nudges are commented on
your tracking issue and **@mention you**. Slack (Tier 3) is a bonus — see
[docs/SLACK.md](../docs/SLACK.md) if you want it.
```

- [ ] **Step 3: Point the scaffold frame at the guide**

In `reference/templates/scaffold/loop-workflow-frame.yml`, replace:

```yaml
          slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}  # Tier 3 (Slack)
```

with:

```yaml
          slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}  # Tier 3 (Slack) — optional; setup in docs/SLACK.md
```

- [ ] **Step 4: Bump the version**

In `.claude-plugin/plugin.json`, set `"version": "0.12.1"`.

- [ ] **Step 5: Verify + commit**

Checks: `docs/SLACK.md` exists and contains "not the claude.ai Slack connector" and "use a private channel"; `loop/README.md` contains "docs/SLACK.md"; the frame comment contains "docs/SLACK.md"; `python3 -m json.tool .claude-plugin/plugin.json` passes and shows `0.12.1`.

```bash
git add docs/SLACK.md loop/README.md reference/templates/scaffold/loop-workflow-frame.yml .claude-plugin/plugin.json
git commit -m "docs(loop): Slack onboarding guide + optional framing; v0.12.1 (loop usability)"
```

- [ ] **Step 6: PR, merge, confirm auto-release**

Open the `docs/slack-onboarding` PR (spec already on the branch) → main; after CI, merge. The `plugin.json` bump triggers `release.yml`. Verify:
Run: `gh release view v0.12.1 -R slopstopper/recursive-spine --json tagName --jq .tagName` → `v0.12.1`.
Run: `gh api repos/slopstopper/recursive-spine/git/refs/tags/v1 --jq .object.sha` matches main HEAD (loop@v1 advanced).
