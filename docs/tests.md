# Tests

How a change is checked: `tests/nvim.sh` and its files, where a new check goes, and how to
check by hand what the suite cannot. Every other context lists its own checks; this one says
how they are built.

## Terms

- **quick**: the default mode, seconds; startup, lint and the headless `.lua` checks.
- **full**: quick plus `install.sh nvim` into an isolated home and a real Neovim in tmux.
- **fresh**: full in a throwaway folder, as on a new machine.
- **probe**: a full-mode check that evaluates Lua in the running Neovim until it returns the
  wanted value or times out.

## Files

| Path | Holds |
|---|---|
| `tests/nvim.sh` | the one test command: `quick` (default), `full`, `fresh` |
| `tests/lib.sh` | pass / fail / skip, the isolated home, tmux, `probe`, `menu_shows`, `install` |
| `tests/look.sh`, `markdown.sh`, `code.sh`, `tex.sh` | the full checks by area, one `test_<name>` function each |
| `tests/lib.lua` | `T.eq`, `T.dir` (a temporary project), `T.config` (load a config file), `T.done` |
| `tests/files.lua`, `helpers.lua`, `toggles.lua`, `keys.lua`, `autocmds.lua` | headless checks with the real config, run through `lua_check` |
| `tests/share.lua`, `tests/modules.lua` | headless checks run without `lua_check` |
| `tests/snippets.lua` | the LaTeX probe the full run types into a real Neovim |

## How it works

Run by hand, never from `install.sh`: `tests/nvim.sh` after any change, `full` after changing
plugins, keys, servers, Markdown or LaTeX, `fresh` after changing `install.sh`. It skips what is
not installed, never touches the real home or clipboard, and fails if `lazy-lock.json` changes.
Each check prints `pass`, `skip` with the reason, or `FAIL` with what was wanted and what came
back; the last line is the count.

`full` installs Neovim into `~/.cache/dotfiles-nvim-test` (reused by later runs) with `HOME`
and the `XDG_*` folders pointed there, and drives Neovim through tmux and `nvim --server`.

Where a new check goes:

- It can run headless: a `T.eq` in the `tests/<area>.lua` of what it tests (or a new file and
  one `lua_check` line in `quick()`), with fakes for the clipboard, browser, Mason or codediff.
- It needs a UI, a server or typing: a `probe` in the `test_<area>` function of the `.sh` file
  of what it tests; a new helper goes in `tests/lib.sh`.
- Keep the `.sh` files together under 650 lines: a new check replaces an old one or earns its
  lines.

## Checking by hand

- Neovim: `nvim --headless "+qa"` prints nothing, and opening a file of the language you
  touched shows no error in `:messages`.
- Anything that needs a UI (LSP attach, Snacks, which-key, Conjure, DAP) is checked in a real
  terminal: write a Lua probe that waits with `vim.defer_fn`, writes what it sees to a file and
  quits, then run `sleep 30 | script -q /dev/null nvim -c "luafile probe.lua"` (the `sleep`
  keeps stdin open; without it Neovim gets EOF and quits). Work in a scratch project, point
  `XDG_STATE_HOME` at a scratch folder for anything that writes state (`:trust`), and stop only
  the processes you started, never with a broad `pkill`.
- Typed behaviour (autosnippets, completion, the `:` line): the probe feeds keys with
  `nvim_feedkeys(keys, "t", false)` one step at a time, waits with `vim.defer_fn` and records
  the line or the mode; text set with the API triggers nothing. `E1568` (no answer to a DSR
  request) in a probe's `:messages` comes from `script`.
- Health: `nvim --headless <file> -c 'checkhealth <names>' -c 'w! out.txt' -c 'qa!'`, then look
  for `ERROR` and `WARNING`; load lazy plugins first (`require("lazy").load`) or their checks
  are skipped. Snacks errors there are not real (see [core](core.md)).
- Scripts: `bash -n install.sh link.sh` and `shfmt -d` on what you changed; Lua through
  `stylua --check .` run from `config/nvim` (from a subfolder it misses `stylua.toml` and
  reports false diffs).
- Markdown: `rumdl check <files> --config config/rumdl/rumdl.toml`; it lets some long prose
  lines through, so also look for lines over 100 columns outside tables and code blocks.
