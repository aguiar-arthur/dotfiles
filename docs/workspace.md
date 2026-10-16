# Workspace

Finding, moving and editing: pickers, the file tree, terminals, sessions, motions and text
objects, completion and snippets, sharing code, and Claude Code. Uses [core](core.md) for keys
and toggles; the pickers change behaviour inside a [git](git.md) review.

## Terms

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
where `q` hides the terminal.

`<leader>cs` on a block selection (`C-v`) reports screen columns (`virtcol`), so tabs and wide
characters give the columns you see, and it lengthens the fence when the code has one. The path
is relative to the git root, so the text pastes well into a chat with an AI or a review.

claudecode.nvim speaks the protocol of Claude Code's VS Code extension. It loads only with a
`<leader>a` key or a `:ClaudeCode` command, never at startup, so its server exists only while
you use Claude; `<leader>aS` stops it. The server listens on `127.0.0.1` only and accepts the
`claude` process that read the random token from `~/.claude/ide/<port>.lock` (mode 0600).
What Claude sees in Neovim goes to Anthropic with the rest of the conversation, as Claude Code
does on its own.

## Pitfalls

- Snacks pickers: a custom `confirm` must call `require("snacks.picker.actions").jump`
  directly; actions such as `tab` route back through `confirm` and recurse.
- blink.cmp on the `:` line inserts the selected item already: mapping `<CR>` to `accept`
  there makes a completed command need a second `<CR>`.
- mini.pairs leaves the backtick alone everywhere; Markdown maps its own pair (see
  [markdown](markdown.md)).

## Checks

| What | Where |
|---|---|
| `<leader>cs` in each mode, fences, block columns | `tests/share.lua`, `tests/keys.lua` |
| References always open the list | `tests/files.lua` |
| Completion and snippets typed for real | full: `test_snippets` in `tests/tex.sh` |
| `Space w` keys, the look | full: `test_look` |
| Everything else here | plugin defaults, no check of our own |

## Changing it

- **A picker key**: one `key(...)` line in `snacks.lua` with `picker("<source>")`, and a row in
  the README's "Finding things" table.
- **A plugin for editing**: first check the plugin rule in `AGENTS.md`; add its spec to
  `editor.lua`, its keys with `desc`, and its row in the README.
