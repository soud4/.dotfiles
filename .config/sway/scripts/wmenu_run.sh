#!/bin/bash
cache="${XDG_CACHE_HOME:-$HOME/.cache}/wmenu_run"

wmenu_opts=(
    -i
    -N "#040404"
    -n "#e6e1cf"
    -M "#040404"
    -m "#e6e1cf"
    -S "#fefefe"
    -s "#040404"
    -f "Inter Bold 8"
    -p "Choose Program: "
)

IFS=:
if stest -dqr -n "$cache" $PATH; then
    stest -flx $PATH | sort -u | tee "$cache" | wmenu "${wmenu_opts[@]}"
else
    wmenu "${wmenu_opts[@]}" < "$cache"
fi | xargs -r swaymsg exec
