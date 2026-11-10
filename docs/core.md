# Core

How Neovim starts, the settings a user changes, the global keys and toggles, treesitter and the
look. Every other context builds on this one (see [map](map.md)).

## Language

- **settings**: the table in `lua/config/settings.lua`, merged with the untracked `local.lua`.
- **trusted `.nvim.lua`**: a project file Neovim runs (`exrc`) once approved with `:trust`.
- **global toggle**: a `<leader>u` key that changes every window and buffer, also later ones.
- **generation**: the counter each global toggle bumps, so a buffer gets the values once.
- **prose filetypes**: `tex`, `markdown`, `text`, `gitcommit`, `plaintex`; spelling and conceal
  are on there only.

## How it works

Neovim 0.12 or newer: `ui2` and `vim.ui.progress_status()` come with it.

`<Space>` is the leader, `,` the local leader; which-key shows every key after a short pause.
`<leader>` keys work everywhere, `,` keys depend on the file type (see [code](code.md)).
`C-h/j/k/l` move between windows, and on to tmux panes (vim-tmux-navigator, see
[workspace](workspace.md)). Neovim's own keys (splits, `]b` / `[b`, `gcc`, `C-w d`) are not
repeated under `<leader>`; the LSP keys are the exception (see [code](code.md)). `<Esc>` clears
the search highlight; Neovim's `nohlsearch` package is not used because it clears it after
`updatetime` (250 ms here), before the matches can be read.

The `<leader>u` toggles are global. A `:setlocal` (wrap, numbers, conceal, spell) stays with
its buffer until the next global toggle. Values an ftplugin sets are replaced when the buffer
first opens; `vim.b.keep_local_opts = true` (in an ftplugin or `.nvim.lua`) keeps a buffer's
own values. Each toggle bumps the generation, so `BufWinEnter` re-applies the values only to
buffers that have not seen the latest one, and a `:setlocal` survives switching buffers. The
toggles take their values once at startup, right after `options.lua`, and keep them in
`toggles.lua` rather than reading `vim.go`, which is the current window's. In a review `<leader>uw`
changes nothing and says why (wrap would misalign the two sides). Conceal follows spelling: it
applies only to the prose file types (`toggles.prose`), and every other file gets 0, since the
JSON parser hides every quote at 2 and a missing one went unseen.

Treesitter highlights every language with a parser except LaTeX, where vimtex's syntax is
richer, and indents only the ones in `settings.treesitter_indent`: its indentation is still
unreliable in Python, YAML and Markdown, so the ftplugin's stays there. Folds come from
treesitter everywhere (`foldexpr`).

The look: messages and the `:` line use Neovim's own `ui2` (`require("vim._core.ui2").enable()` in
`options.lua`): no "Press ENTER" prompt, long output folded behind a `[+N]` mark (`g<` shows it).
blink completes the `:` line and `/` search, notifications go to Snacks and signature help to
blink. mini.statusline shows mode, git, diagnostics, running progress (`vim.ui.progress_status()`,
see [code](code.md)) and language servers; the path is in each window's winbar instead. A window
whose winbar is already set keeps it; a review's tab, floats and terminals have none, and a file
window that turns into a terminal drops it, because a split inherits the winbar of the window it
came from. Inactive windows are a shade darker (`NormalNC`) and the cursorline shows only in the
active one. Closing the last file shows the Snacks dashboard again; its logo is
`dashboard/clock.sh` in a `terminal` section with `ttl = 0` (a cached section would be static), so
any script that redraws from the top-left corner can replace it. The clock draws two frames a
second, enough for the blinking colon; ten cost about 15% of a core. Smooth scrolling is Snacks'
at 100 ms instead of its 200, since a review's `]c` and `C-d` wait for it. The tab line is
`dotfiles/tabline.lua` (see [git](git.md) for a review's label). Diff colors are tinted
backgrounds over Dracula, so the code stays readable.

Spell checking (`en_us`, `pt_br`) is on for prose filetypes. Words added with `zg` (in either
language) go to the versioned `spell/en.utf-8.add`; Neovim compiles it at startup when it is
newer, as after a `git pull`. Without `spellfile`, `zg` would write outside the repository.
`.tex` files are LaTeX, not plain TeX (`g:tex_flavor`).

### Per-project settings

A `.nvim.lua` in the folder Neovim starts in, or in any folder above it, runs at startup
(`exrc`; since 0.12 Neovim walks up the parent folders and runs every trusted one it finds,
nearest first, and a file that sets `vim.o.exrc = false` stops the walk):

```lua
vim.g.disable_autoformat = true
vim.lsp.config("basedpyright", { settings = { basedpyright = { analysis = { typeCheckingMode = "strict" } } } })
```

Neovim runs it only after you trust it: the first time it asks, `v` shows the file and `:trust`
approves it; after any edit it asks again. A trusted `.nvim.lua` also lets prettier run (see
[code](code.md)). Projects' `.editorconfig` files are followed (built in).

## Pitfalls

- `<A-j>` / `<A-k>` reindent the moved lines (`==`). With `silent! move` the reindent still ran
  when the move failed at the edge, and changed a line that never moved; the keys catch `E16`
  (`:move` past the edge) and skip it.
- `foldexpr` runs treesitter only where `buftype` is empty. Neovim's folds keep an entry per buffer
  and, when `foldminlines` changes globally (`<leader>gz` in a review), refresh them all; a float
  closed inside an autocmd, as a hunk preview closes on a cursor move, is wiped without the
  `BufUnload` that clears its entry, and that refresh then failed with `Invalid buffer id`.
- Neovim's own ftplugins for Lua, Markdown, help and query call `vim.treesitter.start()` after
  the `FileType` autocmds; anything that turns treesitter off must stop it again later (the
  treesitter autocmd does it in `vim.schedule`).
- Snacks installs `vim.ui.input` / `vim.ui.select` and the dashboard on `UIEnter`, which a
  headless Neovim never fires: `:checkhealth snacks` errors there are not real.
- `:checkhealth snacks` reports errors under `Snacks.image` (kitty graphics, `magick`, `mmdc`)
  although the module is off and iTerm2 has no kitty protocol: not real.
- `ui2` is still marked experimental in 0.12 and turns itself on only when a UI is attached, so
  the headless quick tests never see it draw; they only check that its modules are still there
  (`tests/core.lua`, which CI runs), `test_look` checks it draws, and a probe in a real terminal
  (see [tests](tests.md)) is how to check the `:` line and blink's menu after a Neovim update.
  Turning it off is deleting its line in `options.lua`. The call is in a `pcall`, because
  `vim._core.ui2` is a private module: a Neovim that renames it only warns, instead of stopping
  `init.lua` before the keys, the autocmds and lazy.nvim.

## Checks

`tests/core.lua`, `toggles.lua`, `keys.lua`, `autocmds.lua`, `treesitter.lua`, `files.lua`;
full: `test_look` and `test_windows` in `tests/core.sh`. `tests/nvim.sh` prints what each check
covers.

## Changing it

- **A new setting**: add it to `settings.lua` with its default, read it with
  `require("config.settings")`, and show it in the README's per-machine example if users
  would change it.
- **A new global toggle**: a `M.option` or `global(...)` line in `toggles.lua` `M.map()`, a check
  in `tests/toggles.lua`.
- **A new global key**: `keymaps.lua` (or its plugin's `keys`), a `desc`, a which-key group in
  `ui.lua` if it opens a new `<leader>` prefix.
