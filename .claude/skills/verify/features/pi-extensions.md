# Pi terminal extensions

Running the Pi coding agent updates the terminal title (idle marker, spinner while it works, check mark when done) and `/calm` toggles a quieter transcript presentation whose choice survives restarts. A user watches the window title and types `/calm`.

## Sub-features

- `title-idle` the window title reads `○ | π | <session name or cwd basename>` once Pi is up.
- `title-working` during an active run the title cycles the spinner frames `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`.
- `title-done` after the run finishes the title shows `✓ |` (errors show `✗ |`).
- `calm-toggle` `/calm` switches the presentation on, then off again.
- `calm-state` the agent dir's `calm` file holds `on` or `off` and survives a new session.
- `calm-boat` during a run Calm replaces the working row with its two-row boat widget, which reflows when the window is resized.

## How to get to it (user POV)

- Run `pi` in a terminal; the title changes without any typing.
- Type `/calm` at the Pi prompt.
- Watch the terminal tab while Pi is working.

## Driving it with tmux

Build the fixture exactly as `tests/pi-calm.test.sh`'s `test_real_pi_tui_smoke` does: copy `home/.pi/agent/extensions/calm` into `$DROOT/agent/extensions`, write the same deterministic `provider.ts`, and launch Pi with `PI_CODING_AGENT_DIR="$DROOT/agent"`, `PI_CODING_AGENT_SESSION_DIR="$DROOT/sessions"`, `PI_OFFLINE=1`, and flags `--approve --no-context-files --no-skills --no-prompt-templates -e ./provider.ts`.

Preconditions:

- `scripts/doctor.sh` ran; a `warn` about the Pi version pin is allowed here but must be reported.
- The drive starts via `scripts/new-drive.sh pi-drive --cols 100 -- <the fixture pi command above>`.
- The fixture never touches the live `~/.pi/agent`.

- **Idle title.** Wait for the Pi session to start. Run `tmux -L "$SOCK" display-message -p '#T'` and expect `○ | π |` followed by the fixture project basename. The title proof reads `#T`, not the pane.
- **Toggle on.** `send-keys -l '/calm'` + `Enter`. Wait for the command echo in the pane; then `cat "$DROOT/agent/calm"` must read `on`.
- **Working states.** `send-keys -l '/calm-smoke'` + `Enter` (the fixture command streams a deterministic reply). While the stream runs: read `#T` twice, expecting spinner frames; wait-for the boat row in the pane (the repo test asserts `\__/` in the capture); then resize-window to `-x 40 -y 30` and expect the boat row again (reflowed). After the stream: `#T` carries `✓ |`.
- **Toggle off.** `/calm` again; `cat "$DROOT/agent/calm"` reads `off`; `#T` returns to `○ |`.
- **Persistence.** After teardown of this session, a fresh drive in the same fixture agent dir starts with Calm still on/off per the file (start pi, send `/calm-smoke`, expect the boat without typing `/calm` first).
- **Quit and cleanup.** `send-keys -l '/quit'` + `Enter`, then kill the socket.
- **Proof.** The `#T` reads plus the pane captures plus the two `cat` outputs name Pi, the fixture dir, and each state; write them as artifacts under `artifacts/pi-extensions/`.

## Gotchas

- `tests/pi-calm.test.sh` pins pi `0.82.0` for its real-TUI smoke; this machine carries `pi --version` = `1.0.2`. That test fails its TUI section on this machine. Its non-TUI contract tests are wiring evidence only. Report the version drift as the reason the TUI journey fails; never claim Pi behavior from those tests alone.
- Pi needs a model to run. The offline fixture provider keeps the journey credential-free; pointed at the live agent dir without auth, the journey has an unmet precondition.
- Never point a drive at the live `~/.pi/agent` (auth, sessions, trust decisions live there).
- This tmux records an OSC-2 title under `#T`, not `#W` (`#W` shows the pane's shell label).
- `home/.pi/agent/extensions/herdr-agent-state.ts` is inert outside herdr (needs `HERDR_ENV=1` and herdr's socket). Do not expect it in these drives; the herdr multiplexer is unmapped.
- `/calm-smoke` is the fixture's command, not a stock Pi one; it exists only in the fixture provider.
