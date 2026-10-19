#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
# sudo may not see /run/current-system/sw/bin, so resolve the binary first.
DARWIN_REBUILD="$(command -v darwin-rebuild || true)"
if [ -z "$DARWIN_REBUILD" ] && [ -x /run/current-system/sw/bin/darwin-rebuild ]; then
  DARWIN_REBUILD=/run/current-system/sw/bin/darwin-rebuild
fi
exec sudo "${DARWIN_REBUILD:-darwin-rebuild}" switch --flake ~/.dotfiles#mac
