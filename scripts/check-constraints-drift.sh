#!/usr/bin/env bash
# Drift gate for the connective-tissue vertebra (#33).
#
# Every constraints-copy block must byte-match the canonical constraints
# file AT THE SHA its provenance line pins:
#
#   <!-- constraints-copy: <path> @ <sha> -->
#   <!-- constraints:begin -->
#   ...copied block...
#   <!-- constraints:end -->
#
# Sha-pinning keeps merged docs green when the canonical file evolves;
# stale pins are the digest's concern, not CI's. Requires full git
# history (fetch-depth: 0 in CI).
#
# Exits 0 when all copies match, 1 otherwise, naming the doc, the pinned
# sha, and the exact diff. Templates documenting the marker format are
# excluded by pathspec below.
set -u

first_block() {
  awk '/<!-- constraints:begin -->/{f=1;next} /<!-- constraints:end -->/{exit} f'
}

fail=0
for file in $(git grep -l -e 'constraints-copy:' -- ':!scripts/' ':!reference/templates/' 2>/dev/null); do
  while IFS=: read -r ln _; do
    line=$(sed -n "${ln}p" "$file")
    src=$(printf '%s\n' "$line" | sed -nE 's/.*constraints-copy: *([^ ]+) @ ([0-9a-f]{7,40}) .*/\1/p')
    sha=$(printf '%s\n' "$line" | sed -nE 's/.*constraints-copy: *([^ ]+) @ ([0-9a-f]{7,40}) .*/\2/p')
    if [ -z "$src" ] || [ -z "$sha" ]; then
      # Docs that DOCUMENT the marker format (specs, plans, frames) contain
      # placeholder mentions like "@ <commit sha>" — note them loudly, but
      # only well-formed markers are verifiable claims.
      echo "DRIFT-GATE NOTE: $file:$ln — unparseable constraints-copy mention (documentation? a real marker must be: constraints-copy: <path> @ <hex sha>)"
      continue
    fi
    canonical=$(git show "${sha}:${src}" 2>/dev/null | first_block)
    if [ -z "$canonical" ]; then
      echo "DRIFT-GATE FAIL: $file:$ln — cannot read $src @ $sha (bad sha, bad path, or shallow clone; CI needs fetch-depth: 0)"
      fail=1
      continue
    fi
    copied=$(tail -n +"$ln" "$file" | first_block)
    if [ "$copied" != "$canonical" ]; then
      echo "DRIFT-GATE FAIL: $file:$ln — copy drifted from $src @ $sha:"
      diff <(printf '%s\n' "$canonical") <(printf '%s\n' "$copied") | sed 's/^/    /'
      fail=1
    fi
  done < <(grep -n -e 'constraints-copy:' "$file")
done
exit $fail
