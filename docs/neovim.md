# Neovim

The editor for everything. Needs Neovim 0.12 or newer; plugins come from lazy.nvim, language servers
from Neovim's native LSP. The grammar toggle needs 0.12: it reads `vim.lsp.is_enabled()` and relies
on `vim.lsp.enable(name, false)` stopping the running servers.

```text
config/nvim/
  init.lua                    options, keymaps, autocmds, then lazy.nvim
  lua/config/settings.lua     colorscheme, wrap, format on save, spell languages, the notes folder, the servers,
                              Mason tools and treesitter parsers to install
  lua/config/local.lua        per-machine overrides (untracked)
  lua/plugins/                one spec file per concern
  lua/dotfiles/install.lua    headless install of Mason packages, parsers and spell files
  lua/dotfiles/mason.lua      which Mason packages the settings want and which are missing
  lua/dotfiles/toggles.lua    the global <leader>u toggles
  lua/dotfiles/treesitter.lua highlight and indent per buffer, the switch behind <leader>uT
  lua/dotfiles/markdown_preview.lua   the pandoc preview behind `,p`
  lua/dotfiles/python.lua     the Python interpreter (.venv, $VIRTUAL_ENV, python3)
  lua/dotfiles/git.lua        the base branch behind <leader>gV (origin/HEAD, main, master), the review check
  lua/dotfiles/share.lua      what <leader>cs copies: the path from the git root, line:col, a fenced block
  after/lsp/<server>.lua      per-server settings
  after/ftplugin/             tex (vimtex keys), markdown (preview, backticks), lua (`,s`)
                              and clojure (which-key names of Conjure's groups)
  snippets/tex.lua            LaTeX snippets (math, ABNT)
  templates/note.md           the `# title` that new and daily notes start with
  spell/en.utf-8.add          words accepted with `zg` (the compiled .spl is ignored)
  lazy-lock.json              plugin versions (committed; `:Lazy restore` goes back to it)
```

## Where things live

Each feature, the code behind it, what changes it and the check that covers it. Paths are
under `config/nvim/` unless they start with `tests/` or the repository root. In the Test
column, a `.lua` file runs in the quick suite; `full:` names a function in `tests/<area>.sh`.
`settings.lua` and `local.lua` are the ones in `lua/config/`.

| Feature | Code | Settings | Test |
|---|---|---|---|
| Options, leader keys, `.mdc` and `*.json.*` filetypes | `lua/config/options.lua` | `settings.lua` (wrap, spelllang) | quick startup check, `tests/files.lua` |
| Window `Space w`, buffer `Space b`, `]d` / `]e`, `Space c c` / `c d` | `lua/config/keymaps.lua` | | `tests/keys.lua` (`]d`, `]e`), full: `test_look` (`Space w`) |
| `Space c s` share a line or selection | `lua/dotfiles/share.lua`, key in `lua/config/keymaps.lua` | | `tests/share.lua` |
| Yank highlight, reload on focus, last position, `q` closes, missing folders | `lua/config/autocmds.lua` | | `tests/autocmds.lua` |
| `Space u` toggles | `lua/dotfiles/toggles.lua`, keys in `lua/plugins/snacks.lua` (`init`) | `settings.lua` (wrap), `local.lua` | `tests/toggles.lua`, full: `test_markdown` (`u m`), `test_tex` (`u G`) |
| Pickers `Space f`, file tree `Space o`, terminals `Space t`, lazygit, references list | `lua/plugins/snacks.lua` | | `tests/files.lua` (references) |
| Jumps from a review open a new tab | `lua/plugins/snacks.lua` (`actions.confirm`), `lua/dotfiles/git.lua` (`review`) | | full: `test_review` |
| Completion, snippets | `lua/plugins/completion.lua`, `snippets/tex.lua` | | full: `test_snippets` |
| Language servers, `Space l`, `gd` / `gr`, `,o`, `gq` in prose | `lua/plugins/lsp.lua`, `after/lsp/<server>.lua` | `settings.lua` (mason_servers, system_servers, mason_tools) | `tests/keys.lua` (`gq`), full: `test_lua`, `test_language_actions`, `test_markdown`, `test_tex`, `test_clojure` |
| Format on save, `Space l f` | `lua/plugins/formatting.lua` | `settings.lua` (format_on_save), a style file in the project | `tests/files.lua` |
| Treesitter: parsers, indent, `Space u T`, code context | `lua/plugins/treesitter.lua`, `lua/dotfiles/treesitter.lua`, `lua/plugins/ui.lua` | `settings.lua` (parsers, treesitter_indent) | `tests/toggles.lua` (`u T`), full: `test_look` (context) |
| Git hunks `Space g`, `]c` | `lua/plugins/editor.lua` (gitsigns) | | full: `test_review` (`]c`) |
| Review `Space g V` / `g D` | `lua/plugins/editor.lua` (codediff), `lua/dotfiles/git.lua` | | `tests/helpers.lua` (base branch), `tests/toggles.lua` (wrap), full: `test_review` |
| Flash, text objects, surround, pairs, `Space r` replace, todos, Trouble `Space d`, sessions `Space S` | `lua/plugins/editor.lua` | | plugin defaults; backtick pairs in `tests/keys.lua` |
| Look: Dracula, statusline, status column, which-key | `lua/plugins/colorscheme.lua`, `lua/plugins/ui.lua`, `lua/plugins/snacks.lua` | `settings.lua` (colorscheme) | full: `test_look` |
| `,r` run the file | `lua/plugins/run.lua`, interpreter from `lua/dotfiles/python.lua` | | `tests/helpers.lua` (interpreter), full: `test_run` |
| `,t` tests | `lua/plugins/test.lua` | | full: `test_test_keys` |
| `,d` debugger | `lua/plugins/debug.lua` | `settings.lua` (mason_tools: debugpy) | full: `test_debug` |
| `,s` source a Lua file | `after/ftplugin/lua.lua` | | full: `test_language_actions` |
| Clojure: Conjure, paredit, `,cj` | `lua/plugins/clojure.lua`, `lua/dotfiles/clojure.lua`, `after/ftplugin/clojure.lua` | | full: `test_clojure` |
| LaTeX: vimtex `,l`, builds, `,lw` | `lua/plugins/tex.lua`, `after/ftplugin/tex.lua`, `config/latex/latexmkrc` (root) | | `tests/keys.lua` (`,lw`), full: `test_tex` |
| Markdown: rendering, `,p` preview, backticks | `lua/plugins/markdown.lua`, `lua/dotfiles/markdown_preview.lua`, `after/ftplugin/markdown.lua` | `config/rumdl/rumdl.toml` (root) | `tests/keys.lua`, full: `test_markdown` |
| Notes `Space n` | `lua/plugins/markdown.lua` (obsidian.nvim), `templates/note.md` | `settings.lua` (notes) | full: `test_notes` |
| Installing Mason packages, parsers, spell files | `lua/dotfiles/install.lua`, `lua/dotfiles/mason.lua`, `install.sh` (root) | `settings.lua` (servers, tools, parsers, spelllang) | `tests/helpers.lua`, full: `install` |
| `zg` word list | `spell/en.utf-8.add`, `lua/config/options.lua` (spellfile) | | quick `zg` check |
| Per-machine and per-project overrides | `lua/config/settings.lua`, `lua/config/local.lua`, a trusted `.nvim.lua` | | none (plain settings) |

## Keys

`<Space>` is the leader, `,` the local leader; which-key shows every key after a short pause.
The README has every key, one table per module; this page explains how they behave.

| Group | For |
|---|---|
| `<leader>f` | find: files, grep, recent, buffers, help, symbols, marks (snacks picker) |
| `<leader>g` | git: lazygit, hunks, blame, changes (`gc` working tree hunks; `gD` / `gV` side by side review of the working tree / the branch vs origin's default branch), history (`gh` file, `gL` line, `gl` repo) |
| `<leader>l` | LSP: definition, references, rename, code action, format |
| `<leader>d` | diagnostics and lists (Trouble) |
| `<leader>b` / `w` / `t` | buffers / windows / terminals |
| `<leader>n` | notes: find, grep, new, daily, backlinks |
| `<leader>r` | search and replace in the whole project (grug-far), prefilled with the word or selection |
| `<leader>S` | sessions |
| `<leader>o` | file tree, notifications, dashboard |
| `<leader>u` | toggles: spelling, wrap, relative numbers, conceal, grammar (`uG`), Markdown rendering, code context (`ux`), diagnostics, inlay hints, indent guides, treesitter, format on save; `un` dismisses notifications |

`gd` / `gr` / `K` work as usual (implementation is `<leader>li`; `gi` keeps Vim's meaning);
`]r` / `[r` jump between references of the word under the cursor; `s` / `S` jump with flash;
`gs…` surrounds. `<Tab>` is left alone so `<C-i>` still walks the jump list forward; in
insert mode it jumps to the next snippet field first, then moves in the completion menu
(`<C-n>` / `<C-p>` always move in it; `<C-j>` / `<C-k>` only move between windows). On the
`:` command line `<Tab>` completes (a single match at once) and `<CR>` runs the line as it
reads.
Neovim's own `grn` / `grr` / `gra` / `gri` / `grt` / `grx` keys are deleted so `gr` lists
references at once instead of waiting for a second key. `LspAttach` clears `formatexpr`, so `gq`
keeps wrapping prose and comments instead of handing the lines to the language server.
Text objects (mini.ai) work in every language with a treesitter parser: `af` / `if` function,
`ac` / `ic` class, `au` / `iu` function call, `aa` / `ia` argument, plus brackets, quotes and
tags (`daf` deletes a function, `ciu` rewrites a call's arguments). The function and class
queries come from nvim-treesitter-textobjects, which is installed only for them.
`<A-j>` / `<A-k>` move lines; `C-h/j/k/l` (or `<leader>w h/j/k/l`) move between windows.
`<leader>tf` / `th` / `tv` toggle three separate terminals (float, bottom, right). Inside a
terminal every key goes to the program (lazygit, the shell, a REPL); a quick double `Esc` or
`C-\ C-n` returns to Neovim, where `q` hides the terminal.
`<leader>cs` on a block selection (`C-v`) reports screen columns (`virtcol`), so tabs and wide
characters give the columns you see, and it lengthens the fence when the code itself has one.

The `<leader>u` toggles are global: they change every window or buffer and the ones opened
later. A `:setlocal` (wrap, numbers, conceal, spell) stays with its buffer until the next
global toggle. Values an ftplugin sets are replaced when the buffer first opens;
`vim.b.keep_local_opts = true` (in an ftplugin or `.nvim.lua`) keeps a buffer's own values.
Each global toggle bumps a generation number, so `BufWinEnter` re-applies the values only to
buffers that have not seen the latest toggle, and a `:setlocal` survives switching buffers.
The toggles take their values once at startup, right after `options.lua`, and keep them in
`dotfiles/toggles.lua` rather than reading `vim.go`, which is the current window's: codediff
turns `wrap` off with `vim.wo`, so in a review `vim.go.wrap` was off and leaked into other
windows. Wrap is left alone in a review, where it would misalign the two sides.
Neovim's own ftplugins for Lua, Markdown, help and query start treesitter after the
`FileType` autocmds, so while highlight is off the treesitter autocmd stops it again.

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
the status column, toggles), blink.cmp + LuaSnip (completion, snippets), nvim-lspconfig +
Mason, conform.nvim (formatting), nvim-treesitter (`main` branch) + treesitter-context,
gitsigns, codediff.nvim (side by side review), flash, mini.ai / surround / pairs / icons /
statusline, todo-comments, Trouble, persistence, nvim-dap + dap-ui, Neotest (neotest-python),
code_runner.nvim (`,r`),
which-key, vimtex,
Conjure, nvim-paredit, grug-far, render-markdown.nvim, obsidian.nvim, Dracula. Behind them:
friendly-snippets, lazydev (Neovim's API in Lua completion), SchemaStore (JSON and YAML
schemas), mason-lspconfig, mason-tool-installer, mason-nvim-dap, nvim-nio and plenary. Each one
meets the plugin rule in `AGENTS.md`. codediff.nvim downloads its prebuilt diff library in its
lazy.nvim `build` step, so `install.sh` fetches it with the plugins. gitsigns attaches to a file
the review opens after codediff maps `]c` / `[c`, so its own `]c` / `[c` ask codediff first.
Inside a review the pickers' `confirm` opens the file in a new tab, so a jump never replaces a
side of the diff; references always show their list (`auto_confirm = false`).
That tab remembers the review it came from, so `<leader>gq` closes it and returns there even
after visiting other tabs; `tabclose = "uselast"` makes a plain `:q` return to the last tab.

The look: the `:` line and `/` search stay Neovim's own (blink completes them), notifications
go to Snacks (`<leader>on`) and signature help to blink. treesitter-context keeps the enclosing
function or class on top while scrolling (`<leader>ux` toggles it). The status column (Snacks)
shows marks and diagnostics on the left and git and closed folds on the right; the statusline
(mini.statusline, Dracula colors) shows mode, git, diagnostics, file, language servers and a
running latexmk.

## Language servers and formatting

- Mason installs the servers in `settings.mason_servers` and the tools in
  `settings.mason_tools` (shellcheck and debugpy). Only the servers in that list
  are enabled (`automatic_enable = mason_servers`): a server left over in Mason stays off.
  rumdl (`Brewfile.nvim`) and clojure-lsp (the full `Brewfile` only) are enabled when the
  binary exists.
- JavaScript and TypeScript have no server, formatter, runner, tests or debugger: they were
  removed as unused. Adding them back is a server in `settings.mason_servers` and a line in
  conform. The `javascript` parser stays for `<script>` blocks in HTML.
- blink.cmp adds its completion capabilities to every server by itself; it is a dependency
  of nvim-lspconfig so it loads, and registers them, before the first server starts.
- stylua, shfmt and prettier come from `Brewfile.nvim`; Mason does not install copies.
- Files named `*.json.*` (`config.json.example`, `package.json.tmpl`) are JSON
  (`config/options.lua`), so jsonls lints them; prettier gets `--parser json` for them, since
  it picks its parser from the last extension.
- Mason installs nothing when Neovim starts: after adding a server or tool to the settings,
  run `./install.sh` again (or `:MasonToolsInstall`).
- Treesitter highlights every language with a parser but indents only the ones in
  `settings.treesitter_indent`; elsewhere the ftplugin's indent stays, since treesitter
  indentation is still unreliable in Python, YAML and Markdown.
- conform formats on save (Lua, Python with ruff, shell, web/JSON/YAML with prettier,
  Markdown with rumdl; TOML and Clojure through taplo and clojure-lsp), but
  only in projects that declare that tool's style: Lua with a
  `stylua.toml`, shell with an `.editorconfig` section for `.sh` or `.bash` files, Python with
  a `ruff.toml` or a `[tool.ruff]` table in `pyproject.toml`, web/JSON/YAML with a prettier
  config file and a trusted `.nvim.lua` beside it, Markdown with a `.rumdl.toml` or
  `.markdownlint.*`, TOML with a `taplo.toml`,
  Clojure with a `cljfmt.edn` or `:cljfmt` in `.lsp/config.edn`. Without one each formatter
  falls back to its own defaults and a `:w` would restyle someone else's code; a bare
  `.editorconfig` or `pyproject.toml` is too common to count. `<leader>lf` still formats
  anywhere. LaTeX is formatted only on demand with `<leader>lf`. `:FormatToggle` (`!` for one
  buffer) or `<leader>uf` turns it off.
- prettier runs a project's JavaScript (`.prettierrc.js`, plugins named in any config), so it
  formats, on save or with `<leader>lf`, only where a `.nvim.lua` you approved with `:trust` sits
  next to the prettier config and has not changed since; elsewhere `<leader>lf` falls back to
  the language server. It is always Homebrew's prettier, never a repository's
  `node_modules/.bin/prettier`.
- `gq` wraps text to `textwidth` everywhere (prose, comments): Neovim would hand it to a
  language server that formats ranges (rumdl, lua_ls), which does not wrap, so it is reset.
- In Python, ruff is asked for UTF-16 positions like basedpyright (two encodings in one
  buffer make Neovim warn), and its hover is off so `K` shows basedpyright's.

## Clojure

clojure-lsp gives navigation, rename, diagnostics and formatting. Conjure evaluates code in a
REPL, nvim-paredit edits s-expressions (`>)` / `<)` slurp and barf, `,o` raises a form; see
`:h nvim-paredit`). `,cj` in a Clojure file starts an nREPL with cider-nrepl in a terminal
below (`clojure` for `deps.edn`, `lein` for `project.clj`) and connects as soon as
`.nrepl-port` appears; when a REPL is already running it only connects (a `.nrepl-port` left
by a dead REPL is removed and a new one starts, replacing the dead REPL's terminal). Then
`,ee` evaluates the form under the cursor, `,er` the outer form, `,eb` the buffer, `,tn` runs
the namespace's tests, `,lv` opens the log. Conjure is limited to Clojure (its other clients
would map keys in Lua and Python files), and `K` / `gd` stay with the language server. The
nREPL and cider-nrepl versions are at the top of `lua/dotfiles/clojure.lua`.

## Local leader

`<leader>` keys work everywhere; `,` keys depend on the file type, and which-key lists them when
you press `,`. Where a tool is missing the key says so instead of failing silently. Each `,` key
sits in its plugin's spec with lazy.nvim's `ft`, so it exists only in those buffers and loads the
plugin on first use; `,o` is mapped when the language server offers to organize imports and
the file type has no `,o` of its own (in Clojure it stays nvim-paredit's raise).

| Keys | Python | Lua | Shell |
|---|---|---|---|
| `,r` run the file | yes | `nvim -l` | `bash` |
| `,t…` tests (Neotest) | pytest | | |
| `,d…` debugger | yes | | |
| `,o` organize imports | ruff | | |
| `,s` source the file | | yes | |

`,r` is code_runner.nvim (`lua/plugins/run.lua`): it saves the file and runs it in a bottom
terminal from the file's folder; running the same file again replaces its terminal. Besides
the table, it runs JavaScript, Java, C, C++, Ruby and Rust with the plugin's own commands; a
language is one line in `commands` plus its name in the key's `ft`.

`,t` runs tests through Neotest: `,tt` the nearest test, `,tf` the file, `,tp` the project,
`,tl` the last run, `,tS` stops, `,ts` toggles the summary, `,to` shows the output of the test
under the cursor and `,tO` toggles the output panel; in Python `,td` debugs the nearest test.
Results show as signs and diagnostics in the buffer. Python uses neotest-python (pytest, from
the project's virtualenv).

Clojure keeps Conjure's keys (`,e` evaluate, `,l` log, `,t` tests, `,r` refresh, `,s` sessions,
`,cj` jack in), Markdown has `,p`, and LaTeX has vimtex's `,l…`.

## Debugging

`,d` drives nvim-dap with dap-ui in Python buffers (`,db`
breakpoint, `,dB` conditional, `,dc` continue or start, `,di` / `,do` / `,dO` step into, over,
out, `,dr` REPL, `,dl` run last, `,dt` terminate, `,de` evaluate). dap-ui stays open after the
program ends so its output can be read (`,du` closes it). Breakpoints show as `●` (`◆` with a
condition) and the stopped line is tinted green. Python uses debugpy and runs the file with the
project's `.venv` (uv's, found upward from the file), else `$VIRTUAL_ENV`, else `python3`.

## LaTeX

vimtex compiles with latexmk and shows the PDF in Skim with SyncTeX; texlab gives completion
and diagnostics; the snippets in `snippets/tex.lua` expand as you type, but never right after
a `\` (typing `\sum` or `\begin` by hand stays as typed), and `beg` only at the start of a
line. `<=>` is typed as `<=` then `>`, `<->` as `<-` then `>`; in math `x12` gives
`x_{12}`. Keys under `,l` in `.tex` files are vimtex's own, labelled in which-key: `,ll`
compile, `,lv` view / forward search, `,le` errors, `,lt` table of contents, `,lc` clean,
`,lx` reload, `,lw` count words. Cmd+Shift+click in Skim jumps back to the line (set up by
`link.sh`, which also makes Skim reload the PDF when it changes).
Put `% !TEX program = lualatex` on the first line for another engine.

Builds go to `build/` next to the main file, so the project folder keeps only sources; texlab
reads the same folder, which keeps citation and label completion working. `link.sh` links
`config/latex/latexmkrc` to `~/.latexmkrc` (BibTeX runs when a `.bib` exists); a `latexmkrc`
in a project still wins. Folds follow the preamble and sections.

For a Brazilian thesis, `abnt` expands to a complete abnTeX2 skeleton (cover, abstract in two
languages, table of contents, `abntex2cite` with `abntex2-alf`), and `capa`, `resumo`,
`abstract`, `citacao`, `citeonline` and `apud` insert the pieces. Only `abntex2` and
`abntex2cite` ship with MacTeX; `biblatex-abnt` does not, so citations go through BibTeX.

ltex-ls-plus checks grammar in Portuguese (`pt-BR`) by default. A comment such as
`% LTeX: language=en-US` switches the language from that line on. Its spelling rules are off:
vim spell already underlines typos, and one word list (`zg`) is simpler than two that disagree.
`<leader>uG` turns grammar off and on; vim spell stays on as before.

## Markdown and notes

render-markdown.nvim draws headings, tables, code blocks and checkboxes in the buffer; the
line under the cursor and insert mode show the raw text. `<leader>um` turns it off.
Cursor's `.mdc` rule files are Markdown too (`config/options.lua`), so they get all of this.
render-markdown sets `conceallevel` on every redraw, so it is set up again with the global value
whenever that changes (`<leader>uc`). LaTeX math
is not rendered there: `,p` builds an HTML page with pandoc (math as MathML, images embedded),
opens it in the browser and rebuilds it on every save. Raw HTML in the Markdown is shown as
text, so a `<script>` in someone else's file cannot read the embedded local files.

Notes are plain Markdown files in `settings.notes.dir` (`~/notes`, created by the first `<leader>n`
key; change it in `local.lua`), handled by obsidian.nvim, which loads only there and needs no
Obsidian app or account: the folder is only a folder of `.md` files. `<leader>nf` / `ng` find and
grep them, `nn` asks for a title and creates `the-title.md`, `nd` opens today's note in `daily/`,
and `nb` lists the notes that link to the current one (on a `#` heading, those that link to that
heading). Links are `[[note]]`: obsidian.nvim completes them, `<CR>` or `gd` follows one and `gr`
lists references; `<CR>` on a checkbox ticks it. No YAML frontmatter is written. marksman serves
Markdown outside the notes folder only (`after/lsp/marksman.lua`), so the two never answer the
same request twice. rumdl lints as you type, with the rules in `config/rumdl/rumdl.toml` (line
length 100); it formats on save only under a `.rumdl.toml` or `.markdownlint.*`, so notes are
never restyled.

## Notes

- Diff colors are tinted backgrounds over Dracula, so the code stays readable.
- Spell checking (`en_us`, `pt_br`) is on for prose files; `install.sh` downloads the
  Portuguese spell file. Words added with `zg` (in any of the two languages) go to the versioned
  `spell/en.utf-8.add` (`spellfile`); Neovim compiles it at startup when it is newer, as after a
  `git pull`. Without `spellfile`, `zg` would write outside the repository.
- `.tex` files are LaTeX, not plain TeX (`g:tex_flavor`).
