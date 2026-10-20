# Verification map

This directory is the maintained source for verifying user-facing behavior of the machine setup this repo applies. Read the index before driving, then use the matching feature file as the recipe.

## Baseline preconditions

- `scripts/doctor.sh` (relative to the skill root) exits 0 before any drive.
- Every drive starts with `scripts/new-drive.sh` so it gets a fresh scratch dir (`$DROOT`), a private tmux socket, and its own PTY. Never target a tmux session or terminal the user already runs.
- Never run `bootstrap.sh`, `rebuild.sh`, `sudo`, `darwin-rebuild`, `brew`, or the `cc` / `co` aliases in a verification run.
- Artifacts go under `.claude/skills/verify/artifacts/<feature>/` and are never committed.
- A feature whose tool is missing (doctor says so) reports failures with the unmet precondition. It does not fake a pass.

## Driving conventions

- Treat every command in a feature file as literal. Keep quoted names and flags unchanged.
- Wait for observable strings via `wait-for.sh`, never fixed sleeps, before capturing.
- Stable handles: prompt glyphs and segments, pane text, SGR sequences in `.ansi.txt` captures, tmux `#T` window title. Not coordinates or tab order.
- Mutation-style proof pairs an action capture with a second read-only view of the result.

## Proof and skip reporting

- Capture the user action and the resulting state, not just the final screen.
- Text proof reads the plain capture; color proof asserts SGR sequences in the ANSI capture; title proof reads `#T`.
- Side effects (cwd, staged files, git branch, preference file) are checked next to what is visible.
- Record the feature ID and entry point with every artifact.
- Report an unreachable path with the attempted command and the unmet precondition. Do not report a skipped entry point as verified through another path.

## Feature entry contract

Each feature file: H1 title, one user-visible paragraph, then exactly four H2s in order - `Sub-features` (short IDs, one line each), `How to get to it (user POV)` (every entry point), `Driving it with tmux` (`Preconditions:` then labeled bullets pairing user action with exact command and observable result), and `Gotchas` (traps that waste or invalidate a run). Name only user paths, stable handles, required state, commands, and observable proof.

## Features

- [Shell prompt and aliases](./shell.md) covers the starship prompt symbols and segments, the typed aliases, autosuggest accept, and syntax highlighting.
- [Neovim behavior](./neovim.md) covers the rose-pine moon theme colors, the keymaps, and markdown rendering.
- [Pi terminal extensions](./pi-extensions.md) covers the terminal-title states and the Calm presentation toggle.
- [Config validation](./nix-config.md) covers evaluating and dry-building the config without applying, the live symlink chain, and the host-label triple.

## Unmapped surfaces

Not driven yet, and why: the WezTerm GUI window itself (needs a GUI screenshot path), macOS `system.defaults` (verified only through the apply path, which is destructive), Homebrew app sets (apply path is destructive), the herdr multiplexer and its Pi agent-state integration (drivable in principle; no map yet - the integration is inert outside herdr), and Pi package sources pinned in `settings.json` (needs the network and third-party trust).
