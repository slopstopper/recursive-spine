---
name: recursive-spine-method
description: Use when a builder wants to learn or be reminded of the recursive-spine tracking convention — where work state lives (GitHub issues+milestones, never prose ledgers), the five principles, the module system, and how to design a repo's dialect. Pure knowledge; takes no actions.
---

# recursive-spine: the method

Read `${CLAUDE_PLUGIN_ROOT}/reference/principles.md` and teach from it.
Do not paraphrase the principles loosely — state them exactly, then explain.

## How to teach it

1. Open with the failure mode, not the rule: prose ledger files (status
   files, queue tables) merge as text; rows get lost silently; every branch
   edits them so they become the repo's #1 conflict source. The convention
   exists because that failure was measured, not imagined.
2. State the five principles verbatim from the reference.
3. Explain the recursion doctrine: the convention was built under itself
   (issues before code, self-bootstrap, self-digest) and any adopting repo
   can hold it to that standard.
4. Walk the module system: deferral label mandatory, gap/debt/lane optional.
   Ask which failure modes the user actually has before recommending modules.

## Dialect design

Each repo keeps its own vocabulary ON TOP of the principles. Guide the user:
- What do you call a unit of work today? (W-item, ticket, task…) That word
  maps to "issue".
- Do you run assessments that produce findings? If yes → gap module.
- Do finished units hand incomplete edges to the next unit? If yes → debt
  module.
- Do you route work across model tiers or people? If yes → lane module,
  renamed to fit.
Record the answers as a short dialect note the repo keeps in its docs.

## Vocabulary seams

Same words, different plugins — don't conflate: spine "handover" = a closing
unit filing its debt issues (principle 4). tokenomics "handoff" = a down-tier
work spec crossing model tiers. plumb-line "handoff" = a skill-to-skill baton
pass within one session. plumb-line's internal "spine" (null-result
expressibility) is unrelated to this plugin's name.

## What this skill never does

No writes, no `gh` calls, no repo changes. If the user wants the convention
installed, name `recursive-spine-bootstrap`. If they have an existing prose
ledger, name `recursive-spine-migrate`. Suggest; never auto-invoke.
