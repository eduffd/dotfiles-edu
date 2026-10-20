# Shell prompt and aliases

Open a terminal and the starship prompt is already there: a purple `❯` after success, red `❯` after failure, branch and status segments inside a git repo, and a duration segment after slow commands. The config's typed shortcuts (`..`, `m`, `add`) and keybinding (Ctrl+F accepts autosuggestion ghost text) work while typing.

## Sub-features

- `prompt-success` a purple `❯` follows a successful command.
- `prompt-error` a red `❯` follows a failed command.
- `prompt-git` a dirty git directory shows the branch name and a status marker in the prompt.
- `prompt-duration` a command over the default threshold shows a duration segment (`2s` after a 2.2s sleep).
- `alias-dotdot` `..` moves up one directory.
- `alias-m` `m` switches the branch to `main` (driven in a scratch fixture only).
- `alias-add` `add` runs `git add .` (driven in a scratch fixture only).
- `autosuggest-accept` Ctrl+F accepts ghost text taken from an earlier command in the same session.
- `syntax-highlight` a valid typed command echoes in green (ANSI capture).

## How to get to it (user POV)

- Open any terminal window; the prompt renders with no typing.
- Type `..` instead of `cd ..`, or `m` inside a git directory.
- Run a command, then start the same command again and press Ctrl+F before finishing it.

## Driving it with tmux

Preconditions:

- `scripts/doctor.sh` ran ok.
- The drive starts with `scripts/new-drive.sh shell-drive -- zsh -il`. Immediately after launch, type `unset HISTFILE` as the first line: `scripts/new-drive.sh` cannot redirect the history file because the live `~/.zshrc` re-assigns `HISTFILE` after the environment, so unsetting inside the session is what keeps the live `~/.zsh_history` untouched.
- Fixture (send as one literal line, then Enter; count gate `❯` = 3): `git init -b experiment "$DROOT/work" >/dev/null && printf 'seed\n' > "$DROOT/work/seed.md" && printf 'x\n' > "$DROOT/work/dirty.md" && cd "$DROOT/work" && git add seed.md && git -c user.name=verify -c user.email=verify@invalid commit -qm seed && git update-ref refs/heads/main HEAD`
- Gate every completed command with the prompt-line count: `scripts/wait-for.sh "$SOCK" "$SESS" '❯' 12 N+1` where N is the count of prompt lines rendered so far (each completed command adds one fresh `❯` line; waiting for a fixed single `❯` matches the stale pre-command state and races). Capture with `scripts/capture.sh` into `artifacts/shell/`.

- **History guard.** First typed line after launch: `send-keys -l 'unset HISTFILE'` + Enter; count gate `❯` = 2.
- **Duration + success symbol.** `send-keys -l 'sleep 2.2'` + Enter; count gate `❯` = 4; then `wait-for.sh "$SOCK" "$SESS" '2s' 5`; capture `duration-step`. The prompt line carries the `2s` segment (config sets `cmd_duration.format = "[$duration]($style) "`, starship styles without literal brackets), and its `❯` renders purple in the ANSI capture.
- **Error symbol.** `send-keys -l 'false'` + Enter; count gate `❯` = 5; capture `prompt-error`. The ANSI capture wraps that `❯` in `31m` (starship's red); success prompts carry `35m` (purple).
- **Git segments.** In `$DROOT/work` (branch `experiment`, one untracked file; count gate `❯` = 3 already proves the fixture completed): capture `prompt-git`. Plain capture contains the line `work on  experiment [?]` (starship renders branch plus status inside `[]`).
- **alias m.** `send-keys -l 'm'` + Enter; count gate `❯` = 6; capture `prompt-main`. It shows `Switched to branch 'main'` and the prompt line `work on  main [?]`; side effect confirmed by `send-keys -l 'git rev-parse --abbrev-ref HEAD'` + Enter, count gate `❯` = 7, capture `branch-confirm` with output line `main`.
- **alias add.** `send-keys -l 'add'` + Enter; count gate `❯` = 8; then `send-keys -l 'git status --porcelain'` + Enter; count gate `❯` = 9; capture `add-effect`. Output carries `A  dirty.md` (git porcelain: two spaces) and the prompt marker moved from `[?]` to `[+]`.
- **alias `..`.** `send-keys -l 'cd "$DROOT/work"'` + Enter (count gate 10), then `send-keys -l '..'` + Enter (count gate 11; the prompt loses the git segments once cwd is outside the repo), then `pwd` + Enter (count gate 12); capture `dotdot-pwd`. The `pwd` line reads the scratch root without `/work`.
- **Autosuggest.** `send-keys -l 'echo verify-me'` + Enter (count gate 13); then `send-keys -l 'echo '` with no Enter, and capture `ghost-step` (the ANSI capture carries the ghost `verify-me` in a dim SGR); then `send-keys C-f` (the bound autosuggest-accept), `send-keys Enter`, count gate `❯` = 14; capture `autosuggest`. The output line `verify-me` proves the accept ran the full command.
- **Syntax highlight.** In the ANSI capture of any `echo` step, the echoed command line carries a green-family SGR on `echo` (zsh syntax highlighting valid-command color).
- **Proof.** The named captures together prove success vs error symbols, git segments, duration, all three aliases' effects, and the keybinding. Record feature IDs and the covered entry point (the typed prompt path) in each capture label.

## Gotchas

- Never type `cc` or `co` in any drive: they launch `claude --dangerously-skip-permissions` / `codex --full-auto`. They are in the alias set but deliberately undriven; report them as configured-but-not-exercised.
- `m` in the real repo switches the user's live branch (this checkout sits on a feature branch). Drive it in `$DROOT/work` only.
- `push`/`pull` aliases hit the network. Out of scope; report as skipped with the reason, not verified via `alias` output.
- The live `~/.zshrc` (home-manager generated) assigns `HISTFILE` explicitly, so an env prefix on the launch command cannot redirect it. The drive must type `unset HISTFILE` as its first line. That line itself gets recorded (one entry, `: <ts>:0;unset HISTFILE`); cleanup deletes exactly that entry and confirms the line count returns to its pre-run value. Commands after the unset never reach the file.
- Autosuggestions read this session's history; seed the source command in the same drive session.
- starship config is generated by home-manager from `home.nix`; a prompt change needs a `switch`, which verify never runs. This map proves the live behavior against what `home.nix` declares now.
- A new prompt only renders after a command completes; wait on the `❯` glyph, not a sleep.
- The fixture sets `-b experiment` explicitly because `git init` default branch varies by machine.
