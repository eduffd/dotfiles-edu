# Neovim behavior

Neovim opens with the rose-pine moon theme (no italics, transparent background), keeps the config's keymaps live, and render-markdown decorates markdown files. A user opens a file and sees these colors, presses Escape to save, Ctrl+A to select everything.

## Sub-features

- `theme-headings` markdown headings render in rose-pine hues, bold, never italic.
- `theme-text` body text is `224;222;244` on a default (transparent) background, not an opaque one.
- `keys-save` a single Escape press writes the file (`:w` mapping).
- `keys-selectall` Ctrl+A selects the whole file.
- `markdown-decor` render-markdown replaces `-` bullets with a rose `●` and puts an icon before each heading.
- `gutter-numbers` the line-number gutter is visible (absolute at the cursor line, relative elsewhere).

## How to get to it (user POV)

- Run `nvim <file>` in any terminal at any directory.
- Press Escape to save, Ctrl+A at the top of a file to select all.
- Open a `.md` file to see the markdown decorations.

## Driving it with tmux

Preconditions:

- `scripts/doctor.sh` exits 0; drive started with `scripts/new-drive.sh nvim-drive --cols 90 -- nvim probe.md` and it prints SOCK/SESSION/ROOT.
- The scratch fixture `probe.md` was written by the recipe: `printf '# Heading one\n## Heading two\n\n- bullet item\n**bold** word\n' > "$DROOT/probe.md"` before launch (the same command the drive runs under `cd "$DROOT"`).

- **Open and capture.** Send nothing extra; wait-for `Heading two`, then `scripts/capture.sh "$SOCK" "$SESSION" opened "artifacts/neovim"`. The plain capture shows a NerdFont icon glyph before each heading, `● bullet item`, and the `~` filler. The ANSI capture contains heading foregrounds `38;2;196;167;231m` (H1) and `38;2;156;207;216m` (H2), body foreground `38;2;224;222;244m`, and bullet foreground `38;2;234;154;151m`.
- **No italics.** Assert the ANSI capture contains no ESC `[3m` sequence (`grep -c $'\033\[3m'` is 0); bold `1m` is fine.
- **Transparency.** Assert the ANSI capture contains `49m` (default background restored) on non-heading lines.
- **Save key.** `tmux -L "$SOCK" send-keys -t "$SESSION" Escape` once. Wait-for `written`, then capture. The status line reads `probe.md ... <n>L, <n>B written` - Escape saved through the config mapping. This wrote the scratch file, a real side effect: the file exists on disk (`ls -l "$DROOT/probe.md"`).
- **Select-all key.** `tmux -L "$SOCK" send-keys -t "$SESSION" C-a`. Wait-for the first line again, then capture. All content lines in the ANSI capture carry the visual selection background `48;2;59;53;81m`.
- **Proof.** The `opened` and `saved` and `selectall` captures together name Neovim (`probe.md`), the theme, and the two keymaps.

## Gotchas

- Escape is the save keymap. Never press Escape while a drive is pointed at a real repo file; use the scratch fixture only.
- The first `nvim` run on a fresh machine clones lazy plugins (network). This machine already has them; assert `render-markdown.nvim` appears in `home/.config/nvim/lazy-lock.json` instead of bootstrapping.
- nvim writes undo files to the shared `~/.local/share/nvim/undo`; scratch filenames keep them harmless.
- PUA icon glyphs vary with the NerdFont install. Assert colors and glyph presence, not the exact codepoint.
- tmux colors pass through because nvim negotiates the terminal; if the ANSI capture has no `38;2;` sequences, the pane is not reporting full color and the proof is inconclusive, not passing.
