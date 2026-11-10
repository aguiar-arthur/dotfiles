# Tests

How a change is checked: `tests/nvim.sh` and its files, where a new check goes, and how to
check by hand what the suite cannot. Every other context names its own checks; this one says
how they are built. Its relationships are in [map](map.md).

## Language

- **quick**: the default mode, seconds; startup, lint and the headless `.lua` checks.
- **full**: quick plus `macos/nvim/install.sh` into an isolated home and a real Neovim in tmux.
- **fresh**: full in a throwaway folder, as on a new machine.
- **probe**: a full-mode check that evaluates Lua in the running Neovim until it returns the
  wanted value or times out.

## Files

`tests/nvim.sh` is the one command (`quick`, `full`, `fresh`) and prints what every check covers.
`tests/lib.sh` holds the shell helpers (the isolated home, tmux, `probe`, `review_repo`, `install`),
and `tests/lib.lua` the Lua ones: `T.case` (a named group), `T.stub` (a fake undone after its
case), `T.eq`, `T.dir` (a temporary project), `T.config`, `T.skip`, `T.done`. The full checks are
one `tests/<context>.sh` per context with one `test_<name>` function per scenario; the headless
ones are `tests/*.lua`, run with the real config through `lua_check`. `tests/modules.lua` loads
every module alone (`nvim -l`), and `tests/probes.lua` holds the multi-statement Lua the full
checks call in the running Neovim.

## How it works

Run by hand, never from an installer: `tests/nvim.sh` after any change, `full` after changing
plugins, keys, servers, Markdown or LaTeX, `fresh` after changing `macos/`. It skips what is
not installed, never touches the real home or clipboard, and fails if `lazy-lock.json` changes.
The quick checks run headless Neovim with the real config, so `quick` points `XDG_STATE_HOME`
at a temporary folder: persistence saves a session on exit and would replace the real session
of `~/dotfiles` with test files (`the quick tests leave your sessions alone` checks it).
Each check prints `pass`, `skip` with the reason, or `FAIL` with what was wanted and what came
back; the last line is the count. A headless check that cannot run something here (no pandoc,
no rumdl) calls `T.skip(name, reason)` and `lua_check` prints a `skip` line below its `pass`,
so a missing program never reads as a pass of what it was meant to check.

`full` installs Neovim into `~/.cache/dotfiles-nvim-test` (reused by later runs) with `HOME`
and the `XDG_*` folders pointed there, and drives Neovim through tmux and `nvim --server`.
`fresh` uses a throwaway folder with its symlinks resolved: macOS keeps temporary folders under
`/var`, a link to `/private/var`, and Neovim's paths and the checks' would not match. Run `fresh`
now and then: a file left in the reused folder hides a test that never creates it.

Where a new check goes:

- It can run headless: a `T.eq` in a `T.case` of the `tests/<area>.lua` of what it tests (or a
  new file and one `lua_check` line in `quick()`), with fakes for the clipboard, browser, Mason
  or codediff. A case runs in `xpcall`, so a crash fails only that case and the next ones still
  run; it opens the buffer it needs itself and never relies on what an earlier case left. A fake
  goes in with `T.stub(table, key, value)`, which puts the old value back when the case ends,
  passed or crashed; a fake left by hand would replace `vim.notify` for the rest of a file.
- A probe that needs more than one statement is a function in `tests/probes.lua`, called as
  `P.name()`, so stylua checks it; a one-line expression stays in the `.sh` file.
- It needs a UI, a server or typing: a `probe` in the `test_<area>` function of the `.sh` file
  of what it tests; a new helper goes in `tests/lib.sh`.
- There is no line limit: split a file by sub-context when it grows (`workspace.sh` could become
  `terminals.sh` and `claude.sh`) and list it in the `for part in …` loop of `tests/nvim.sh`.
- Wait for the signal the next key needs (`wait_for`, or `expect_screen`, which fails with the
  screen when the text never comes; the text is the program's own, so the test config pins
  lazygit to English: in Portuguese its file list never says `Files`), not for a `sleep`; a sleep
  stays only where Neovim shows nothing to wait for (a second run replacing a terminal, a
  server indexing). Each full test builds the repository it needs (`review_repo`) and never
  relies on what an earlier one left, so one runs alone.
- tmux keys need an attached client (`script -q /dev/null tmux attach`) and `send-keys -K`;
  a key that opens a popup blocks `send-keys` until the popup closes, so send it in the
  background.
- A key sent while a terminal has the cursor goes to the program, so set Lua state there with
  `lua_do`, not with `send ':lua …'`.
- `ui2` keeps its message and `:` line windows as floats in the current tab, so a probe that
  counts windows by an option (wrap, cursorline) keeps only `relative == ""` ones, as `tiles`
  does.

## CI

`.github/workflows/tests.yml` runs the quick suite on a macOS runner: it installs the programs the
checks use (without pandoc the preview check skips), links Neovim, restores the plugins from
`lazy-lock.json` and runs `dotfiles.install`, as `macos/nvim/install.sh` does. There is no TeX on
the runner: no quick check builds a document. Checks for programs the runner lacks (Skim, tmux)
skip, and a newer push to the same branch cancels the run. `full` and `fresh` stay manual: they
need real language servers and tmux and would fail for reasons that are not in a change.

`.github/workflows/security.yml` runs on push, pull request and every Monday: ShellCheck (it reads
`tests/*.sh` by glob, but not zsh, so `config/zsh/` is left out), gitleaks on the full history
(`gitleaks git` runs it locally) and zizmor, pinned to a version that moves with the monthly
update ([install](install.md#updating)). Actions are pinned to a commit SHA, the token is
read-only, and Dependabot bumps the pins. CodeQL, OSSF Scorecard and OSV-Scanner are not used:
none of them reads the Lua, the shell or `lazy-lock.json` here.

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
