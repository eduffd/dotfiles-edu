---
name: verify
description: Drive and prove this dotfiles machine setup the way a user does - the zsh/starship shell, the Neovim TUI, and the Pi terminal agent - through isolated tmux PTY sessions, capture evidence, and clean up. Use for /verify, after editing any config in this repo, or when asked whether the machine setup still works.
---

# Verify the machine setup

The app is the configured macOS terminal environment this repo produces. There is no server. Users touch the zsh+starship prompt, Neovim, and Pi terminal extensions; each drive is its own tmux session on a private socket.

**Never run during a verify run:** `bootstrap.sh`, `rebuild.sh`, `sudo`, `darwin-rebuild`, `brew`, or the `cc` / `co` aliases. `switch` applies config with sudo and a Homebrew `zap` that removes unlisted packages. It is destructive, out of scope. The safe config layer is the dry-run pair below, and the drive tools are already installed live.

## Launch

Launch contract for a CLI/TUI setup: prove the config once, then start each drive in its own isolated PTY.

1. Validate the config without applying (commands from the README quickstart, run at the repo root):

   ```sh
   nix flake check --no-build
   nix build .#darwinConfigurations.mac.system --dry-run
   ```

   If `nix` rejects those subcommands, add `--extra-experimental-features 'nix-command flakes'` right after `nix`, as `bootstrap.sh` does on this machine. Ready = both exit 0. If the host label was renamed, substitute it in the second command. Do not trust the `--dry-run` name: before and after it, record `stat -f '%m' ~/.config ~/.config/nvim` and confirm the values are unchanged. A dry run that changed live state is a failed launch contract, not a pass.

2. Start each drive with the helper (fresh scratch dir, private socket, fresh PTY):

   ```sh
   .claude/skills/verify/scripts/new-drive.sh shell-drive -- zsh -il
   ```

   It prints `SOCK=`, `SESSION=`, `ROOT=`; the session's scratch dir is exported to it as `$DROOT`. Ready per drive = the pane reaches the app state the feature file names (prompt glyph for zsh, status line for nvim, title or transcript row for Pi).

Teardown is in Cleanup. Never attach to a tmux session the user already runs; never drive the live `~/.pi/agent` directory.

## Doctor

Run first whenever anything looks off:

```sh
.claude/skills/verify/scripts/doctor.sh
```

Read-only. It answers: the checkout is live as `~/.dotfiles`, every live config (`nvim`, `wezterm`, Claude settings, Pi theme/extensions) resolves into this repo through the symlink chain, the generated starship config exists, the drive tools (`zsh starship nvim tmux git`) are on PATH, `nix flake check --no-build` evaluates, and `pi` version matches the pin `tests/pi-calm.test.sh` asserts (a drift is a warning, not a failure). Exit 0 means drives may start.

## Drive

Harness: tmux on a private `-L` socket per drive. Recipe:

```sh
tmux -L "$SOCK" send-keys -t "$SESSION" -l 'sleep 1.2'
tmux -L "$SOCK" send-keys -t "$SESSION" Enter
.claude/skills/verify/scripts/wait-for.sh "$SOCK" "$SESSION" '❯' 12
.claude/skills/verify/scripts/capture.sh "$SOCK" "$SESSION" after-cmd "artifacts/$FEATURE"
```

Stable handles to assert against, not coordinates or tab order:

- zsh/starship: the prompt glyph `❯` and the segment strings (`[1s]`, branch name, `*`) in the captured pane.
- nvim: pane text plus the SGR escapes in the `.ansi.txt` capture; the status line for keymaps.
- terminal title: this tmux records an OSC-2 title under `#T`, so `tmux -L "$SOCK" display-message -p '#T'` is the handle, not `#W`.

Read `features/README.md` before driving, then the feature file matching what changed. Drive every sub-feature its file lists unless its preconditions are unmet. If you cannot identify the right file, pick the one whose entry points the change touches, and say so.

## Evidence

Artifacts go to `.claude/skills/verify/artifacts/<feature>/<label>.txt` (+ `.ansi.txt` from capture.sh). They survive cleanup. Never commit them; they are gitignored.

Proof standards:

- Exercise the real user path: type into the PTY the way the user types. Do not substitute builtin introspection (`alias`, `:checkhealth`) for driving behavior.
- Capture the action and the resulting state, not just the final screen: the `send-keys` step first, the changed state after.
- Verify side effects alongside what is visible: cwd moved, file staged, git ref switched, preference file content, live-state mtimes unchanged.
- Persisted state needs a second read-only view: reopen the file, re-render the prompt, re-run the command.
- Color proof asserts the SGR sequences in the `.ansi.txt` capture; plain text alone cannot show a theme.
- A proof that drives one entry point is incomplete when the feature file lists others; report which entry points were covered.
- Unreachable path = attempted command plus the unmet precondition, reported as a failure. Never weaken a journey to make it pass.

## Cleanup

- Kill only tmux sessions this run started: `tmux -L "$SOCK" kill-server` for each printed `SOCK=`. Never kill by process name; never touch the user's own tmux sockets.
- `rm -rf "$ROOT"` for each scratch root `new-drive.sh` printed.
- Confirm untouched live state: `stat -f '%m' ~/.config ~/.config/nvim` unchanged from pre-run values and `readlink ~/.dotfiles` still this repo. The live `~/.zshrc` writes history despite the drive's `unset HISTFILE`, so `~/.zsh_history` grows by exactly one entry (`: <ts>:0;unset HISTFILE`) from a shell drive: cleanup deletes that one entry and confirms the line count returned to its pre-run value. Anything else in history = unmet precondition, report it.
- Evidence survives: after teardown, `ls .claude/skills/verify/artifacts` must still show every artifact this run wrote.

## Helpers

All four are executable, in `scripts/`, each self-documented by its usage line:

- `doctor.sh` — run before anything looks off; exit 0 gates drives.
- `new-drive.sh <name> [--rows N] [--cols N] -- <command...>` — start one isolated drive; prints SOCK/SESSION/ROOT.
- `wait-for.sh <socket> <session> <text> [secs]` — wait for an observable string; exit 1 = timeout = failed proof.
- `capture.sh <socket> <session> <label> <artifact-dir>` — full-scrollback plain + ANSI captures.
