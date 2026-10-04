#!/usr/bin/env bash
# Disable matrix.
#
# Switches off each module on its own and starts Neovim headless, checking that
# nothing errors and that every non-optional feature still has an
# implementation. This is the test for the one property the whole design exists
# to provide: removing a module must not break the others.
#
# Usage:  scripts/matrix.sh [loader]     loader defaults to lazy
set -uo pipefail

LOADER="${1:-lazy}"
CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES=$(cd "$CONFIG/lua/modules" && find . -name '*.lua' | sed 's|^\./||; s|\.lua$||; s|/|.|g' | sort)

probe='
local d = require("dohwa")
local problems = {}
for _, m in ipairs(d:names()) do
  local mod = d.modules[m]
  if mod.state == "error" then problems[#problems+1] = m .. ": " .. tostring(mod.reason) end
end
for _, name in ipairs(d.registry:names()) do
  local f = d.registry:get(name)
  if not f:winner() and not f.optional then problems[#problems+1] = "orphan feature " .. name end
end
for _, r in ipairs(d.keys:conflicts().rejected) do
  problems[#problems+1] = "key " .. r.lhs .. " " .. r.reason
end
for _, msg in ipairs(d.messages) do
  if msg.level == "error" then problems[#problems+1] = msg.source .. ": " .. msg.message end
end
io.write(#problems == 0 and "OK" or ("FAIL " .. table.concat(problems, " | ")))
'

run() {
  DOHWA_LOADER="$LOADER" DOHWA_DISABLE="$1" \
    nvim --headless -c "lua $probe" -c "qa!" 2>&1 | tr -d '\r'
}

printf 'disable matrix  ·  loader=%s\n\n' "$LOADER"
failures=0

printf '  %-22s ' "(nothing disabled)"
result=$(run "")
printf '%s\n' "$result"
[[ $result == OK ]] || failures=$((failures + 1))

for module in $MODULES; do
  printf '  %-22s ' "-$module"
  result=$(run "$module")
  printf '%s\n' "$result"
  [[ $result == OK ]] || failures=$((failures + 1))
done

printf '\n  %-22s ' "(everything off)"
result=$(run "$(echo "$MODULES" | paste -sd,)")
printf '%s\n' "$result"
[[ $result == OK ]] || failures=$((failures + 1))

# The documentation is part of the configuration: a generated reference that no
# longer matches the live model is a failure like any other. Runs with nothing
# disabled, so it describes the real configuration.
printf '\n  %-22s ' "(docs up to date)"
docs=$("$CONFIG/scripts/gendoc.sh" --check 2>&1 | tr -d '\r')
if [[ $docs == *OK* ]]; then
  printf 'OK\n'
else
  printf 'FAIL %s\n' "$(echo "$docs" | tr '\n' ' ')"
  failures=$((failures + 1))
fi

printf '\n%d failure(s)\n' "$failures"
exit $((failures > 0))
