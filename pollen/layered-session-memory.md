---
id: pollen-layered-session-memory
form: pattern
source: slopstopper/recursive-spine#32
captured: 2026-07-11
stage: seedling
transplants: []
---

# Layered session memory

A session-memory convention with time-layered files and explicit rotation
rules, so an agent (or a returning human) reads the smallest file that
answers "where was I?" instead of one ever-growing log.

**Provenance, declassified:** proven in the builder's live session
environment (daily use across their projects, 2026). Recorded here as a
structure-faithful abstraction per the hive routing rule — layout and
rotation only, no personal content. The `source:` anchor is the issue
where capture was approved (#32 design review), because the proving
ground is not a repo.

## What worked

A single memory directory with four layers, hottest to coldest:

| layer | file(s) | holds | rotates |
| --- | --- | --- | --- |
| buffer | `now.md` | the current session's working notes | cleared into today's file at session end |
| daily | `today-<date>.md` | one file per working day | folded into `recent.md` after the day closes |
| recent | `recent.md` | a rolling ~7-day window, compressed | entries older than the window move to archive |
| archive | `archive.md` | everything older, tersest form | never deleted, only compressed |

Plus one file outside the rotation: `core-memories.md` — durable facts
and key moments that must survive every compression.

## Why it worked

Reading cost tracks recency: the buffer is tiny and always current; the
archive is complete but never read by default. Compression at each
boundary is a deliberate act (what mattered today?), which doubles as
review. Nothing is ever lost, but nothing old is ever in the way.

## How to transplant

1. Pick the memory root (a dot-directory at repo or home level).
2. Create the four layers plus the durable file; empty is fine.
3. Adopt the two rotation rules: session end → buffer folds into daily;
   day/window end → older layers compress downward.
4. State the convention in a doc agents read at session start (the
   scaffold's session-memory part stamps exactly this doc).
