#!/usr/bin/env bash
# Offline test for spine-digest.sh: stubs `gh` on PATH and asserts structure,
# the failure path, exit codes, and aging-deferral sort order.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

overall_fail=0

# ---------------------------------------------------------------------------
# Scenario 1: all repos sweep successfully (baseline structure check).
# ---------------------------------------------------------------------------
run_scenario_all_succeed() {
  local tmp out fail=0
  tmp="$(mktemp -d)"

  cat > "$tmp/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"issue list"*"--label deferred"*) echo '[{"number":7,"title":"old thing","createdAt":"2026-06-01T00:00:00Z"}]' ;;
  *"api"*"/milestones"*)             echo '[{"title":"M1","number":1,"open_issues":2,"updated_at":"2026-05-01T00:00:00Z"}]' ;;
  *"issue list"*"--assignee"*)       echo '[]' ;;
  *)                                  echo '[]' ;;
esac
STUB
  chmod +x "$tmp/gh"

  out="$(PATH="$tmp:$PATH" SPINE_REPOS="acme/one acme/two" SPINE_DEFERRAL_LABEL=deferred \
         SPINE_STALL_DAYS=21 GH_TOKEN=x bash "$HERE/spine-digest.sh" 2>/dev/null)"

  grep -q "^# Spine digest — " <<<"$out" || { echo "FAIL[all-succeed]: no title heading"; fail=1; }
  grep -q "acme/one" <<<"$out"          || { echo "FAIL[all-succeed]: repo one missing"; fail=1; }
  grep -q "acme/two" <<<"$out"          || { echo "FAIL[all-succeed]: repo two missing"; fail=1; }
  grep -q "#7"       <<<"$out"          || { echo "FAIL[all-succeed]: aging deferral #7 missing"; fail=1; }
  grep -Eq "swept 2/2" <<<"$out"        || { echo "FAIL[all-succeed]: denominator wrong"; fail=1; }

  rm -rf "$tmp"
  [ "$fail" = 0 ] && echo "PASS: spine-digest structure (all succeed)" || return 1
}

# ---------------------------------------------------------------------------
# Scenario 2: one repo unreachable -> FAILED line, partial denominator,
# exit code 0 (since at least one repo still swept).
# ---------------------------------------------------------------------------
run_scenario_partial_failure() {
  local tmp out rc fail=0
  tmp="$(mktemp -d)"

  cat > "$tmp/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"api repos/acme/bad"*)             exit 1 ;;
  *"api repos/acme/ok"*)              echo '"acme/ok"' ;;
  *"issue list"*"--label deferred"*)  echo '[]' ;;
  *"api"*"/milestones"*)              echo '[]' ;;
  *)                                   echo '[]' ;;
esac
STUB
  chmod +x "$tmp/gh"

  out="$(PATH="$tmp:$PATH" SPINE_REPOS="acme/ok acme/bad" SPINE_DEFERRAL_LABEL=deferred \
         SPINE_STALL_DAYS=21 GH_TOKEN=x bash "$HERE/spine-digest.sh" 2>/dev/null)"
  rc=$?

  grep -q "FAILED: acme/bad" <<<"$out" || { echo "FAIL[partial-failure]: no FAILED line for acme/bad"; fail=1; }
  grep -Eq "swept 1/2" <<<"$out"       || { echo "FAIL[partial-failure]: denominator not 1/2"; fail=1; }
  [ "$rc" -eq 0 ]                      || { echo "FAIL[partial-failure]: exit code $rc, expected 0"; fail=1; }

  rm -rf "$tmp"
  [ "$fail" = 0 ] && echo "PASS: partial failure path (FAILED line, swept 1/2, exit 0)" || return 1
}

# ---------------------------------------------------------------------------
# Scenario 3: every repo unreachable -> swept 0/N, exit code 2.
# ---------------------------------------------------------------------------
run_scenario_all_fail() {
  local tmp out rc fail=0
  tmp="$(mktemp -d)"

  cat > "$tmp/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"api repos/"*) exit 1 ;;
  *)               echo '[]' ;;
esac
STUB
  chmod +x "$tmp/gh"

  out="$(PATH="$tmp:$PATH" SPINE_REPOS="acme/one acme/two" SPINE_DEFERRAL_LABEL=deferred \
         SPINE_STALL_DAYS=21 GH_TOKEN=x bash "$HERE/spine-digest.sh" 2>/dev/null)"
  rc=$?

  grep -Eq "swept 0/2" <<<"$out" || { echo "FAIL[all-fail]: denominator not 0/2"; fail=1; }
  [ "$rc" -eq 2 ]                || { echo "FAIL[all-fail]: exit code $rc, expected 2"; fail=1; }

  rm -rf "$tmp"
  [ "$fail" = 0 ] && echo "PASS: all-fail path (swept 0/2, exit 2)" || return 1
}

# ---------------------------------------------------------------------------
# Scenario 4: aging deferrals are sorted oldest-first.
# #2 is older (createdAt 2026-01-01), #1 is newer (createdAt 2026-06-01).
# #2's row must appear before #1's row.
# ---------------------------------------------------------------------------
run_scenario_sort_order() {
  local tmp out fail=0
  tmp="$(mktemp -d)"

  cat > "$tmp/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"api repos/acme/one"*)             echo '"acme/one"' ;;
  *"issue list"*"--label deferred"*)  echo '[{"number":1,"title":"newer","createdAt":"2026-06-01T00:00:00Z"},{"number":2,"title":"older","createdAt":"2026-01-01T00:00:00Z"}]' ;;
  *"api"*"/milestones"*)              echo '[]' ;;
  *)                                   echo '[]' ;;
esac
STUB
  chmod +x "$tmp/gh"

  out="$(PATH="$tmp:$PATH" SPINE_REPOS="acme/one" SPINE_DEFERRAL_LABEL=deferred \
         SPINE_STALL_DAYS=21 GH_TOKEN=x bash "$HERE/spine-digest.sh" 2>/dev/null)"

  local line2 line1
  line2="$(grep -n "#2" <<<"$out" | head -1 | cut -d: -f1)"
  line1="$(grep -n "#1" <<<"$out" | head -1 | cut -d: -f1)"

  if [ -z "$line2" ] || [ -z "$line1" ]; then
    echo "FAIL[sort-order]: expected both #1 and #2 rows in output"
    fail=1
  elif [ "$line2" -ge "$line1" ]; then
    echo "FAIL[sort-order]: #2 (older) did not appear before #1 (newer)"
    fail=1
  fi

  rm -rf "$tmp"
  [ "$fail" = 0 ] && echo "PASS: aging deferrals sorted oldest-first" || return 1
}

# ---------------------------------------------------------------------------
# Scenario 5: a deferral title with a backslash escape sequence (e.g.
# "C:\config") and a pipe character must not truncate the digest (via %b
# backslash interpretation) or corrupt the Markdown table (via unescaped |).
# The second repo's content must still be present after the hazardous title.
# ---------------------------------------------------------------------------
run_scenario_hazardous_title() {
  local tmp out fail=0
  tmp="$(mktemp -d)"

  cat > "$tmp/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"api repos/acme/one"*)             echo '"acme/one"' ;;
  *"api repos/acme/two"*)             echo '"acme/two"' ;;
  *"issue list -R acme/one"*"--label deferred"*) echo '[{"number":9,"title":"restore C:\\config | urgent","createdAt":"2026-06-01T00:00:00Z"}]' ;;
  *"issue list -R acme/two"*"--label deferred"*) echo '[{"number":11,"title":"second repo item","createdAt":"2026-06-01T00:00:00Z"}]' ;;
  *"api"*"/milestones"*)              echo '[]' ;;
  *)                                   echo '[]' ;;
esac
STUB
  chmod +x "$tmp/gh"

  out="$(PATH="$tmp:$PATH" SPINE_REPOS="acme/one acme/two" SPINE_DEFERRAL_LABEL=deferred \
         SPINE_STALL_DAYS=21 GH_TOKEN=x bash "$HERE/spine-digest.sh" 2>/dev/null)"

  grep -q "acme/two" <<<"$out"          || { echo "FAIL[hazardous-title]: repo two section missing (truncated by %b)"; fail=1; }
  grep -q "#11"      <<<"$out"          || { echo "FAIL[hazardous-title]: repo two's deferral #11 missing (truncated by %b)"; fail=1; }
  grep -q "second repo item" <<<"$out"  || { echo "FAIL[hazardous-title]: repo two's title text missing"; fail=1; }
  grep -q "restore C:.config" <<<"$out" || { echo "FAIL[hazardous-title]: hazardous title text missing/mangled"; fail=1; }
  grep -Fq 'config \| urgent' <<<"$out" || { echo "FAIL[hazardous-title]: pipe in title not escaped"; fail=1; }
  grep -Eq "swept 2/2" <<<"$out"        || { echo "FAIL[hazardous-title]: denominator wrong (indicates truncation)"; fail=1; }

  rm -rf "$tmp"
  [ "$fail" = 0 ] && echo "PASS: hazardous title (backslash + pipe) does not truncate or corrupt digest" || return 1
}

overall_fail=0
run_scenario_all_succeed    || overall_fail=1
run_scenario_partial_failure || overall_fail=1
run_scenario_all_fail       || overall_fail=1
run_scenario_sort_order     || overall_fail=1
run_scenario_hazardous_title || overall_fail=1

if [ "$overall_fail" = 0 ]; then
  echo "PASS: all spine-digest scenarios"
  exit 0
else
  echo "FAIL: one or more spine-digest scenarios failed (see above)"
  exit 1
fi
