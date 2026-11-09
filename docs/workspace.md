# Workspace

Finding, moving and editing: pickers, the file tree, terminals, sessions, motions and text
objects, completion and snippets, sharing code, and Claude Code. Its relationships are in
[map](map.md).

## How it works

`gd` / `grr` / `K` work as usual (implementation is `gri`; `gi` keeps Vim's meaning);
`]r` / `[r` jump between references of the word under the cursor; `s` / `S` jump with flash;
`gs…` surrounds; mini.pairs closes brackets and quotes in a file, not on the `:` line, where it
got in the way of ranges and patterns. Text objects (mini.ai) work in every language with a
treesitter parser: `af` / `if` function, `ac` / `ic` class, `au` / `iu` call, `aa` / `ia`
argument, plus brackets, quotes and tags. The function and class queries come from
nvim-treesitter-textobjects, whose own move functions give `]f` / `[f` (function) and `]a` /
`[a` (argument; Vim's `]a` walked the argument list, unused here) in normal, visual and
operator-pending mode.

`<leader>r` searches with ripgrep and `<leader>R` with ast-grep (`brew "ast-grep"`), the engine
grug-far already ships, so a pattern with `$A` meta-variables matches code by its syntax tree.
`<leader>cl` asks Snacks' gitbrowse for a `permalink` (the file's last commit) and copies it
through gitbrowse's `open` option instead of opening a browser, which `<leader>gO` still does.

Completion: `<Tab>` is left alone in normal mode so `<C-i>` still walks the jump list forward;
in insert mode it jumps to the next snippet field first, then moves in the menu (`<C-n>` /
`<C-p>` always move in it; `<C-j>` / `<C-k>` only move between windows, also in pickers). On the
`:` line `<Tab>` completes (a single match at once) and `<CR>` runs the line as it reads.
Snippets are friendly-snippets through blink.cmp's own engine (`vim.snippet`); LuaSnip went
with the LaTeX snippets that needed it.

`<leader>tf` / `th` / `tv` toggle three separate terminals (float, bottom, right). Inside a
terminal every key goes to the program; a quick double `Esc` or `C-\ C-n` returns to Neovim,
where `q` hides the terminal and `<leader>bd` ends it. `<C-/>` hides one of the three from
terminal mode, since a `<leader>` key there would reach the shell; it is mapped in their own
`win.keys`, not for every Snacks terminal, so lazygit and Claude still get it (iTerm2 sends
`<C-/>` as `<C-_>`, so both are mapped). which-key never opens in terminal mode and a single
key has nothing to wait for, so the `<leader>t` group label in `ui.lua` names these keys instead.
The float terminal has the look of `float.lua`.

`<leader>cs` on a block selection (`C-v`) reports screen columns (`virtcol`), so tabs and wide
characters give the columns you see, and it lengthens the fence when the code has one. The path
is relative to the git root, so the text pastes well into a chat with an AI or a review.

claudecode.nvim speaks the protocol of Claude Code's VS Code extension. It loads only with a
`<leader>a` key or a `:ClaudeCode` command, never at startup, so its server exists only while you
use Claude; `<leader>aq` stops it. `<leader>aS` (visual) sends the selection and `<leader>aB` adds
the file to the last session: the terminal opens without taking focus so the selection survives, and
the mention is queued until Claude connects. The server listens on `127.0.0.1` only and accepts the
`claude` process that read the random token from `~/.claude/ide/<port>.lock` (mode 0600). What
Claude sees in Neovim goes to Anthropic with the rest of the conversation, as Claude Code does on
its own.

With `focus_after_send` every send (`<leader>as`, `ab`, `aS`, `aB`) opens Claude, focuses it and
enters terminal mode; without it the window opened but the cursor stayed in the code, in normal mode.

A diff Claude proposes opens in a new tab without the Claude float (`diff_opts.open_in_new_tab`,
`hide_terminal_in_new_tab`), as a codediff review does, instead of beside the code under the
float; `<leader>aa` / `<leader>ad` accept or reject it and close the tab.

A Claude that is out of sight (hidden, or another window focused) notifies through `TermRequest`:
an OSC 9 message (the iTerm2 notification Claude Code sends) is shown as is, OSC 9;4 progress is
ignored, and `TermClose` says it exited. Only the fake-program check proves this; whether the real
Claude sends OSC 9 depends on its notification setting.

Claude, the float terminal and lazygit share `dotfiles/float.lua`: a rounded Snacks float with a
title, 92% by 90% of the editor, over a backdrop dimmed to 60 (the pickers get the same
backdrop). Hiding a float keeps its session, and Snacks refits it when the terminal is resized.

## Pitfalls

- A picker another plugin adds (todo-comments' `todo_comments`) exists only once that plugin
  loads, so its key lives in that plugin's `keys` (`<leader>dt`), not in `snacks.lua`: from the
  dashboard it would fail before the first file is read.
- blink.cmp on the `:` line inserts the selected item already: mapping `<CR>` to `accept`
  there makes a completed command need a second `<CR>`.
- `getregion` pads a block selection to its width while `virtualedit` contains `block` (set in
  `options.lua`), so `<leader>cs` copied trailing spaces after short lines; `share.lua` turns
  `virtualedit` off around the call. `tests/share.lua` caught it once it ran with the real
  config: under `nvim -l` the option was off.
- `dotfiles/claude.lua` calls two functions claudecode.nvim does not document,
  `claudecode.terminal.get_active_terminal_bufnr` and `toggle_open_no_focus`: its commands
  cannot ask whether a Claude terminal runs nor open one without focus. The plugin uses both
  itself; if an update renames them, `tests/workspace.lua` fails in quick, because it reads the
  real plugin for both (the other cases there use fakes).

## Checks

`tests/workspace.lua`, `share.lua`, `keys.lua`; full: `tests/workspace.sh` (terminals, the tree
and pickers, Claude, sessions).
Everything else here is plugin defaults.

## Changing it

- **A picker key**: one `key(...)` line in `snacks.lua` with `picker("<source>")`.
- **A plugin for editing**: first check the plugin rule in `AGENTS.md`; add its spec to
  `editor.lua` and its keys with `desc`.
