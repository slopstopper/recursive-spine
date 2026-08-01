#!/usr/bin/env bash
# Static tier of the skill behavioral evals (#68). Reads evals/*.json from CWD
# and checks each anchored assertion against skills/<skill>/SKILL.md.
#
#   ✓            the assertion holds
#   ✗ FAIL       anchors resolve, but the required order is violated
#   ⚠ UNRESOLVED anchor text is no longer in the skill — a human must look
#
# Exits non-zero on FAIL or UNRESOLVED. Unlike spine-audit.sh / spine-doctor.sh
# (report-only, always exit 0), this one gates.
#
#   scripts/spine-eval.sh
#   scripts/spine-eval.sh --coverage --min-covered N
set -uo pipefail

MODE="check"; MIN_COVERED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --coverage)    MODE="coverage" ;;
    --min-covered) shift; MIN_COVERED="${1:-0}" ;;
    *) echo "spine-eval: unknown argument '$1'" >&2; exit 2 ;;
  esac
  shift
done

# Hard-wrapped prose: collapse to one lowercase line before matching, or every
# rule that spans a line break reports UNRESOLVED forever. Needles (anchor,
# before) go through the same pipeline via norm(), so a phrase copy-pasted
# out of hard-wrapped Markdown still matches the flattened haystack.
flatten()   { tr '\n' ' ' < "$1" | tr -s ' ' | tr '[:upper:]' '[:lower:]'; }
norm()      { printf '%s' "$1" | tr '\n' ' ' | tr -s ' ' | tr '[:upper:]' '[:lower:]'; }
pos()       { awk -v s="$1" -v n="$2" 'BEGIN{print index(s,n)}'; }
last_seen() { git log -S"$1" --format=%h -1 -- "$2" 2>/dev/null | head -1; }

shopt -s nullglob
EVALS=(evals/*.json)
if [ "${#EVALS[@]}" = 0 ]; then
  echo "spine-eval: no eval files in evals/ (cwd=$(pwd))" >&2
  exit 1
fi

FAILS=0; UNRES=0; TOTAL=0

for f in "${EVALS[@]}"; do
  if ! jq -e . "$f" >/dev/null 2>&1; then
    echo "✗ MALFORMED JSON  $f (invalid JSON, could not be parsed)"
    FAILS=$((FAILS + 1)); continue
  fi
  skill="$(jq -r '.skill // empty' "$f")"
  md="skills/$skill/SKILL.md"
  if [ ! -f "$md" ]; then
    echo "✗ MISSING SKILL  $skill (named by $f)"
    FAILS=$((FAILS + 1)); continue
  fi

  flat="$(flatten "$md")"
  n="$(jq -r '.assertions | length' "$f")"
  echo ""
  echo "$skill        $n assertions"

  i=0
  while [ "$i" -lt "$n" ]; do
    id="$(jq -r ".assertions[$i].id" "$f")"
    kind="$(jq -r ".assertions[$i].kind" "$f")"
    anchor="$(jq -r ".assertions[$i].anchor" "$f")"
    before="$(jq -r ".assertions[$i].before // empty" "$f")"
    why="$(jq -r ".assertions[$i].why" "$f")"
    TOTAL=$((TOTAL + 1))
    i=$((i + 1))

    a="$(pos "$flat" "$(norm "$anchor")")"
    if [ "$a" = 0 ]; then
      echo "  ⚠ UNRESOLVED  $id"
      echo "      anchor:  \"$anchor\""
      echo "      not found in $md"
      echo "      why:     $why"
      echo "      last seen at commit $(last_seen "$anchor" "$md" || true)"
      echo "      This is not a test failure. The prose this assertion guards"
      echo "      was edited or removed. Either re-anchor it to the rule's new"
      echo "      wording, or — if the rule was dropped on purpose — delete the"
      echo "      assertion in the same commit and say why in the message."
      UNRES=$((UNRES + 1)); continue
    fi

    case "$kind" in
      contains)
        echo "  ✓ $id" ;;
      precedes)
        b="$(pos "$flat" "$(norm "$before")")"
        if [ "$b" = 0 ]; then
          echo "  ⚠ UNRESOLVED  $id"
          echo "      anchor:  \"$before\"  (the 'before' side)"
          echo "      not found in $md"
          echo "      why:     $why"
          UNRES=$((UNRES + 1))
        elif [ "$a" -lt "$b" ]; then
          echo "  ✓ $id"
        else
          echo "  ✗ FAIL  $id"
          echo "      \"$anchor\" (at $a) must come before \"$before\" (at $b)"
          echo "      why:     $why"
          FAILS=$((FAILS + 1))
        fi ;;
      *)
        echo "  ✗ FAIL  $id — unknown assertion kind '$kind'"
        FAILS=$((FAILS + 1)) ;;
    esac
  done
done

echo ""
echo "spine-eval — $TOTAL assertions, $FAILS failed, $UNRES unresolved"
{ [ "$FAILS" = 0 ] && [ "$UNRES" = 0 ]; } || exit 1
