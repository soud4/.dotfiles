#!/usr/bin/env bash
# Generated documentation.
#
# Writes docs/reference/{keys,features,dependencies,modules}.md from the live
# configuration: the key model from the broker, the feature arbitration from the
# registry, the load order from the graph.
#
# Usage:
#   scripts/gendoc.sh            write the reference pages
#   scripts/gendoc.sh --check    report drift and broken links; exit 1 if any
set -uo pipefail

CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "--check" ]]; then
  probe='
local g = require("dohwa.gendoc")
local problems = {}
for _, name in ipairs(g.check()) do
  problems[#problems+1] = "desactualizado: docs/reference/" .. name .. ".md"
end
local broken, checked = g.broken_links()
for _, link in ipairs(broken) do problems[#problems+1] = "enlace roto: " .. link end
for _, miss in ipairs(g.missing_sections()) do problems[#problems+1] = "sin documentar: " .. miss end
io.write(("%d enlaces comprobados\n"):format(checked))
if #problems == 0 then
  io.write("OK\n")
else
  io.write(table.concat(problems, "\n") .. "\n")
  io.write(("%d problema(s)\n"):format(#problems))
end
'
  output=$(cd "$CONFIG" && nvim --headless -c "lua $probe" -c "qa!" 2>&1 | tr -d '\r')
  printf '%s\n' "$output"
  [[ $output == *OK* ]] && exit 0
  exit 1
fi

cd "$CONFIG" && nvim --headless \
  -c 'lua local w, f = require("dohwa.gendoc").write(); for _, p in ipairs(w) do io.write("escrito  " .. vim.fn.fnamemodify(p, ":.") .. "\n") end; for _, e in ipairs(f) do io.write("FALLO    " .. e .. "\n") end; io.write(#f == 0 and "OK\n" or "\n")' \
  -c 'qa!' 2>&1 | tr -d '\r'
