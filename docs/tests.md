# Tests

How a change is checked: `tests/nvim.sh` and its files, where a new check goes, and how to
check by hand what the suite cannot. Every other context lists its own checks; this one says
how they are built. Its relationships are in [map](map.md).

## Language

- **quick**: the default mode, seconds; startup, lint and the headless `.lua` checks.
- **full**: quick plus `macos/nvim/install.sh` into an isolated home and a real Neovim in tmux.
- **fresh**: full in a throwaway folder, as on a new machine.
- **probe**: a full-mode check that evaluates Lua in the running Neovim until it returns the
  wanted value or times out.

## Files

| Path | Holds |
|---|---|
| `tests/nvim.sh` | the one test command: `quick` (default), `full`, `fresh` |
| `tests/lib.sh` | pass / fail / skip, the isolated home, tmux, `probe`, `menu_shows`, `install` |
| `tests/core.sh`, `workspace.sh`, `code.sh`, `git.sh`, `markdown.sh`, `tex.sh` | the full checks, one file per context (the same names as the docs), one `test_<name>` function per scenario |
| `tests/lib.lua` | `T.eq`, `T.dir` (a temporary project), `T.config` (load a config file), `T.done` |
| `tests/files.lua`, `helpers.lua`, `toggles.lua`, `keys.lua`, `autocmds.lua` | headless checks with the real config, run through `lua_check` |
| `tests/share.lua`, `tests/modules.lua` | headless checks run without `lua_check` |
| `tests/snippets.lua` | the LaTeX probe the full run types into a real Neovim |

## How it works

Run by hand, never from an installer: `tests/nvim.sh` after any change, `full` after changing
plugins, keys, servers, Markdown or LaTeX, `fresh` after changing `macos/`. It skips what is
not installed, never touches the real home or clipboard, and fails if `lazy-lock.json` changes.
The quick checks run headless Neovim with the real config, so `quick` points `XDG_STATE_HOME`
at a temporary folder: persistence saves a session on exit, and it once replaced the real
session of `~/dotfiles` with test files. `the quick tests leave your sessions alone` checks it.
Each check prints `pass`, `skip` with the reason, or `FAIL` with what was wanted and what came
back; the last line is the count.

`full` installs Neovim into `~/.cache/dotfiles-nvim-test` (reused by later runs) with `HOME`
and the `XDG_*` folders pointed there, and drives Neovim through tmux and `nvim --server`.

Where a new check goes:

- It can run headless: a `T.eq` in the `tests/<area>.lua` of what it tests (or a new file and
  one `lua_check` line in `quick()`), with fakes for the clipboard, browser, Mason or codediff.
- It needs a UI, a server or typing: a `probe` in the `test_<area>` function of the `.sh` file
  of what it tests; a new helper goes in `tests/lib.sh`.
- There is no line limit: split a file by sub-context when it grows (`workspace.sh` could become
  `terminals.sh` and `claude.sh`) and list it in the `for part in …` loop of `tests/nvim.sh`.
- A key sent while a terminal has the cursor goes to the program, so set Lua state there with
  `lua_do`, not with `send ':lua …'`.

## Contract

Offers: `tests/nvim.sh` (quick, full, fresh) and `tests/lib.sh` / `lib.lua` to every context.

Consumes: every context's code. A link in [map](map.md) gets a check in the downstream
context's file; the map's last column says which.

## Quick tests in CI

`.github/workflows/tests.yml` runs `tests/nvim.sh` (quick) on a macOS runner on push and pull
request: it installs the programs the checks use and BasicTeX with `latexmk`, runs
`macos/nvim/link.sh`, restores the plugins from `lazy-lock.json`, runs `dotfiles.install`
(servers, parsers, spell files, as `macos/nvim/install.sh` does) and then the suite. Checks for
programs or apps the runner lacks (Skim, tmux) skip. `full` and `fresh` stay manual: they need
real language servers and tmux and would fail for reasons that are not in a change.

## Security workflow

`.github/workflows/security.yml` runs on push, pull request and every Monday: ShellCheck on the
shell scripts, gitleaks on the full history, and zizmor on the workflows. Actions are pinned to
a commit SHA and the token is read-only; Dependabot (`.github/dependabot.yml`) bumps the pins.
ShellCheck does not read zsh, so `config/zsh/` is left out. Run `gitleaks detect` locally for the
same secret scan.

`.github/workflows/scorecard.yml` runs OSSF Scorecard weekly and on push and uploads the result
to the repository's code scanning alerts (Security tab). It scores repository hygiene (branch
protection, pinned actions, token permissions), not code. `.github/workflows/codeql.yml` runs
CodeQL on the workflow files (the `actions` language; there is no other code it supports).
OSV-Scanner is not used: it does not read `lazy-lock.json`.

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
- Scripts: `bash -n macos/install.sh macos/lib.sh macos/*/*.sh` and `shfmt -d` on what you
  changed; Lua through `stylua --check .` run from `config/nvim` (from a subfolder it misses
  `stylua.toml` and reports false diffs).
- Markdown: `rumdl check <files> --config config/rumdl/rumdl.toml`; it lets some long prose
  lines through, so also look for lines over 100 columns outside tables and code blocks.
