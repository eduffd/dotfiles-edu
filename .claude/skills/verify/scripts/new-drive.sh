#!/usr/bin/env bash
# new-drive.sh <name> [--rows N] [--cols N] -- <command...>
# Starts ONE isolated verification drive: fresh scratch dir, private tmux socket,
# fresh PTY. The command may reference $DROOT (exported inside the session).
# Prints SOCK=, SESSION=, ROOT= on stdout; pass these to capture/wait/teardown.
set -euo pipefail
name="${1:?usage: new-drive.sh <name> [--rows N] [--cols N] -- <command...>}"; shift
rows=24; cols=90
while [ "${1:-}" != "--" ]; do
  case "$1" in
    --rows) rows=$2; shift 2 ;;
    --cols) cols=$2; shift 2 ;;
    *) printf 'usage: new-drive.sh <name> [--rows N] [--cols N] -- <command...>\n' >&2; exit 1 ;;
  esac
done
shift
[ "$#" -gt 0 ] || { printf 'empty command after --\n' >&2; exit 1; }
root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-verify.${name}.XXXXXX")"
sock="verify-${name}-$$"
tmux -L "$sock" new-session -d -s "$name" -x "$cols" -y "$rows" -- "cd '$root' && export DROOT='$root' && $*"
printf 'SOCK=%s\nSESSION=%s\nROOT=%s\n' "$sock" "$name" "$root"
