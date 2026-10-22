# Workspace

Finding, moving and editing: pickers, the file tree, terminals, sessions, motions and text
objects, completion and snippets, sharing code, and Claude Code. Its relationships are in
[map](map.md).

## Language

- **picker**: any Snacks list (files, grep, symbols, references, git); one set of keys for all.
- **share**: `<leader>cs`, which copies `path:line:col-line:col` and a fenced code block.

## Files

| Path | Holds |
|---|---|
| `config/nvim/lua/plugins/snacks.lua` | pickers `<leader>f`, file tree `<leader>o`, terminals `<leader>t`, lazygit, `]r`, the picker `confirm` |
| `config/nvim/lua/plugins/editor.lua` | flash, mini.ai, mini.surround, mini.pairs, grug-far, todo-comments, Trouble, persistence (and gitsigns, codediff: see [git](git.md)) |
| `config/nvim/lua/plugins/completion.lua` | blink.cmp, LuaSnip, friendly-snippets, the `:` line |
| `config/nvim/lua/dotfiles/share.lua` | what `<leader>cs` copies; the key is in `lua/config/keymaps.lua` |
| `config/nvim/lua/plugins/claude.lua` | claudecode.nvim, `<leader>a` |
| `config/nvim/lua/dotfiles/claude.lua` | `<leader>aS` (visual) and `<leader>aB`: open the last session if none runs, then send the selection / add the file; notifications from a hidden Claude |
| `config/nvim/lua/dotfiles/float.lua` | the one float style: Claude, the float terminal and lazygit |

## How it works

`gd` / `gr` / `K` work as usual (implementation is `<leader>li`; `gi` keeps Vim's meaning);
`]r` / `[r` jump between references of the word under the cursor; `s` / `S` jump with flash;
`gs…` surrounds. Text objects (mini.ai) work in every language with a treesitter parser:
`af` / `if` function, `ac` / `ic` class, `au` / `iu` call, `aa` / `ia` argument, plus brackets,
quotes and tags. The function and class queries come from nvim-treesitter-textobjects, which
is installed only for them.

Completion: `<Tab>` is left alone in normal mode so `<C-i>` still walks the jump list forward;
in insert mode it jumps to the next snippet field first, then moves in the menu (`<C-n>` /
`<C-p>` always move in it; `<C-j>` / `<C-k>` only move between windows, also in pickers). On the
`:` line `<Tab>` completes (a single match at once) and `<CR>` runs the line as it reads.
friendly-snippets are loaded for every language but LaTeX, which has its own (see
[latex](latex.md)).

`<leader>tf` / `th` / `tv` toggle three separate terminals (float, bottom, right). Inside a
terminal every key goes to the program; a quick double `Esc` or `C-\ C-n` returns to Neovim,
where `q` hides the terminal. The float terminal has the look of `float.lua`.

`<leader>cs` on a block selection (`C-v`) reports screen columns (`virtcol`), so tabs and wide
characters give the columns you see, and it lengthens the fence when the code has one. The path
is relative to the git root, so the text pastes well into a chat with an AI or a review.

claudecode.nvim speaks the protocol of Claude Code's VS Code extension. It loads only with a
`<leader>a` key or a `:ClaudeCode` command, never at startup, so its server exists only while
you use Claude; `<leader>aS` stops it (in visual mode it sends the selection instead, and
`<leader>aB` adds the file: the terminal opens without taking focus so the selection survives,
and the mention is queued until Claude connects). The server listens on `127.0.0.1` only and
accepts the `claude` process that read the random token from `~/.claude/ide/<port>.lock` (mode
0600). What Claude sees in Neovim goes to Anthropic with the rest of the conversation, as Claude
Code does on its own.

With `focus_after_send` every send (`<leader>as`, `ab`, `aS`, `aB`) opens Claude, focuses it and
enters terminal mode; without it the window opened but the cursor stayed in the code, in normal mode.

A Claude that is out of sight (hidden, or another window focused) notifies through `TermRequest`:
an OSC 9 message (the iTerm2 notification Claude Code sends) is shown as is, OSC 9;4 progress is
ignored, and `TermClose` says it exited. Only the fake-program check proves this; whether the real
Claude sends OSC 9 depends on its notification setting.

Claude, the float terminal and lazygit share `dotfiles/float.lua`: a rounded Snacks float with a
title, 92% by 90% of the editor, over a backdrop dimmed to 60 (the pickers get the same
backdrop). Hiding a float keeps its session, and Snacks refits it when the terminal is resized.

## Contract

Offers:

- To [git](git.md): the pickers' custom `confirm` opens a file from a review in the tab before
  it, by pointing `picker.main` at a file window there; it must call
  `require("snacks.picker.actions").jump` directly, because actions such as `tab` route back
  through `confirm` and recurse.
- To [code](code.md): blink.cmp, whose LSP capabilities servers need when they start.
- To [latex](latex.md): completion; LaTeX keeps its own snippets in place of friendly-snippets.
- To [markdown](markdown.md): mini.pairs leaves the backtick alone everywhere.

Consumes: [core](core.md) keys and toggles.

## Pitfalls

- blink.cmp on the `:` line inserts the selected item already: mapping `<CR>` to `accept`
  there makes a completed command need a second `<CR>`.

## Checks

| What | Where |
|---|---|
| `<leader>cs` in each mode, fences, block columns | `tests/share.lua`, `tests/keys.lua` |
| References always open the list | `tests/files.lua` |
| Completion and snippets typed for real | full: `test_snippets` in `tests/tex.sh` |
| Claude helpers, notifications, the file tree keys | `tests/helpers.lua`, `tests/keys.lua` |
| `Space t f` / `t h` / `t v`: modes, same terminal back, sizes, resize | full: `test_terminals` in `tests/workspace.sh` |
| The tree, pickers (`Esc`, `C-v`), Trouble, the floating dashboard | full: `test_tree_and_pickers` |
| Claude: `Space a s` / `a b` / `a B`, focus back to the window it came from, resize | full: `test_claude` |
| A hidden Claude notifies (OSC 9, exit) | full: `test_claude_notices` |
| Sessions: `Space S r` restores, `Space S d` keeps the old one | full: `test_sessions` |
| Everything else here | plugin defaults, no check of our own |

## Changing it

- **A picker key**: one `key(...)` line in `snacks.lua` with `picker("<source>")`, and a row in
  the README's "Finding things" table.
- **A plugin for editing**: first check the plugin rule in `AGENTS.md`; add its spec to
  `editor.lua`, its keys with `desc`, and its row in the README.
