#!/usr/bin/env bash
# wait-for.sh <socket> <session> <fixed-text> [timeout-seconds] [min-count]
# Polls the full scrollback until a fixed string is seen on at least min-count
# lines (1 by default). Exit 0 = seen, 1 = timed out.
# Count gates are how step waits work: each completed command adds a fresh prompt
# line, so "wait for N+1 prompt lines" cannot match the stale pre-command state.
set -u
[ "$#" -ge 3 ] || { printf 'usage: wait-for.sh <socket> <session> <fixed-text> [timeout-seconds] [min-count]\n' >&2; exit 1; }
sock=$1; sess=$2; text=$3; timeout=${4:-12}; want=${5:-1}
ticks=$((timeout * 10)); i=0
while [ "$i" -lt "$ticks" ]; do
  n="$(tmux -L "$sock" capture-pane -p -S - -t "$sess" 2>/dev/null | grep -Fc -- "$text" | head -1 | tr -d ' :/')"
  [ -n "$n" ] && [ "$n" -ge "$want" ] && exit 0
  sleep 0.1; i=$((i + 1))
done
exit 1
