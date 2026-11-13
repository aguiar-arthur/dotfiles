# Workspace

Finding, moving and editing: pickers, the file tree, terminals, sessions, motions and text
objects, completion and snippets, sharing code, and Claude Code. Its relationships are in
[map](map.md).

## How it works

Snacks is the one plugin for pickers, the file tree, terminals, notifications and the dashboard:
a new need there uses it before a new plugin.

mini.pairs closes brackets and quotes in a file, not on the `:` line, where it got in the way of
ranges and patterns. Text objects (mini.ai) work in every language with a treesitter parser; the
function and class queries come from nvim-treesitter-textobjects, whose move functions give
`]f` / `[f` and `]a` / `[a` (Vim's `]a` walked the argument list, unused here).

`<leader>r` searches with ripgrep and `<leader>R` with ast-grep, the engine grug-far already
ships, so a pattern with `$A` meta-variables matches code by its syntax tree. `<leader>cl` asks
Snacks' gitbrowse for a `permalink` and copies it through gitbrowse's `open` option instead of
opening a browser, which `<leader>gO` still does.

Completion: `<Tab>` is left alone in normal mode so `<C-i>` still walks the jump list forward;
in insert mode it jumps to the next snippet field first, then moves in the menu. `<C-j>` /
`<C-k>` only move between windows, also in pickers. On the `:` line `<Tab>` completes and
`<CR>` runs the line as it reads. Snippets are friendly-snippets through blink.cmp's own engine
(`vim.snippet`).

`<leader>t` has three separate terminals (float, bottom, right). Inside a terminal every key goes
to the program; a quick double `Esc` or `C-\ C-n` returns to Neovim. `<C-/>` hides one of the
three from terminal mode, since a `<leader>` key there would reach the shell; it is mapped in
their own `win.keys`, not for every Snacks terminal, so lazygit and Claude still get it (iTerm2
sends `<C-/>` as `<C-_>`, so both are mapped). which-key never opens in terminal mode, so the
`<leader>t` group label in `ui.lua` names these keys instead.

`<leader>cs` on a block selection reports screen columns (`virtcol`), so tabs and wide characters
give the columns you see, and it lengthens the fence when the code has one. The path is relative
to the git root, so the text pastes well into a chat or a review.

claudecode.nvim speaks the protocol of Claude Code's VS Code extension. It loads only with a
`<leader>a` key or a `:ClaudeCode` command, never at startup, so its server exists only while you
use Claude. Sending a selection or a file opens the terminal without taking focus so the selection
survives, and the mention is queued until Claude connects. The server listens on `127.0.0.1` only
and accepts the `claude` process that read the random token from `~/.claude/ide/<port>.lock` (mode
0600). What Claude sees in Neovim goes to Anthropic with the rest of the conversation, as Claude
Code does on its own.

`focus_after_send` is off, so adding files (`<leader>ab`) keeps you in the code; the keys that
expect you to type next focus Claude themselves: `<leader>as` / `aS` (a selection, then your
question), `<leader>ak` and `<leader>ah`. `<leader>ak` asks without leaving the code: it takes the
line or the selection as `@path#L10-20` (relative to the working directory, which is Claude's),
asks for the question in Neovim's own input and submits both. `<leader>ah` (Git's, inside a
review) sends the change under the cursor as a diff, with its file, function and the review's
label, since the old side of a review is no file Claude can read. Both go through `claude.send`:
a running, connected Claude gets the text at once; otherwise one opens without focus and the text
is written once it connects (and the plugin's own `connection_wait_delay`), because text typed
before Claude's prompt is ready is lost; after 15 s it gives up and says so.

The selection Claude sees is paused in a buffer whose name looks like a secret (`.env*`, `*.pem`,
`*.key`, `id_*`, `.netrc`, a name with `credentials` or `secret`) and resumed on the next buffer
that is not: the plugin streams every visual selection to Claude while it is connected, with no list
of files to skip, and what Claude sees goes into the next question. `<leader>ak` and `<leader>ah`
refuse such a file (`claude.refuse`) and say so: their text goes straight into the prompt, past both
the pause and the denied reads, so a hunk of a `.env` would reach Claude whole. A window showing
Claude (not its float) is hidden before a session is saved: `sessionoptions` keeps terminals, and a
restored session would start `claude` again on its own. Reading secrets with Claude's own tools is
denied apart from Neovim, by `macos/nvim/link.sh` (see [install](install.md)).

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
  `virtualedit` off around the call. `tests/share.lua` runs with the real config for this reason:
  under `nvim -l` the option is off.
- `dotfiles/claude.lua` calls what claudecode.nvim does not document: `claudecode.terminal`'s
  `get_active_terminal_bufnr`, `toggle_open_no_focus`, `open` and `send_to_terminal`,
  `claudecode.selection`'s `enable`, `disable` and `state`, and `claudecode`'s
  `is_claude_connected` and `state`: its commands cannot ask whether a Claude terminal runs, open
  one without focus, send text without a command line or pause the selection. The plugin uses all
  of them itself; if an update renames one, `tests/workspace.lua` fails in quick, because it reads
  the real plugin for them (the other cases there use fakes).
- With a float, `toggle_open_no_focus` still leaves the cursor in Claude (in normal mode), so
  `ClaudeCodeFocus`, a toggle, then hid it: `claude.send` focuses with `terminal.open`, which
  only shows and enters terminal mode.

## Checks

`tests/workspace.lua`, `share.lua`, `keys.lua`; full: `tests/workspace.sh` (terminals, the tree
and pickers, Claude, sessions).
Everything else here is plugin defaults.

## Changing it

- **A picker key**: one `key(...)` line in `snacks.lua` with `picker("<source>")`.
- **A plugin for editing**: first check the plugin rule in `AGENTS.md`; add its spec to
  `editor.lua` and its keys with `desc`.
