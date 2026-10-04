#!/usr/bin/env bash
# Genera la línea del overlay de imv. Una sola línea: imv une todo con espacios.
# Se invoca en cada redibujado, así que las dimensiones se cachean por archivo+mtime.

file="$1"
idx="${2:-?}"
total="${3:-?}"
scale="${4:-}"

sep=" │ "
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/imv"
mkdir -p "$cache_dir"

name="${file##*/}"
dir="${file%/*}"
dir="${dir##*/}"

dims="?"
size="?"
if [ -f "$file" ]; then
  mtime=$(stat -c %Y "$file" 2>/dev/null)
  key=$(printf '%s %s' "$file" "$mtime" | md5sum | cut -d' ' -f1)
  cache="$cache_dir/$key"
  if [ -r "$cache" ]; then
    dims=$(cat "$cache")
  else
    dims=$(identify -format '%w×%h' "$file[0]" 2>/dev/null) || dims="?"
    [ -n "$dims" ] && printf '%s' "$dims" > "$cache"
  fi
  size=$(numfmt --to=iec --suffix=B "$(stat -c %s "$file")" 2>/dev/null)
fi

out="󰉏 ${dir}${sep}󰋩 ${idx}/${total}${sep}${name}${sep}${dims}${sep}${size}"
[ -n "$scale" ] && out="${out}${sep}${scale}%"
printf '%s' "$out"
