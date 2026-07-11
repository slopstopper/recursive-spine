# ADR-0001: Scaffold is a sibling skill, not grown bootstrap

**Status:** accepted
**Date:** 2026-07-11

## Context

Issue #32 left the shape open: grow `recursive-spine-bootstrap` to stamp
the full spine, or add a sibling skill. Bootstrap is small and proven
(the tracking stamp); the scaffold is new and larger (four parts,
interview-heavy). One skill would mean one entry point but a long
interview and a proven/unproven mix in one file.

## Decision

We will ship the scaffold as a sibling skill, `recursive-spine-scaffold`.
Its preflight checks for the tracking stamp and offers bootstrap first —
the dependency points at the proven thing. Bootstrap is unchanged except
a one-line referral seam in its report.

## Consequences

Easier: each skill keeps one concern; tracking-only users never meet the
scaffold interview; the scaffold can evolve without risking the proven
stamp. Harder: two invocations for a fresh repo (mitigated by the
referral seams); the plugin's skill count grows, which raises the
surfacing burden the moments map exists to carry.
