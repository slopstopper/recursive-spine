# Sub-issue mechanics (macro/micro depth)

Shared by handover, digest, and nudge. Skills describe *when* depth
happens (their moments); this file owns *how*, once. Depth is
moment-triggered, never speculative — see the depth principle in
`principles.md`.

## Attach

The REST endpoint takes the child's internal ID, not its number:

    CHILD_ID=$(gh api repos/<owner>/<repo>/issues/<child-number> --jq .id)
    gh api repos/<owner>/<repo>/issues/<parent-number>/sub_issues \
      -X POST -F sub_issue_id="$CHILD_ID"

`<owner>/<repo>` in both commands is the PARENT's repo; the child may
live in a different repo **under the same owner only** — cross-owner
attachment is unsupported by GitHub. When lineage must cross owners
(the hives do), record it in prose where the moment's skill says to,
and say plainly that the tree is partial.

Detach: same endpoint with `-X DELETE`. Reorder:
`PATCH .../sub_issues/priority` with `sub_issue_id` and
`after_id`/`before_id`.

## Read a tree

One GraphQL query returns order, progress, and the head:

    gh api graphql -f query='{
      repository(owner: "<owner>", name: "<repo>") {
        issue(number: <parent-number>) {
          subIssues(first: 50) {
            totalCount
            nodes { number title state }
          }
        }
      }
    }'

- **Progress:** closed nodes / totalCount ("3/6 children closed").
- **Sequence head:** the first node in returned order with state OPEN
  whose earlier siblings are all CLOSED. Sub-issue order is the recorded
  order — GitHub preserves it.
- **Upward:** `issue(number: N) { parent { number } }` tells you a swept
  issue is a child, so sweeps can fold it under its parent.

`first: 50` is a deliberate page size; a unit with more than 50 children
is a design smell worth surfacing, not paginating past silently.

## Degrade loudly

If any command above fails (older GHES, missing permission, API change):
say so in the output of whatever you were producing ("sub-issue API
unavailable: <error>; reporting flat") and continue with today's flat
behavior. Depth is an upgrade, never a dependency — no skill may fail,
and no report may silently thin out, because a tree couldn't be read.
