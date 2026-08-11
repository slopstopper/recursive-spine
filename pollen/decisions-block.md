---
id: pollen-decisions-block
form: pattern
source: slopstopper/plumb-line#213
captured: 2026-08-11
stage: seedling
transplants: []
---

# Decisions the human owns go in a block at the end, never in the prose

Every agent response ends with a `## Decisions needed` block: numbered, one line
each, a recommendation per item, and **nothing requiring an answer anywhere else
in the message**. The block is a *running backlog* — anything still unanswered
from earlier turns is carried forward, not dropped. When no decision is genuinely
needed, the response says so rather than omitting the block.

## What worked

In a long working session on plumb-line, the agent repeatedly asked real
questions — which of two pollen records to file, whether to review two
config-only PRs, whether to file a follow-up issue, whether to add a wiki — by
embedding them in explanatory prose. Several were missed. The builder's own
description of the cost:

> "I think i missed some important decisions that I dont want to be lost and
> didn't get to answer and its happend a few times across this session"

The failure is not that the questions were unclear. They were *unlocated*: a
reader scanning a technical summary has no reason to expect a decision in the
fourth paragraph, and no way to tell whether one is there without reading every
line closely — which defeats the point of a summary.

The compounding is the real damage. A decision skipped in turn 3 does not stay
skipped; it resurfaces in turn 7 as confused back-and-forth, by which time the
context that made it easy to answer has scrolled away and work may have been
built on the unmade decision.

After adopting the block, a backlog of ten outstanding decisions — several
several turns old — was surfaced in one place and cleared in a single exchange.

## Why it worked

It separates two things agents habitually interleave: **reporting** (what
happened, which the human reads at whatever depth they choose) and **blocking
asks** (what cannot proceed without them, which they must not miss). Prose is
good at the first and structurally bad at the second.

Carrying unanswered items forward is what makes it a *ledger* rather than a
formatting habit. Without that, a question asked once and missed once is gone —
which is exactly how the backlog accumulated in the first place. This is the
same inbox/outbox reasoning as `pollen-deferral-outbox`, applied to the
conversation instead of the tracker.

Giving a recommendation per item matters too: it keeps the agent from using the
block to offload judgement it should be exercising. A decision listed with no
recommendation is usually one the agent could have made itself.

## How to transplant it

1. Add it to the repo's agent-instructions file (`CLAUDE.md`, `AGENTS.md`, or
   equivalent) so it survives across sessions rather than living in one
   conversation's memory.
2. State the three rules explicitly: **at the end**, **numbered with a
   recommendation each**, **carry forward what is unanswered**.
3. Say what to do when there is nothing to decide — otherwise the block quietly
   disappears on exactly the turns where its absence is ambiguous.
4. Keep it to decisions the human genuinely owns. Anything the agent can resolve
   from the code, the request, or a sensible default does not belong in it, or
   the block becomes noise and gets skimmed like the prose it replaced.

The same section is a natural home for other durable working conventions — how
work is reviewed, what the agent should treat as a class rather than an
instance — but the decisions block is the piece that pays for itself
immediately.

## Note on independent arrival

The same convention had already emerged independently in another of this
builder's projects before being named here. Two unrelated arrivals at the same
rule is a reasonable signal that it is addressing a structural property of
long agent sessions rather than one person's preference.
