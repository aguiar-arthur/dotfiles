# Neovim

The editor for everything. Needs Neovim 0.11 or newer; plugins come from lazy.nvim, language servers
from Neovim's native LSP.

```text
config/nvim/
  init.lua                    options, keymaps, autocmds, then lazy.nvim
  lua/config/settings.lua     colorscheme, wrap, format on save, spell languages, the servers,
                              Mason tools and treesitter parsers to install
  lua/config/local.lua        per-machine overrides (untracked)
  lua/plugins/                one spec file per concern
  lua/dotfiles/install.lua    headless install of Mason packages, parsers and spell files
  lua/dotfiles/toggles.lua    the global <leader>u toggles
  after/lsp/<server>.lua      per-server settings
  after/ftplugin/             tex (vimtex keys) and markdown (pandoc preview)
  snippets/tex.lua            LaTeX snippets
  lazy-lock.json              plugin versions (committed; `:Lazy restore` goes back to it)
```

## Keys

`<Space>` is the leader, `,` the local leader; which-key shows every key after a short pause.

| Group | For |
|---|---|
| `<leader>f` | find: files, grep, recent, buffers, help, symbols (snacks picker) |
| `<leader>g` | git: lazygit, hunks, blame, diffview (`gv` changes, `gV` branch vs origin, `gh` history) |
| `<leader>l` | LSP: definition, references, rename, code action, format |
| `<leader>d` | diagnostics and lists (Trouble) |
| `<leader>D` | debugger (nvim-dap): Python, JavaScript/TypeScript, C/C++ |
| `<leader>b` / `w` / `t` | buffers / windows / terminals |
| `<leader>m` | harpoon marks |
| `<leader>r` | search and replace in the whole project (grug-far), prefilled with the word or selection |
| `<leader>S` | sessions |
| `<leader>o` | file tree, notifications, dashboard |
| `<leader>u` | toggles: spelling, wrap, relative numbers, conceal, diagnostics, inlay hints, indent guides, treesitter, format on save |

`gd` / `gr` / `K` work as usual (implementation is `<leader>li`; `gi` keeps Vim's meaning);
`]r` / `[r` jump between references of the word under the cursor; `s` / `S` jump with flash;
`gs…` surrounds. `<Tab>` is left alone so `<C-i>` still walks the jump list forward; in
insert mode it jumps to the next snippet field first, then moves in the completion menu
(`<C-j>` / `<C-k>` always move in the menu).
Text objects (mini.ai) work in every language with a treesitter parser: `af` / `if` function,
`ac` / `ic` class, `au` / `iu` function call, `aa` / `ia` argument, plus brackets, quotes and
tags (`daf` deletes a function, `ciu` rewrites a call's arguments). The function and class
queries come from nvim-treesitter-textobjects, which is installed only for them.
`<A-j>` / `<A-k>` move lines; `C-h/j/k/l` move between windows; `C-\` toggles a terminal.

The `<leader>u` toggles are global: they change every window or buffer and the ones opened
later. A `:setlocal` (wrap, numbers, conceal, spell) stays with its buffer until the next
global toggle. Values an ftplugin sets are replaced when the buffer first opens;
`vim.b.keep_local_opts = true` (in an ftplugin or `.nvim.lua`) keeps a buffer's own values.
Neovim's own ftplugins for Lua, Markdown, help and query start treesitter after the
`FileType` autocmds, so while highlight is off the toggle's autocmd stops it again.

## Per-project settings

A `.nvim.lua` at the root of a project runs when Neovim starts there (`exrc`), for changes
that belong to that project only, for example:

```lua
vim.g.disable_autoformat = true
vim.lsp.config("basedpyright", { settings = { basedpyright = { analysis = { typeCheckingMode = "strict" } } } })
```

Neovim runs the file only after you trust it: the first time it asks, `v` shows the file and
`:trust` approves it; after any edit it asks again. Projects' `.editorconfig` files are also
followed (built in).

## Plugins

snacks.nvim (picker, file tree, terminal, lazygit, dashboard, notifications, indent guides,
toggles), blink.cmp + LuaSnip (completion, snippets), nvim-lspconfig + Mason, conform.nvim
(formatting), nvim-treesitter (`main` branch), gitsigns, diffview-plus.nvim (the maintained
fork of diffview.nvim), flash, harpoon, mini.ai / surround / pairs / icons, todo-comments,
Trouble, persistence, nvim-dap, lualine, which-key, vimtex, Conjure, nvim-paredit, grug-far,
Dracula.

## Language servers and formatting

- Mason installs the servers in `settings.mason_servers` and the tools in
  `settings.mason_tools` (shellcheck and the debug adapters). Only the servers in that list
  are enabled (`automatic_enable = mason_servers`): a server left over in Mason stays off.
  rumdl (`Brewfile.nvim`) and clojure-lsp (the full `Brewfile` only) are enabled when the
  binary exists.
- blink.cmp adds its completion capabilities to every server by itself; it is a dependency
  of nvim-lspconfig so it loads, and registers them, before the first server starts.
- stylua, shfmt and prettier come from `Brewfile.nvim`; Mason does not install copies.
- Mason installs nothing when Neovim starts: after adding a server or tool to the settings,
  run `./install.sh` again (or `:MasonToolsInstall`).
- Treesitter highlights every language with a parser but indents only the ones in
  `settings.treesitter_indent`; elsewhere the ftplugin's indent stays, since treesitter
  indentation is still unreliable in Python, YAML and Markdown.
- conform formats on save (Lua, Python with ruff, shell, web/JSON/YAML, Markdown with rumdl;
  LaTeX only on demand with `<leader>lf`). `:FormatToggle` (`!` for one buffer) or
  `<leader>uf` turns it off.
- Language servers never attach to `diffview://` buffers: they get `buftype=acwrite`, so
  servers treat them as virtual, and `:w` on the index copy still stages it.
- Inside a diff, `gd` / `gr` / `<leader>l…` open a result in another file in a new tab.

## Clojure

clojure-lsp gives navigation, rename, diagnostics and formatting. Conjure evaluates code in a
REPL, nvim-paredit edits s-expressions (`>)` / `<)` slurp and barf, `,o` raises a form; see
`:h nvim-paredit`). `,cj` in a Clojure file starts an nREPL with cider-nrepl in a terminal
below (`clojure` for `deps.edn`, `lein` for `project.clj`) and connects as soon as
`.nrepl-port` appears; when a REPL is already running it only connects. Then `,ee` evaluates
the form under the cursor, `,er` the outer form, `,eb` the buffer, `,tn` runs the
namespace's tests, `,lv` opens the log. Conjure is limited to Clojure (its other clients
would map keys in Lua and Python files), and `K` / `gd` stay with the language server. The
nREPL and cider-nrepl versions are at the top of `lua/plugins/clojure.lua`.

## Debugging

`<leader>D` drives nvim-dap with dap-ui. Python uses debugpy; C/C++ use codelldb (it asks
for the program to run); JavaScript and TypeScript use js-debug-adapter, which launches the
current file with Node (recent Node runs `.ts` files directly) or attaches to a running Node
process. macOS lets a debugger attach to native programs only with developer mode on:
`sudo DevToolsSecurity -enable` once, or C debugging waits for a password dialog.

## LaTeX

vimtex compiles with latexmk and shows the PDF in Skim with SyncTeX; texlab gives completion
and diagnostics; the snippets in `snippets/tex.lua` expand as you type. Keys under `,l` in
`.tex` files: `,ll` compile, `,lv` view / forward search, `,le` errors, `,lt` table of
contents, `,lc` clean. Cmd+Shift+click in Skim jumps back to the line (set up by `link.sh`).
Put `% !TEX program = lualatex` on the first line for another engine.

## Markdown

`,p` builds an HTML page with pandoc (math as MathML, images embedded) and opens it in the
browser; every save rebuilds it. rumdl lints as you type, with the rules in
`config/rumdl/rumdl.toml` (line length 100).

## Notes

- Diff colors are tinted backgrounds over Dracula, so the code stays readable.
- Spell checking (`en_us`, `pt_br`) is on for prose files; `install.sh` downloads the
  Portuguese spell file. Words added with `zg` go to `spell/<lang>.utf-8.add`, versioned.
- `.tex` files are LaTeX, not plain TeX (`g:tex_flavor`).
