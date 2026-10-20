#!/usr/bin/env bash
# doctor.sh - read-only "is an instance worth driving?" for the verify skill.
# Confirms the live machine still runs this checkout and the drive tools exist.
# Writes nothing. One line per check. Exit 0 = drives may start.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"
NIX="$(command -v nix 2>/dev/null || true)"
[ -z "$NIX" ] && [ -x /nix/var/nix/profiles/default/bin/nix ] && NIX=/nix/var/nix/profiles/default/bin/nix

rc=0
ok()   { printf 'ok - %s\n' "$*"; }
bad()  { printf 'not ok - %s\n' "$*"; rc=1; }
warn() { printf 'warn - %s\n' "$*"; }

ok "repo root: $ROOT"

live="$(readlink "$HOME/.dotfiles" 2>/dev/null || true)"
if [ -n "$live" ] && [ "$(realpath "$live" 2>/dev/null || true)" = "$ROOT" ]; then
  ok "~/.dotfiles -> $ROOT"
else
  bad "~/.dotfiles missing or points elsewhere (live: ${live:-none})"
fi

for f in .config/nvim/init.lua .config/wezterm/wezterm.lua .claude/settings.json .pi/agent/themes/rose-pine-moon.json .pi/agent/extensions/calm/index.ts; do
  tgt="$(realpath "$HOME/$f" 2>/dev/null || true)"
  case "$tgt" in
    "$ROOT"/home/*) ok "live $HOME/$f resolves into $ROOT" ;;
    *) bad "live $HOME/$f does not resolve into $ROOT (got ${tgt:-broken})" ;;
  esac
done

if [ -f "$HOME/.config/starship.toml" ]; then
  ok "generated starship config present (~/.config/starship.toml)"
else
  bad "no ~/.config/starship.toml: home-manager has not applied the prompt yet"
fi

for c in zsh starship nvim tmux git; do
  p="$(command -v "$c" || true)"
  [ -n "$p" ] && ok "driver $c=$p" || bad "driver $c not on PATH"
done

if p="$(command -v pi || true)"; [ -n "$p" ]; then
  ver="$(pi --version 2>/dev/null || true)"
  pin="$(grep -oE '0\.[0-9]+\.[0-9]+' "$ROOT/tests/pi-calm.test.sh" 2>/dev/null | head -1)"
  if [ -n "$ver" ] && [ -n "$pin" ] && [ "$ver" != "$pin" ]; then
    warn "pi $ver differs from pin $pin asserted by tests/pi-calm.test.sh"
  else
    ok "pi=$p version=$ver"
  fi
else
  warn "pi not installed: Pi extension features cannot be driven"
fi

out="$( (cd "$ROOT" && "$NIX" --extra-experimental-features 'nix-command flakes' flake check --no-build) 2>&1 )"
if [ $? -eq 0 ]; then
  ok "nix flake check --no-build"
else
  bad "nix flake check failed: $(printf '%s\n' "$out" | tail -1)"
fi

if [ "$rc" -eq 0 ]; then
  ok "doctor: drives are safe to start"
else
  printf 'doctor: fix the not-ok lines before driving\n'
fi
exit "$rc"
