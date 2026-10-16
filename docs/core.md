# Core

How Neovim starts, the settings a user changes, the global keys and toggles, treesitter and the
look. Every other context builds on this one: plugins read `settings.lua`, and the toggles
reach into the git review (wrap) and Markdown (conceal).

## Terms

- **settings**: the table in `lua/config/settings.lua`, merged with the untracked `local.lua`.
- **trusted `.nvim.lua`**: a project file Neovim runs (`exrc`) once approved with `:trust`.
- **global toggle**: a `<leader>u` key that changes every window and buffer, also later ones.
- **generation**: the counter each global toggle bumps, so a buffer gets the values once.
- **prose filetypes**: `tex`, `markdown`, `text`, `gitcommit`, `plaintex`; spelling is on there.

## Files

| Path | Holds |
|---|---|
| `config/nvim/init.lua` | the 0.12 check, then options, keymaps, autocmds, lazy.nvim, in that order |
| `config/nvim/lua/config/settings.lua` | colorscheme, wrap, format on save, spell languages, notes folder, servers, Mason tools, parsers |
| `config/nvim/lua/config/local.lua` | per-machine overrides (untracked, merged over the settings) |
| `config/nvim/lua/config/options.lua` | options, leader keys, `.mdc` and `*.json.*` filetypes, the spell file |
| `config/nvim/lua/config/keymaps.lua` | save, quit, windows `<leader>w`, buffers `<leader>b`, `]d` / `]e`, `<leader>c` |
| `config/nvim/lua/config/autocmds.lua` | yank highlight, reload on focus, last position, `q` closes, missing folders, resize |
| `config/nvim/lua/config/lazy.lua` | lazy.nvim bootstrap at the commit in `lazy-lock.json` |
| `config/nvim/lua/dotfiles/windows.lua` | the cursorline only in the active window, the path in the winbar of file windows, the welcome screen when the last file closes, `q` closing a floating dashboard (`<leader>od`) instead of quitting |
| `config/nvim/dashboard/clock.sh` | the welcome screen's logo: a seven-segment clock (HH:MM:SS, blinking colon, English date) drawn by awk; `clock.sh N` stops after N frames |
| `config/nvim/lua/dotfiles/toggles.lua` | the global `<leader>u` toggles |
| `config/nvim/lua/plugins/snacks.lua` (`init`) | where the toggles are mapped, on `VeryLazy` |
| `config/nvim/lua/dotfiles/treesitter.lua` | highlight and indent per buffer, the switch behind `<leader>uT` |
| `config/nvim/lua/plugins/treesitter.lua` | nvim-treesitter (`main`), installing missing parsers on `UIEnter` |
| `config/nvim/lua/plugins/colorscheme.lua` | Dracula with tinted diff backgrounds |
| `config/nvim/lua/plugins/ui.lua` | mini.icons, mini.statusline, treesitter-context, which-key groups |
| `config/nvim/spell/en.utf-8.add` | words accepted with `zg` (the compiled `.spl` is ignored) |

## How it works

Neovim 0.12 or newer: the grammar toggle reads `vim.lsp.is_enabled()` and relies on
`vim.lsp.enable(name, false)` stopping the running servers.

`<Space>` is the leader, `,` the local leader; which-key shows every key after a short pause.
`<leader>` keys work everywhere, `,` keys depend on the file type (see [code](code.md)).
`<A-j>` / `<A-k>` move lines; `C-h/j/k/l` (or `<leader>w h/j/k/l`) move between windows.
Neovim's own `grn` / `grr` / `gra` / `gri` / `grt` / `grx` are deleted so `gr` lists
references at once instead of waiting for a second key.

The `<leader>u` toggles are global. A `:setlocal` (wrap, numbers, conceal, spell) stays with
its buffer until the next global toggle. Values an ftplugin sets are replaced when the buffer
first opens; `vim.b.keep_local_opts = true` (in an ftplugin or `.nvim.lua`) keeps a buffer's
own values. Each toggle bumps the generation, so `BufWinEnter` re-applies the values only to
buffers that have not seen the latest one, and a `:setlocal` survives switching buffers. The
toggles take their values once at startup, right after `options.lua`, and keep them in
`toggles.lua` rather than reading `vim.go`, which is the current window's. In a review `<leader>uw`
changes nothing and says why (wrap would misalign the two sides).

Treesitter highlights every language with a parser except LaTeX, where vimtex's syntax is
richer, and indents only the ones in `settings.treesitter_indent`: its indentation is still
unreliable in Python, YAML and Markdown, so the ftplugin's stays there. Folds come from
treesitter everywhere (`foldexpr`).

The look: the `:` line and `/` search stay Neovim's own (blink completes them), notifications
go to Snacks (`<leader>on`) and signature help to blink. treesitter-context keeps the enclosing
function or class on top (`<leader>ux`). The status column (Snacks) shows marks and diagnostics
on the left, git and closed folds on the right; mini.statusline shows mode, git, diagnostics,
file, language servers and a running latexmk. Inactive windows are a shade darker
(`NormalNC`), the cursorline shows only in the active one, and each file window has its path
in a winbar (a window whose winbar is already set, as in a review, keeps it; floats and
terminals have none). Closing the last file (`<leader>bd`, `:bd`) shows the Snacks dashboard
again, as at startup (`q` quits there; on the floating one from `<leader>od` it only closes it);
its logo is `dashboard/clock.sh` in a Snacks `terminal` section with
`ttl = 0` (a cached section would be static), so any script that redraws from the top-left
corner can replace it. Smooth scrolling is Snacks' (`<leader>uS`). Diff colors are tinted
backgrounds over Dracula, so the code stays readable.

Spell checking (`en_us`, `pt_br`) is on for prose filetypes. Words added with `zg` (in either
language) go to the versioned `spell/en.utf-8.add`; Neovim compiles it at startup when it is
newer, as after a `git pull`. Without `spellfile`, `zg` would write outside the repository.
`.tex` files are LaTeX, not plain TeX (`g:tex_flavor`).

### Per-project settings

A `.nvim.lua` at the root of a project runs when Neovim starts there (`exrc`):

```lua
vim.g.disable_autoformat = true
vim.lsp.config("basedpyright", { settings = { basedpyright = { analysis = { typeCheckingMode = "strict" } } } })
```

Neovim runs it only after you trust it: the first time it asks, `v` shows the file and `:trust`
approves it; after any edit it asks again. A trusted `.nvim.lua` also lets prettier run (see
[code](code.md)). Projects' `.editorconfig` files are followed (built in).

## Pitfalls

- Neovim's own ftplugins for Lua, Markdown, help and query call `vim.treesitter.start()` after
  the `FileType` autocmds; anything that turns treesitter off must stop it again later (the
  treesitter autocmd does it in `vim.schedule`).
- In a codediff tab `vim.go.wrap` is off (codediff sets it with `vim.wo`); global toggles keep
  their own values instead of reading `vim.go`.
- render-markdown sets `conceallevel` on every redraw, so the conceal toggle sets it up again
  (see [markdown](markdown.md)).
- Snacks installs `vim.ui.input` / `vim.ui.select` and the dashboard on `UIEnter`, which a
  headless Neovim never fires: `:checkhealth snacks` errors there are not real.
- `:checkhealth snacks` reports errors under `Snacks.image` (kitty graphics, `magick`, `mmdc`)
  although the module is off and iTerm2 has no kitty protocol: not real.

## Checks

| What | Where |
|---|---|
| Startup prints nothing, every module loads | quick: `nvim starts without messages`, `tests/modules.lua` |
| Autocmds, the cursorline and winbar of `windows.lua` | `tests/autocmds.lua` |
| `]d`, `]e` | `tests/keys.lua` |
| The `<leader>u` toggles, beside a review, `keep_local_opts`, `uT` | `tests/toggles.lua` |
| Filetypes (`.mdc`, `*.json.*`) | `tests/files.lua` |
| `zg` writes to the versioned list | quick: `zg writes to the versioned word list` |
| The look, code context, `Space w` | full: `test_look` in `tests/core.sh` |
| Windows (`Space w` split, move, resize, close), buffers (`Space b`), `Space u w`, `:help` | full: `test_windows` in `tests/core.sh` |

## Changing it

- **A new setting**: add it to `settings.lua` with its default, read it with
  `require("config.settings")`, and show it in the README's per-machine example if users
  would change it.
- **A new global toggle**: a `M.option` or `global(...)` line in `toggles.lua` `M.map()`, a check
  in `tests/toggles.lua`, a row in the README's toggles table.
- **A new global key**: `keymaps.lua` (or its plugin's `keys`), a `desc`, a which-key group in
  `ui.lua` if it opens a new `<leader>` prefix, and the README table of its module.
