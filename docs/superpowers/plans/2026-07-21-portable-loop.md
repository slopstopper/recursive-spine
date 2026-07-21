# Portable Collaborative-Loop Substrate (#93) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the collaborative loop run for any user as a scheduled GitHub Action — a deterministic digest (zero-secret), optional LLM nudges (API key), notifying delivery (issue comment + @mention, optional Slack webhook) — packaged as a reusable Action the scaffold stamps, and dogfooded on recursive-spine itself.

**Architecture:** A POSIX/`gh` digest script and an Anthropic-API nudge script live in `scripts/`. A composite Action in `loop/` orchestrates them with tier degradation and delivery. The scaffold skill gains a sixth optional part that stamps a thin workflow referencing the versioned Action. recursive-spine runs its own loop through the shipped Action.

**Tech Stack:** POSIX shell, `gh` CLI, `jq`, GitHub Actions (composite), Anthropic API (via `curl`), Slack incoming webhooks.

## Global Constraints

- Tiered by secret, each tier degrades loudly: Tier 0 none (own-repo digest) · Tier 1 `SPINE_SWEEP_TOKEN` (cross-repo) · Tier 2 `ANTHROPIC_API_KEY` (nudges) · Tier 3 `SLACK_WEBHOOK_URL` (Slack push).
- Config-neutral: owner, repo set, tracking issue, thresholds, channels come from workflow inputs or the dialect note — never hardcoded in the script or action.
- Delivery default is an issue comment that **@mentions the owner** (the #80 resolution — never a self-DM). Slack is an optional POST to a webhook (a bot, notifies).
- Degrade loudly: no `ANTHROPIC_API_KEY` → digest-only and says so; a repo that fails to sweep is a line in the report, never omitted; missing tracking issue → hard error.
- Honest denominators in every run (repos swept / failed).
- The nudge step is invoked as a named script with the nudge skill as its runbook — never a fat inline "obey this" prompt.
- Deterministic digest is tabular; #81's LLM "briefing voice" is NOT reproduced in shell (out of scope).
- Platform stays GitHub, model stays Claude (#46 out of scope).
- Version becomes exactly `0.10.0`.

## File Structure

```
scripts/spine-digest.sh              # NEW deterministic sweep (Tier 0/1) → digest markdown
scripts/test-spine-digest.sh         # NEW test (fixture-driven, offline)
scripts/spine-nudge.sh               # NEW Tier-2 nudge step: digest+ledger → ≤3 nudges via Anthropic API
scripts/spine-deliver.sh             # NEW delivery: post comment (+@mention), optional Slack webhook
loop/action.yml                      # NEW composite Action (loop@v1): orchestrates + tier degradation
loop/README.md                       # NEW action usage + the tier/secret table
reference/templates/scaffold/loop-workflow-frame.yml   # NEW stamped-workflow frame
skills/recursive-spine-scaffold/SKILL.md               # add 6th optional "loop" part
.github/workflows/spine-loop.yml     # NEW dogfood: recursive-spine's own loop
docs/tracking-dialect.md             # record loop config for the dogfood
.claude-plugin/plugin.json           # version → 0.10.0
```

---

### Task 1: Deterministic digest script

**Files:**
- Create: `scripts/spine-digest.sh`
- Create: `scripts/test-spine-digest.sh`

**Interfaces:**
- Consumes: env `SPINE_REPOS` (space-separated `owner/repo` list), `SPINE_DEFERRAL_LABEL` (default `deferred`), `SPINE_STALL_DAYS` (default 21), `GH_TOKEN` (from the caller).
- Produces: writes a Markdown digest to stdout and exits 0 if at least one repo swept, 2 if all failed. A `## Denominator` line always ends the output: `swept N/M` plus a `FAILED: <repo> (<reason>)` line per failure. Later tasks parse the first heading `# Spine digest — <date>` and the trailing denominator.

- [ ] **Step 1: Write the failing test**

Create `scripts/test-spine-digest.sh`:

```bash
#!/usr/bin/env bash
# Offline test for spine-digest.sh: stubs `gh` on PATH and asserts structure.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Stub gh: return fixed JSON per subcommand so the sweep is deterministic.
cat > "$TMP/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"issue list"*"--label deferred"*) echo '[{"number":7,"title":"old thing","createdAt":"2026-06-01T00:00:00Z"}]' ;;
  *"api"*"/milestones"*)             echo '[{"title":"M1","number":1,"open_issues":2,"updated_at":"2026-05-01T00:00:00Z"}]' ;;
  *"issue list"*"--assignee"*)       echo '[]' ;;
  *)                                  echo '[]' ;;
esac
STUB
chmod +x "$TMP/gh"

OUT="$(PATH="$TMP:$PATH" SPINE_REPOS="acme/one acme/two" SPINE_DEFERRAL_LABEL=deferred \
       SPINE_STALL_DAYS=21 GH_TOKEN=x bash "$HERE/spine-digest.sh" 2>/dev/null)"

fail=0
grep -q "^# Spine digest — " <<<"$OUT" || { echo "FAIL: no title heading"; fail=1; }
grep -q "acme/one" <<<"$OUT"          || { echo "FAIL: repo one missing"; fail=1; }
grep -q "acme/two" <<<"$OUT"          || { echo "FAIL: repo two missing"; fail=1; }
grep -q "#7"       <<<"$OUT"          || { echo "FAIL: aging deferral #7 missing"; fail=1; }
grep -Eq "swept 2/2" <<<"$OUT"        || { echo "FAIL: denominator wrong"; fail=1; }
[ "$fail" = 0 ] && echo "PASS: spine-digest structure" || exit 1
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash scripts/test-spine-digest.sh`
Expected: FAIL (script does not exist yet) — a "No such file" / non-PASS exit.

- [ ] **Step 3: Write the digest script**

Create `scripts/spine-digest.sh`:

```bash
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
```

- [ ] **Step 4: Make executable and run the test to verify it passes**

Run: `chmod +x scripts/spine-digest.sh && bash scripts/test-spine-digest.sh`
Expected: `PASS: spine-digest structure`

- [ ] **Step 5: Commit**

```bash
git add scripts/spine-digest.sh scripts/test-spine-digest.sh
git commit -m "feat(loop): deterministic digest sweep script — Tier 0/1, no LLM (#93)"
```

---

### Task 2: Delivery script

**Files:**
- Create: `scripts/spine-deliver.sh`

**Interfaces:**
- Consumes: env `SPINE_TRACKING_ISSUE` (`owner/repo#N`), `SPINE_MENTION` (e.g. `@effythealien`), optional `SLACK_WEBHOOK_URL`, `GH_TOKEN`; reads the message body from stdin.
- Produces: posts the body (prefixed with the @mention) as a comment on the tracking issue via `gh`; if `SLACK_WEBHOOK_URL` is set, also POSTs a JSON `{"text": <body>}`. Prints the created comment URL to stdout. Exit 3 on a hard failure (no tracking issue).

- [ ] **Step 1: Write the failing test (inline structure check)**

Add `scripts/test-spine-deliver.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/gh" <<'STUB'
#!/usr/bin/env bash
# echo a fake comment URL for `gh issue comment`
case "$*" in
  *"issue comment"*) echo "https://github.com/acme/one/issues/20#issuecomment-1" ;;
  *) echo '{}' ;;
esac
STUB
chmod +x "$TMP/gh"
OUT="$(printf 'hello world' | PATH="$TMP:$PATH" SPINE_TRACKING_ISSUE="acme/one#20" \
       SPINE_MENTION="@aoife" GH_TOKEN=x bash "$HERE/spine-deliver.sh" 2>/dev/null)"
grep -q "issuecomment-1" <<<"$OUT" && echo "PASS: deliver returns comment url" || exit 1
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash scripts/test-spine-deliver.sh`
Expected: FAIL (script missing).

- [ ] **Step 3: Write the delivery script**

Create `scripts/spine-deliver.sh`:

```bash
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
```

- [ ] **Step 4: Make executable and verify test passes**

Run: `chmod +x scripts/spine-deliver.sh && bash scripts/test-spine-deliver.sh`
Expected: `PASS: deliver returns comment url`

- [ ] **Step 5: Commit**

```bash
git add scripts/spine-deliver.sh scripts/test-spine-deliver.sh
git commit -m "feat(loop): delivery script — issue comment + @mention, optional Slack webhook (#93)"
```

---

### Task 3: Nudge step script (Tier 2)

**Files:**
- Create: `scripts/spine-nudge.sh`

**Interfaces:**
- Consumes: env `ANTHROPIC_API_KEY`, `SPINE_NUDGE_RUNBOOK` (path to the nudge skill file, default the installed `recursive-spine-nudge/SKILL.md`), `SPINE_LEDGER` (`owner/repo:path`), `GH_TOKEN`; reads the digest Markdown from stdin.
- Produces: prints the selected nudges as Markdown to stdout (empty string if zero); the model is instructed to obey the runbook's max-3, shape-gate, and suppression rules. Ledger append is performed by the caller/action (Task 4) using the model's returned ledger lines on stderr-free stdout section. Exit 0 always (a failed API call prints a loud `nudge step unavailable` note to stdout so the digest still delivers).

- [ ] **Step 1: Write the failing test (offline, stubbed curl)**

Add `scripts/test-spine-nudge.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# Stub curl to return a minimal Anthropic messages response.
cat > "$TMP/curl" <<'STUB'
#!/usr/bin/env bash
echo '{"content":[{"type":"text","text":"1. acme/one#5 — open it? (unblocked)"}]}'
STUB
chmod +x "$TMP/curl"
echo "$TMP/runbook.md" > /dev/null; echo "be brief" > "$TMP/runbook.md"
OUT="$(printf '# Spine digest\n## acme/one\n' | PATH="$TMP:$PATH" ANTHROPIC_API_KEY=x \
       SPINE_NUDGE_RUNBOOK="$TMP/runbook.md" GH_TOKEN=x bash "$HERE/spine-nudge.sh" 2>/dev/null)"
grep -q "acme/one#5" <<<"$OUT" && echo "PASS: nudge parses model output" || exit 1
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash scripts/test-spine-nudge.sh`
Expected: FAIL (script missing).

- [ ] **Step 3: Write the nudge script**

Create `scripts/spine-nudge.sh`:

```bash
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
```

- [ ] **Step 4: Make executable and verify test passes**

Run: `chmod +x scripts/spine-nudge.sh && bash scripts/test-spine-nudge.sh`
Expected: `PASS: nudge parses model output`

- [ ] **Step 5: Commit**

```bash
git add scripts/spine-nudge.sh scripts/test-spine-nudge.sh
git commit -m "feat(loop): Tier-2 nudge step — runbook-driven Anthropic call, degrades loudly (#93)"
```

---

### Task 4: The composite Action

**Files:**
- Create: `loop/action.yml`
- Create: `loop/README.md`

**Interfaces:**
- Consumes: the three scripts (Tasks 1–3) by relative path within the checked-out action repo; inputs `repos`, `tracking-issue`, `mention`, `deferral-label`, `stall-days`, `nudge-runbook`; env secrets `SPINE_SWEEP_TOKEN`, `ANTHROPIC_API_KEY`, `SLACK_WEBHOOK_URL`, plus the caller's `GITHUB_TOKEN`.
- Produces: a composite action runnable as `uses: slopstopper/recursive-spine/loop@v1`. Task 5's stamped workflow and Task 6's dogfood reference this path.

- [ ] **Step 1: Write the composite action**

Create `loop/action.yml`:

```yaml
name: "recursive-spine loop"
description: "Weekly deterministic digest + optional LLM nudges, delivered to a tracking issue."
inputs:
  repos:
    description: "Space-separated owner/repo list to sweep. Defaults to the workflow's own repo."
    required: false
    default: ${{ github.repository }}
  tracking-issue:
    description: "owner/repo#N to post the digest/nudges to."
    required: true
  mention:
    description: "@handle to notify in the comment."
    required: false
    default: ""
  deferral-label:
    required: false
    default: "deferred"
  stall-days:
    required: false
    default: "21"
  nudge-runbook:
    description: "Path to the nudge skill file for the Tier-2 step."
    required: false
    default: "${{ github.action_path }}/../skills/recursive-spine-nudge/SKILL.md"
runs:
  using: "composite"
  steps:
    - name: Digest (Tier 0/1)
      id: digest
      shell: bash
      env:
        GH_TOKEN: ${{ env.SPINE_SWEEP_TOKEN != '' && env.SPINE_SWEEP_TOKEN || github.token }}
        SPINE_REPOS: ${{ inputs.repos }}
        SPINE_DEFERRAL_LABEL: ${{ inputs.deferral-label }}
        SPINE_STALL_DAYS: ${{ inputs.stall-days }}
      run: |
        set -euo pipefail
        "${{ github.action_path }}/../scripts/spine-digest.sh" > "$RUNNER_TEMP/digest.md" || true
        echo "path=$RUNNER_TEMP/digest.md" >> "$GITHUB_OUTPUT"
    - name: Nudges (Tier 2, optional)
      id: nudge
      shell: bash
      env:
        GH_TOKEN: ${{ env.SPINE_SWEEP_TOKEN != '' && env.SPINE_SWEEP_TOKEN || github.token }}
        ANTHROPIC_API_KEY: ${{ env.ANTHROPIC_API_KEY }}
        SPINE_NUDGE_RUNBOOK: ${{ inputs.nudge-runbook }}
      run: |
        set -euo pipefail
        "${{ github.action_path }}/../scripts/spine-nudge.sh" \
          < "$RUNNER_TEMP/digest.md" > "$RUNNER_TEMP/nudges.md" || true
    - name: Deliver
      shell: bash
      env:
        GH_TOKEN: ${{ github.token }}
        SPINE_TRACKING_ISSUE: ${{ inputs.tracking-issue }}
        SPINE_MENTION: ${{ inputs.mention }}
        SLACK_WEBHOOK_URL: ${{ env.SLACK_WEBHOOK_URL }}
      run: |
        set -euo pipefail
        { cat "$RUNNER_TEMP/digest.md"; echo; echo "---"; echo; cat "$RUNNER_TEMP/nudges.md" 2>/dev/null || true; } \
          | "${{ github.action_path }}/../scripts/spine-deliver.sh"
```

- [ ] **Step 2: Write `loop/README.md`** with the tier/secret table and a copy-paste caller workflow.

Create `loop/README.md`:

```markdown
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
            env:
              SPINE_SWEEP_TOKEN: ${{ secrets.SPINE_SWEEP_TOKEN }}
              ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
              SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

- [ ] **Step 3: Lint the action YAML**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('loop/action.yml')); print('action YAML OK')"`
Expected: `action YAML OK`

- [ ] **Step 4: Commit**

```bash
git add loop/action.yml loop/README.md
git commit -m "feat(loop): composite Action wiring digest + optional nudges + delivery, tiered (#93)"
```

---

### Task 5: Scaffold integration

**Files:**
- Create: `reference/templates/scaffold/loop-workflow-frame.yml`
- Modify: `skills/recursive-spine-scaffold/SKILL.md` (add a sixth optional part in `## 2` and update the description + `## 5`/`## 6` counts)

**Interfaces:**
- Consumes: the Action from Task 4 (`slopstopper/recursive-spine/loop@v1`).
- Produces: a scaffold part that stamps `.github/workflows/spine-loop.yml` from the frame.

- [ ] **Step 1: Write the workflow frame** (interview fills the `<...>` slots).

Create `reference/templates/scaffold/loop-workflow-frame.yml`:

```yaml
# Stamped by recursive-spine-scaffold (the "loop" part). Edit the `with:` values.
name: spine-loop
on:
  schedule:
    - cron: "0 8 * * 6"   # Saturday 08:00 UTC — adjust to taste
  workflow_dispatch: {}
jobs:
  loop:
    runs-on: ubuntu-latest
    steps:
      - uses: slopstopper/recursive-spine/loop@v1
        with:
          repos: "<OWNER/REPO ...>"          # default: this repo only
          tracking-issue: "<OWNER/REPO#N>"
          mention: "<@handle>"
        env:
          SPINE_SWEEP_TOKEN: ${{ secrets.SPINE_SWEEP_TOKEN }}   # Tier 1 (cross-repo)
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}   # Tier 2 (nudges)
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}   # Tier 3 (Slack)
```

- [ ] **Step 2: Add the sixth part to the scaffold skill**

In `skills/recursive-spine-scaffold/SKILL.md`, under `## 2. The five parts`, rename the heading to `## 2. The six parts (interview one at a time, all optional)` and append this part after the constraints-file part:

```markdown
6. **The loop** — "the weekly digest+nudge should run itself, not wait for
   you to remember." Frame: `loop-workflow-frame.yml`. Interview: which
   repos to sweep (default this repo), which tracking issue receives the
   digest, and the @handle to notify. Stamps `.github/workflows/spine-loop.yml`
   referencing the published `slopstopper/recursive-spine/loop@v1` Action —
   the logic lives in the versioned Action, the stamped file is thin.
   Secrets (`SPINE_SWEEP_TOKEN`, `ANTHROPIC_API_KEY`, `SLACK_WEBHOOK_URL`)
   are the owner's to add; tiers degrade loudly without them. Record the
   choice (and any decline) in the dialect note.
```

Also update the skill's `description:` frontmatter to say "up to six parts" (from "up to five parts") and adjust any "five parts" count in `## 5`/`## 6`.

- [ ] **Step 3: Verify counts are consistent**

Run: `grep -c "five parts" skills/recursive-spine-scaffold/SKILL.md; grep -c "six parts" skills/recursive-spine-scaffold/SKILL.md`
Expected: `0` then `>=1` (no stale "five parts" remains; "six parts" present).

- [ ] **Step 4: Commit**

```bash
git add reference/templates/scaffold/loop-workflow-frame.yml skills/recursive-spine-scaffold/SKILL.md
git commit -m "feat(loop): scaffold's sixth part stamps the loop workflow (#93)"
```

---

### Task 6: Dogfood, docs, version (owner secrets required)

**Files:**
- Create: `.github/workflows/spine-loop.yml`
- Modify: `docs/tracking-dialect.md` (record the loop config)
- Modify: `.claude-plugin/plugin.json` (version → 0.10.0)

**Interfaces:**
- Consumes: everything prior. Requires the owner to add repo secrets (only they can) — this task's run step is gated on that.

- [ ] **Step 1: Stamp recursive-spine's own loop workflow**

Create `.github/workflows/spine-loop.yml`:

```yaml
name: spine-loop
on:
  schedule:
    - cron: "0 8 * * 6"   # Saturday 08:00 UTC
  workflow_dispatch: {}
jobs:
  loop:
    runs-on: ubuntu-latest
    steps:
      - uses: ./loop
        with:
          repos: "slopstopper/recursive-spine slopstopper/plumb-line slopstopper/tokenomics effythealien/Veska_Index_App"
          tracking-issue: "slopstopper/recursive-spine#20"
          mention: "@effythealien"
        env:
          SPINE_SWEEP_TOKEN: ${{ secrets.SPINE_SWEEP_TOKEN }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

(Note: `uses: ./loop` references the action in this same repo. The published `@v1` form is what other repos use.)

- [ ] **Step 2: Record loop config in the dialect note**

In `docs/tracking-dialect.md`, add a short `## loop (this installation)` section: repos swept (the family), tracking issue `#20`, notify `@effythealien`, schedule Saturday 08:00 UTC, and that the family sweep needs the `SPINE_SWEEP_TOKEN` PAT because it spans two owners. Note this replaces the personal launchd stopgap once verified.

- [ ] **Step 3: Bump version**

In `.claude-plugin/plugin.json`, set `"version": "0.10.0"`.

- [ ] **Step 4: Validate JSON and commit the buildable parts**

Run: `python3 -m json.tool .claude-plugin/plugin.json >/dev/null && python3 -c "import yaml;yaml.safe_load(open('.github/workflows/spine-loop.yml'));print('workflow OK')"`
Expected: `workflow OK`

```bash
git add .github/workflows/spine-loop.yml docs/tracking-dialect.md .claude-plugin/plugin.json
git commit -m "chore(loop): dogfood workflow + dialect config + v0.10.0 (#93)"
```

- [ ] **Step 5: Owner action + live verification (gated)**

This step needs the owner to add repo secrets — surface it, do not fake it:
1. Owner adds to `slopstopper/recursive-spine` secrets: `SPINE_SWEEP_TOKEN` (a PAT/fine-grained token with read access to the four repos + write to the tracking issue and the private-hive ledger), `ANTHROPIC_API_KEY`, and optionally `SLACK_WEBHOOK_URL`.
2. Trigger a run: `gh workflow run spine-loop.yml -R slopstopper/recursive-spine` then watch `gh run watch`.
3. Verify: a new digest comment on #20, @mentioning the owner; if the key is set, nudges appended; the denominator honest.
4. Tier check: temporarily unset `ANTHROPIC_API_KEY` (or run a branch without it) → the comment posts digest-only with the "_Nudge step skipped: no ANTHROPIC_API_KEY_" note.
5. Once green, retire the launchd stopgap: `launchctl unload ~/Library/LaunchAgents/com.slopstopper.spine-loop.plist && rm ~/Library/LaunchAgents/com.slopstopper.spine-loop.plist` and note the retirement on #21/#93.

- [ ] **Step 6: Commit any config fixes** discovered during live verification (e.g. token scope notes in the dialect section), message `fix(loop): <what> from live dogfood (#93)`.
