# The Collaborative Loop (#47) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the initiative organ — a weekly scheduled cloud routine that sweeps the tracked repos, selects 0–3 nudges against a private-hive ledger, and delivers them as a Slack DM, each nudge terminating in a question to the owner.

**Architecture:** One routine, two voices (spec approach A): the existing `recursive-spine-digest` skill produces the durable report on the tracking issue; a new `recursive-spine-nudge` skill ranks nudge candidates from the sweep plus dependency and pollen readings, filtered through an append-only ledger in `effythealien/private-hive`. Delivery destination is configuration read from the private hive, never hardcoded.

**Tech Stack:** Markdown prose skills (Claude Code plugin conventions), `gh` CLI, GitHub private repo for state, Claude Code scheduled cloud agent (`/schedule`), claude.ai Slack connector.

## Global Constraints

- Every nudge is shaped *observation → why now → question*; a candidate that cannot end in a question to a human is dropped. Nudges propose conversations, never execution.
- Max 3 nudges per delivery; an empty week is stated ("no nudges this week — nothing newly unblocked, nothing aged past threshold"), never padded.
- Skills are config-neutral: board owner, repo set, ledger location, delivery destination come from the dialect note / invoking context / private-hive config. No skill names a workspace, repo list, or file path inline.
- Nudge state is private-scope: ledger and delivery config live in `effythealien/private-hive` (per #40), never in this repo.
- Every failure is loud: failed repo sweeps appear in report and DM footer with honest denominators; Slack failure falls back to a tracking-issue comment marked `nudge-delivery-failed`; missed runs are detected from the ledger's last-run timestamp.
- Nothing may depend on a Claude Code hook having fired (#71 stays deferred).
- The Slack workspace question (Veska-origin account vs. new/refit workspace) is a recorded, non-blocking owner decision — build against the current linkage.

## File Structure

```
slopstopper/recursive-spine (this repo)
  skills/recursive-spine-nudge/SKILL.md        # the brain (new)
  skills/recursive-spine-nudge/evals/scenarios.md  # golden scenarios, hand-run (new)
  .claude-plugin/plugin.json                   # register 8th skill, bump 0.7.0 → 0.8.0
  .claude-plugin/marketplace.json              # description recount
  README.md                                    # skills list recount

effythealien/private-hive (via gh api, not a local clone)
  nudges/config.md                             # delivery destination + thresholds (new)
  nudges/ledger.md                             # append-only nudge memory (new)
```

---

### Task 1: Spike — headless gh-auth and Slack send (go/no-go)

**Files:**
- None in-repo. Output is a recorded comment on issue #21.

**Interfaces:**
- Produces: a go/no-go decision comment on `slopstopper/recursive-spine#21`. Task 6 (scheduling) reads this decision; if NO-GO, Task 6 switches to the recorded fallbacks (launchd substrate / issue-comment delivery) — both named in the spec.

- [ ] **Step 1: Create a one-off scheduled cloud run that tests both capabilities**

Use the `schedule` skill (or `claude` scheduled-agent UI) to create a **one-time** cloud run with exactly this prompt:

```
Spike for slopstopper/recursive-spine#21 and #47. Do exactly this and nothing else:
1. Run: gh api user --jq .login
2. Run: gh issue list -R effythealien/private-hive --limit 1 --json number,title
3. Attempt to send a Slack DM to the linked account with the text:
   "spine spike: headless Slack send works (delete me)"
4. Post ONE comment on slopstopper/recursive-spine#21 reporting three lines:
   - gh auth as: <login or FAILED: error text>
   - private repo read: <OK or FAILED: error text>
   - slack send: <OK or FAILED: error text>
Do not modify any files or close any issues.
```

- [ ] **Step 2: Verify the spike ran and read the result**

Run: `gh issue view 21 -R slopstopper/recursive-spine --comments | tail -20`
Expected: a comment containing the three result lines.

- [ ] **Step 3: Record the go/no-go decision**

Comment the decision on #21:

```bash
gh issue comment 21 -R slopstopper/recursive-spine --body "Spike verdict: <GO / NO-GO>. <If NO-GO: which capability failed and which recorded fallback applies — launchd substrate for gh-auth failure, issue-comment delivery for Slack failure.> Routine substrate decision for the collaborative loop (#47) follows this verdict."
```

No commit — this task changes no files.

---

### Task 2: The `recursive-spine-nudge` skill and its golden scenarios

**Files:**
- Create: `skills/recursive-spine-nudge/SKILL.md`
- Create: `skills/recursive-spine-nudge/evals/scenarios.md`

**Interfaces:**
- Consumes: digest sweep findings (the report format of `skills/recursive-spine-digest/SKILL.md`), ledger + config formats defined in Task 3 (`nudges/ledger.md`, `nudges/config.md` — formats are specified verbatim in both tasks, so they can be built in either order).
- Produces: the skill prose that Task 5's end-to-end run and Task 6's routine prompt invoke by name: `recursive-spine-nudge`.

- [ ] **Step 1: Write the golden scenarios first (the failing "tests")**

Create `skills/recursive-spine-nudge/evals/scenarios.md`:

```markdown
# recursive-spine-nudge — golden scenarios

Hand-run: dispatch a fresh subagent with SKILL.md plus one scenario's
fixture as its only context; check its output against the expectation.
CI wiring is #68's job, not this version's.

Fixture conventions: `sweep:` blocks use the digest's finding shapes;
`ledger:` blocks use the ledger entry format from nudges/ledger.md.

## S1 — re-nudge suppression
sweep: deferral recursive-spine#66 open, 30d old, no events since 2026-07-01.
ledger: `2026-07-05 | recursive-spine#66 | aging-deferral | outcome: no-response`
Expect: #66 NOT selected (nudged before, no state change since).

## S2 — declined stays declined
sweep: deferral recursive-spine#75 open, 20d old, no events since decline.
ledger: `2026-07-05 | recursive-spine#75 | aging-deferral | outcome: declined`
Expect: #75 NOT selected.

## S3 — state-change resurrection
sweep: deferral recursive-spine#66 open, commented 2026-07-10.
ledger: `2026-07-05 | recursive-spine#66 | aging-deferral | outcome: no-response`
Expect: #66 IS eligible again (issue activity after the nudge).

## S4 — max-3 cut and trigger ranking
sweep: 1 unblocked-and-next item, 2 aging deferrals, 2 stalled milestones,
1 pollen pair; empty ledger.
Expect: exactly 3 nudges, in order: the unblocked item, then the two
deferrals (older first). Stalled milestones and pollen cut. The cut is
noted in the delivery ("3 of 6 candidates").

## S5 — empty-week honesty
sweep: nothing aged past threshold, nothing unblocked, no pollen pairs.
Expect: delivery says exactly that no nudges qualify this week, with the
heartbeat visible (run happened, swept N/N). No padding.

## S6 — failed-repo footer
sweep: 3 of 4 repos swept; Veska_Index_App failed (auth).
Expect: DM footer contains "swept 3/4" and names the failed repo and
reason. Nudges from swept repos still go out.

## S7 — shape gate
candidate: "milestone M is stalled" with no possible question attached.
Expect: any candidate that cannot be phrased ending in a question to the
owner is dropped, whatever its rank.
```

- [ ] **Step 2: Verify the scenarios fail without the skill**

Dispatch one subagent with only `evals/scenarios.md` scenario S4 and the instruction "act as the recursive-spine-nudge skill" — without SKILL.md existing.
Expected: the subagent cannot state the ranking/cut rules consistently (no source of truth). This confirms the scenarios test the prose, not general knowledge.

- [ ] **Step 3: Write the skill**

Create `skills/recursive-spine-nudge/SKILL.md`:

```markdown
---
name: recursive-spine-nudge
description: Use after a recursive-spine-digest sweep to select and deliver system-initiated nudges — 0–3 conversation-starters pushed to the owner about what is unblocked, aging, stalled, or newly connected. Every nudge ends in a question; the skill proposes conversations, never executes work.
---

# recursive-spine: nudge

The digest reports; the nudge starts a conversation. This skill is the
initiative organ of the collaborative loop (#47): it may only propose,
shaped so that autonomy is structurally impossible — a nudge that cannot
end in a question to a human is dropped, whatever its rank.

## Configuration (read, never assume)

From the invoking context or the private hive's `nudges/config.md`:
delivery destination (Slack DM, issue comment, or file), tracking issue,
ledger location, age thresholds. From the dialect note of the invoking
repo: board owner, repo set. Never hardcode any of these. Nudge state is
private-scope: ledger and config live in the private hive, never in a
public repo.

## Inputs

1. **The sweep** — run or receive a recursive-spine-digest sweep
   (aging deferrals, stalled milestones, in-flight by lane,
   assigned-but-untouched, honest denominators).
2. **Dependency reading** (new sensing) — per repo, find items that became
   unblocked: issues whose recorded sequencing ("sequenced after…",
   "blocked by…", milestone ordering, lane position) names predecessors
   that are now all closed. Cite the predecessor state in the nudge.
3. **Pollen reading** (new sensing) — pollen records that plausibly relate
   to an open deferral. Every pair must cite *why* (shared mechanism,
   named skill, same moment). No citation, no candidate.
4. **The ledger** — `nudges/ledger.md` in the private hive: every prior
   nudge, its trigger, and its outcome.

## Candidate shape — the safety gate

Every candidate is *observation → why now → question*:

> #68 is next in the flagship lane (obs); the watches-itself milestone
> opened and its roadmap predecessors closed this week (why now); want to
> brainstorm it this week? (question)

Drop any candidate that cannot honestly take this shape.

## Discipline rules (ledger-enforced)

- **Never re-send an unanswered nudge** unless its underlying state
  changed since (issue edited, commented, relabeled, or a predecessor
  closed after the nudge date).
- **Declined stays declined** unless the issue changed after the decline.
- **Max 3 nudges per delivery.** When candidates exceed 3, say so
  ("3 of N candidates").
- **Empty week is stated, not padded:** "no nudges this week — nothing
  newly unblocked, nothing aged past threshold." The heartbeat stays
  visible even when the content is empty.

## Ranking

1. Unblocked-and-next (concrete, actionable now)
2. Aging deferrals (oldest first)
3. Stalled milestones
4. Pollen↔deferral connections (fuzziest; earns rank as it proves precision)

Within a trigger, older first.

## Delivery

Send the selected nudges to the configured destination. Footer always
carries the honest denominator ("swept N/M; X failed: reason") when any
repo failed. If the primary channel send fails, post the nudges as a
comment on the tracking issue prefixed `nudge-delivery-failed:` — the
heartbeat must stay observable when the channel isn't.

## Ledger append (always, even on empty weeks)

Append to `nudges/ledger.md`: run timestamp, swept N/M, one line per nudge
sent (`date | repo#issue | trigger | outcome: pending`). If the previous
run's timestamp is more than one interval old, open the delivery with
"missed N scheduled runs."

## Never

- Never execute, file, close, or edit work a nudge proposes — the owner's
  reply starts that conversation elsewhere.
- Never auto-file pollen matches as issues in target repos (that is #38,
  deliberately deferred).
- Never write nudge state to a public repo.
- Never depend on a Claude Code hook having fired (#71 is an adapter,
  never the method).
```

- [ ] **Step 4: Hand-run the golden scenarios**

For each scenario S1–S7: dispatch a fresh subagent whose context is `skills/recursive-spine-nudge/SKILL.md` + that scenario's fixture, instructed to "produce the delivery this skill would send." Check output against the scenario's Expect line.
Expected: all 7 match. Fix skill prose (not scenarios) on mismatch and re-run the failed scenario.

- [ ] **Step 5: Commit**

```bash
git add skills/recursive-spine-nudge/
git commit -m "feat(nudge): recursive-spine-nudge skill + golden scenarios — the initiative organ (#47)"
```

---

### Task 3: Private-hive ledger and delivery config

**Files:**
- Create (in `effythealien/private-hive`, via `gh api` — no local clone): `nudges/config.md`, `nudges/ledger.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the exact file formats the nudge skill reads (Task 2 quotes them) and the routine prompt names (Task 6): `nudges/config.md`, `nudges/ledger.md` in `effythealien/private-hive`.

- [ ] **Step 1: Create `nudges/config.md` in the private hive**

```bash
cat > "$CLAUDE_JOB_DIR/tmp/nudge-config.md" <<'EOF'
# Nudge delivery configuration (read by recursive-spine-nudge)

- **Channel:** slack-dm (the account currently linked to claude.ai)
- **Workspace note:** current Slack linkage is the Veska-origin account.
  Owner may later create a slopstopper workspace or refit this one as
  one-for-all-projects — switching is an edit to this file plus connector
  re-link, zero skill edits. Tracked as its own issue in
  slopstopper/recursive-spine.
- **Fallback channel:** comment on the tracking issue, prefixed
  `nudge-delivery-failed:`
- **Tracking issue (durable digest record):** slopstopper/recursive-spine#20
- **Ledger:** nudges/ledger.md (this repo)
- **Cadence:** weekly
- **Max nudges per delivery:** 3
- **Aging threshold:** digest defaults (21d stalled milestones,
  14d assigned-untouched) — defaults, not doctrine
- **Repo set:** per the dialect notes (public: slopstopper/recursive-spine
  docs/tracking-dialect.md; private: this repo's dialect note)
EOF
gh api repos/effythealien/private-hive/contents/nudges/config.md \
  -X PUT -f message="feat(nudges): delivery config for the collaborative loop (recursive-spine#47)" \
  -f content="$(base64 -i "$CLAUDE_JOB_DIR/tmp/nudge-config.md")"
```

Expected: HTTP 201 with the new file's content URL.

- [ ] **Step 2: Create `nudges/ledger.md` in the private hive**

```bash
cat > "$CLAUDE_JOB_DIR/tmp/nudge-ledger.md" <<'EOF'
# Nudge ledger (append-only; outcomes updated in place)

Entry format, one line per nudge sent:
`date | repo#issue | trigger | outcome: pending|conversation-started|declined|no-response`

Run header format, one per run (including empty weeks):
`## run YYYY-MM-DD — swept N/M[, FAILED: repo (reason)][, sent K nudges]`

Discipline this file enforces: never re-send an unanswered nudge without
state change; declined stays declined unless the issue changed after;
missed runs are detected from the latest run header's date.

<!-- runs append below -->
EOF
gh api repos/effythealien/private-hive/contents/nudges/ledger.md \
  -X PUT -f message="feat(nudges): nudge ledger — the loop's memory of what it said (recursive-spine#47)" \
  -f content="$(base64 -i "$CLAUDE_JOB_DIR/tmp/nudge-ledger.md")"
```

Expected: HTTP 201.

- [ ] **Step 3: Verify both files read back**

```bash
gh api repos/effythealien/private-hive/contents/nudges/config.md --jq .name
gh api repos/effythealien/private-hive/contents/nudges/ledger.md --jq .name
```

Expected: `config.md`, `ledger.md`.

No commit in this repo — both files live in the private hive.

---

### Task 4: Register the eighth skill

**Files:**
- Modify: `.claude-plugin/plugin.json` (description, version)
- Modify: `.claude-plugin/marketplace.json` (description)
- Modify: `README.md:5`, `README.md:39`, `README.md:66-74`

**Interfaces:**
- Consumes: the skill name `recursive-spine-nudge` from Task 2.
- Produces: manifests/README that count eight skills; version `0.8.0`.

- [ ] **Step 1: Update `plugin.json`**

In `.claude-plugin/plugin.json`: bump `"version": "0.7.0"` → `"0.8.0"`; in `description`, change the skill enumeration to `recursive-spine-method, recursive-spine-bootstrap, recursive-spine-migrate, recursive-spine-digest, recursive-spine-pollinate, recursive-spine-scaffold, recursive-spine-handover, recursive-spine-nudge`.

- [ ] **Step 2: Update `marketplace.json`**

Change `seven skills (…)` to `eight skills (…, recursive-spine-nudge)` matching the plugin.json enumeration exactly.

- [ ] **Step 3: Update README**

Line 5: `seven skills` → `eight skills`. Line 39: `installs the seven skills` → `installs the eight skills`. Line 66 list header `Seven skills` → `Eight skills`, and append to the list:

```markdown
- The system starts the conversation → `recursive-spine-nudge`
```

- [ ] **Step 4: Verify JSON is valid**

Run: `python3 -m json.tool .claude-plugin/plugin.json > /dev/null && python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md
git commit -m "feat(nudge): register recursive-spine-nudge — eight skills, v0.8.0 (#47)"
```

---

### Task 5: Manual end-to-end run — owner judges nudge quality

**Files:**
- None in-repo. Output: one real digest comment on #20, one real Slack DM (or fallback), one ledger append, owner verdict on #47.

**Interfaces:**
- Consumes: everything from Tasks 1–4 against live repo state.
- Produces: the owner's quality verdict recorded on #47; Task 6 is gated on it.

- [ ] **Step 1: Run the full pipeline manually, in-session**

Invoke `recursive-spine-digest` (post report to #20 as usual), then `recursive-spine-nudge` with the sweep output, reading config/ledger from the private hive, sending the real Slack DM.

- [ ] **Step 2: Verify all four outputs**

Run: `gh issue view 20 -R slopstopper/recursive-spine --comments | tail -5` (report posted); confirm DM arrived (owner checks Slack, or `nudge-delivery-failed:` comment exists on #20 if the channel failed); `gh api repos/effythealien/private-hive/contents/nudges/ledger.md --jq .content | base64 -d | tail -8` (run header + entries appended).

- [ ] **Step 3: Owner judges, verdict recorded**

Ask the owner: were the selected nudges the *right* nudges (would you have picked these three)? Record the answer:

```bash
gh issue comment 47 -R slopstopper/recursive-spine --body "First live end-to-end run <date>: <N> nudges delivered via <channel>. Owner verdict: <verbatim>. <Any selection-logic fixes filed/made.>"
```

If the verdict demands selection changes: fix SKILL.md prose, re-run the affected golden scenarios (Task 2 Step 4), commit as `fix(nudge): <what changed> per first live run`, and repeat this task once.

---

### Task 6: Schedule the routine; close the loop

**Files:**
- None in-repo. Output: a weekly scheduled cloud routine, #21 and #47 closed with records, two follow-up issues filed.

**Interfaces:**
- Consumes: Task 1's go/no-go verdict (fallbacks if NO-GO), Task 5's owner approval.

- [ ] **Step 1: Create the weekly routine**

Per Task 1's verdict: if GO, create a weekly scheduled cloud agent (via the `schedule` skill) with exactly this prompt; if NO-GO on gh-auth, install the same prompt as a weekly local launchd job running `claude -p "<prompt>"`; if NO-GO only on Slack, keep the cloud routine (the skill's fallback delivery already handles it).

```
Weekly collaborative-loop run for the recursive-spine installation.
1. Invoke the recursive-spine-digest skill; post the report to the
   tracking issue named in effythealien/private-hive nudges/config.md.
2. Invoke the recursive-spine-nudge skill with the sweep output; read
   ledger and delivery config from effythealien/private-hive nudges/;
   deliver per config; append the ledger (empty weeks included).
Never execute, file, or close work a nudge proposes. Honest denominators
in every output.
```

- [ ] **Step 2: Verify the routine exists and dry-fire once**

List the schedule (`/schedule` list or launchd: `launchctl list | grep spine`); trigger one immediate run; confirm a ledger run-header appended (same check as Task 5 Step 2).

- [ ] **Step 3: File the two follow-up issues**

```bash
gh issue create -R slopstopper/recursive-spine --label "deferred,lane:small" \
  --title "Slack workspace: keep Veska-origin linkage, new slopstopper workspace, or one-for-all refit" \
  --body "Recorded at #47 build time (spec 2026-07-12): nudge delivery currently uses the Veska-origin Slack linkage as working default. Switching is an edit to private-hive nudges/config.md plus connector re-link — zero skill edits. Owner decision, no deadline."
gh issue comment 35 -R slopstopper/recursive-spine --body "Collaborative loop (#47) shipped reading repo sets from dialect notes, so it does not depend on this board's freshness — but the nudge 'unblocked-and-next' reading benefits from a live board. Auto-add remains an owner UI task."
```

- [ ] **Step 4: Close #21 and #47 with closing records**

```bash
gh issue close 21 -R slopstopper/recursive-spine --comment "Resolved by the collaborative loop build (#47, spec 2026-07-12): substrate = <cloud routine / launchd per spike verdict on this issue>. Digest now runs weekly inside the loop's routine; manual invocation remains available."
gh issue close 47 -R slopstopper/recursive-spine --comment "Shipped (spec docs/superpowers/specs/2026-07-12-collaborative-loop-design.md, v0.8.0): recursive-spine-nudge skill + private-hive ledger/config + weekly routine delivering ≤3 question-terminated nudges via Slack DM with loud fallbacks. Deliberately still deferred: #71 hooks, #38 push distribution, #35 board auto-add, #68 CI evals (golden scenarios ship hand-run in skills/recursive-spine-nudge/evals/)."
```

- [ ] **Step 5: Verify closes and final state**

Run: `gh issue view 21 --json state --jq .state && gh issue view 47 --json state --jq .state`
Expected: `CLOSED` twice.
