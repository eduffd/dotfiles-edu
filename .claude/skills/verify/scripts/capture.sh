#!/usr/bin/env bash
# capture.sh <socket> <session> <label> <artifact-dir>
# Writes the full scrollback as <artifact-dir>/<label>.txt (plain) and
# <label>.ansi.txt (SGR sequences preserved, for color proof).
set -u
[ "$#" -eq 4 ] || { printf 'usage: capture.sh <socket> <session> <label> <artifact-dir>\n' >&2; exit 1; }
sock=$1; sess=$2; label=$3; adir=$4
mkdir -p "$adir"
tmux -L "$sock" capture-pane -p -S - -t "$sess" > "$adir/$label.txt"
tmux -L "$sock" capture-pane -ep -S - -t "$sess" > "$adir/$label.ansi.txt"
printf 'wrote: %s %s\n' "$adir/$label.txt" "$adir/$label.ansi.txt"
