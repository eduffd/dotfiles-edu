# Config validation

The user edits a config file and checks the config still works before applying it: evaluation, a build plan that touches nothing, the live symlinks still pointing at this checkout, and the machine's one-line identities matching. Applying is `rebuild.sh`, out of scope for a verification run.

## Sub-features

- `eval-clean` `nix flake check --no-build` passes at the repo root.
- `plan-dry` `nix build .#darwinConfigurations.mac.system --dry-run` prints a plan and changes no live state.
- `chain-live` every live config resolves into this repo through the symlink chain.
- `label-triple` the host label matches in all three places the README names.
- `username-current` flake.nix's `user =` line equals the live macOS username.

## How to get to it (user POV)

- Edit a config file in this repo, then run the README's "Validate without applying" commands.
- The daily path is `./rebuild.sh`; a verification run never runs it.

## Driving it with plain shell

Plain shell, not tmux: these commands are not TUI drives. Run at the repo root; capture stdout/stderr into artifacts with `tee`.

Preconditions:

- cwd is the repo root; `nix` resolves (bare on PATH, or `/nix/var/nix/profiles/default/bin/nix`).
- `scripts/doctor.sh` ran ok for the chain sub-feature.

- **Evaluate.** Run `nix flake check --no-build`; if nix rejects `flake`, re-run with `--extra-experimental-features 'nix-command flakes'` after `nix` (as `bootstrap.sh` does). Expect exit 0. Capture its output.
- **Plan without applying.** Record `stat -f '%m' ~/.config ~/.config/nvim ~/.zshrc` into the artifact, run `nix build .#darwinConfigurations.mac.system --dry-run` (same flag rule as the evaluate step; expect exit 0 and plan lines ending in `(dry run)`), record the stats again, and assert before == after. The flag name is not the proof; the unchanged live-state mtimes are.
- **Live chain.** Every `live ... resolves into ...` doctor line is `ok`. If `~/.dotfiles` is missing, the unmet precondition is "first switch not yet run" - report, do not run it.
- **Label triple.** `grep -n 'darwinConfigurations."mac"' flake.nix`, `grep -n '#mac' rebuild.sh`, `grep -n '#mac' bootstrap.sh` all name the same label. Mismatch is a failure; the README documents all three must move together.
- **Username.** Extract flake.nix's single `user = "..."` line the same way `bootstrap.sh` does, compare to `whoami`. Match, or the run reports the mismatch `bootstrap.sh` would offer to fix.
- **Proof.** The artifacts carry each command, its exit code, the plan text, and the stat table.

## Gotchas

- Never `sudo`, `bootstrap.sh`, `rebuild.sh`, or `darwin-rebuild switch` in a run: `switch` applies config and Homebrew `zap` deletes unlisted packages.
- `--no-build` proves evaluation and typechecking only; the dry build covers planning. Say which layer a pass covers.
- If the host label was renamed, substitute it in both commands and all three greps together.
- Inputs are pinned by `flake.lock`; the greps run against working-tree files, so an uncommitted rename still shows in the triple check before any apply would.
