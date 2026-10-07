# Neovim

A general-purpose editor (LSP, completion, git, debugging, picker, file tree, terminal) with a
complete LaTeX workflow. Requires **Neovim ≥ 0.11** (native `vim.lsp.config` /
`vim.lsp.enable`); tested on 0.12. Keys are in [keymaps.md](keymaps.md).

## Structure

```text
config/nvim/
  init.lua                    version check, Lua bytecode cache, loads lua/config/*
  lazy-lock.json              last working plugin commits (versioned, see maintenance.md)
  lua/config/
    options.lua               options and leaders
    keymaps.lua               core keys that need no plugin
    autocmds.lua              editor behaviour driven by events
    lazy.lua                  lazy.nvim bootstrap and settings
  lua/plugins/                one spec file per concern
    colorscheme.lua           Dracula + diff colors
    snacks.lua                picker, file tree, terminal, lazygit, dashboard, notifications, toggles
    completion.lua            blink.cmp + LuaSnip
    lsp.lua                   servers, Mason, diagnostics, LSP keys
    formatting.lua            conform.nvim
    treesitter.lua            nvim-treesitter (main branch)
    editor.lua                gitsigns, diffview, flash, harpoon, mini.*, todo-comments, Trouble, sessions
    debug.lua                 nvim-dap + UI + virtual text
    ui.lua                    icons, lualine, which-key
    lang/tex.lua              vimtex
  after/lsp/<server>.lua      per-server settings (lua_ls, basedpyright, jsonls, yamlls, texlab)
  after/ftplugin/tex.lua      LaTeX buffer options and `,l…` keys
  after/ftplugin/markdown.lua `,p` browser preview
  snippets/tex.lua            LaTeX and Beamer snippets
```

`init.lua` stops with an error on Neovim older than 0.11 and enables `vim.loader` (bytecode
cache) before loading `options`, `keymaps`, `autocmds` and `lazy`, in that order: leaders must
exist before any key is mapped.

## Options

- Leaders: `<Space>` and `,` (vimtex uses the local leader for `,l…`).
- UI: absolute + relative numbers, cursor line, sign column always on, 8 lines of scroll
  context, global statusline (`laststatus=3`), rounded borders on every floating window
  (`winborder`), visible tabs/trailing spaces, splits open right and below,
  `splitkeep=screen` (the text does not jump when a split opens).
- Long lines wrap on screen in every buffer and stay one line in the file (`wrap`): breaks
  fall between words (`linebreak`), continuation lines keep the indent plus two columns
  (`breakindent`, `breakindentopt=shift:2`), and scrolling moves by screen line
  (`smoothscroll`). `j` / `k` move by screen line too (by file line when given a count), and
  `<leader>uw` turns wrapping off for the current window.
- Editing: 2-space indent with spaces, smart case search, live `:s` preview in a split,
  block selection past line end, `confirm` instead of failing on `:q` with unsaved changes,
  persistent undo (10 000 levels), `grepprg` = ripgrep.
- Diff: `diffopt` adds `algorithm:histogram`, which aligns moved and rewritten blocks better.
  Neovim 0.12 already pairs changed lines (`linematch`) and highlights the changed characters
  (`inline:char`). Removed lines are drawn as `╱` (`fillchars diff`).
- Folds come from treesitter and start open (`foldlevel=99`).
- Spell languages `en_us` and `pt_br`, only turned on for prose. The first time a prose file
  opens, Neovim asks to download the `pt` spell file.
- The system clipboard is set with `vim.schedule` so its provider check does not slow
  startup.
- `.tex` files are LaTeX, not plain TeX (`g:tex_flavor`).
- The Perl, Ruby, Node and Python providers are disabled: no plugin here needs them.

## Autocmds

| Event | Behaviour |
|---|---|
| yank | highlights the yanked text |
| focus gained, terminal closed | `checktime`: reloads files changed outside (latexmk, git) |
| file read | restores the last cursor position (not for git commit/rebase messages) |
| terminal resized | rebalances the splits in every tab |
| help, quickfix, man, checkhealth, vimtex TOC… | `q` closes the window |
| tex, markdown, text, gitcommit, plaintex | spell on |
| before save | creates missing parent directories (ignores URLs like `scp://`) |

## Plugins

lazy.nvim loads everything; `defaults.version = false` follows the latest commit of each
plugin. The checker looks for updates in the background without notifying, and
change detection is silent. luarocks support is off (no plugin needs it), and a few unused
built-in plugins (gzip, tar, zip, tohtml, tutor) are disabled.

| Plugin | Role | Notes |
|---|---|---|
| dracula.nvim | colorscheme | diff colors overridden, see Git diffs |
| snacks.nvim | picker, file tree, terminal, lazygit, dashboard, notifier, input, indent guides, scope, words, big-file and quick-file handling, UI toggles | replaces telescope, nvim-tree, toggleterm, indent-blankline, dressing and noice in one plugin; hidden files show in the tree and pickers |
| blink.cmp | completion | follows `1.*`: releases ship a prebuilt fuzzy matcher, so no Rust toolchain is needed |
| LuaSnip + friendly-snippets | snippets | follows `v2.*`; friendly-snippets loads for every language except LaTeX, which uses `snippets/tex.lua` |
| nvim-lspconfig, mason, mason-lspconfig, mason-tool-installer | LSP | see LSP |
| lazydev.nvim | Neovim API types for lua_ls | also completes `Snacks` and `vim.uv` |
| SchemaStore.nvim | JSON/YAML schemas | used by jsonls and yamlls |
| conform.nvim | formatting | see Formatting |
| nvim-treesitter (`main`) | parsers, highlight, indent, folds | see Treesitter |
| gitsigns.nvim | signs, hunks, blame | current-line blame on, 500 ms delay |
| diffview.nvim | side-by-side diffs, history, merges | see Git diffs |
| flash.nvim | `s` / `S` jumps | also remote and treesitter modes |
| harpoon (harpoon2) | marked files `<leader>m` | |
| mini.ai, mini.surround, mini.pairs, mini.icons | text objects, `gs…` surround, auto pairs, icons | mini.icons also stands in for nvim-web-devicons |
| todo-comments.nvim | TODO highlighting, `]t` `[t` | |
| trouble.nvim | diagnostics, symbols, lists | |
| persistence.nvim | sessions | saved automatically per directory |
| nvim-dap, nvim-dap-ui, nvim-dap-virtual-text, mason-nvim-dap | debugging | debugpy installed by Mason; the UI opens and closes with the session |
| lualine.nvim | statusline | mode, branch, diff, diagnostics, path, latexmk status, LSP clients |
| which-key.nvim | key hints | group names for every leader group |
| vimtex | LaTeX | see LaTeX |

## LSP

Neovim's native API does the work: nvim-lspconfig only provides the default configuration of
each server (its `lsp/` folder), and personal settings go in `after/lsp/<server>.lua`, which
Neovim merges on top.

- **Mason servers** (installed and enabled automatically): lua_ls, basedpyright, ruff, bashls,
  texlab, jsonls, yamlls, taplo, rumdl, html, cssls, vtsls, clangd.
- **System servers:** clojure-lsp comes from the Brewfile and is enabled only when the binary
  is on the PATH.
- **Tools** (mason-tool-installer, two seconds after startup): stylua, shfmt, shellcheck (used
  by bashls), prettier.
- Every server gets blink.cmp's completion capabilities.
- Diagnostics: sorted by severity, virtual text with a `●` prefix and the source when several
  servers report, rounded floats, custom sign icons, nothing updated while typing.

Per-server settings:

| Server | Setting | Why |
|---|---|---|
| basedpyright | `disableOrganizeImports`, standard type checking, open files only | ruff organizes imports |
| ruff | hover disabled on attach | basedpyright gives the better hover |
| lua_ls | LuaJIT runtime, no third-party checks, no telemetry, `missing-fields` off, parameter-type inlay hints | |
| jsonls / yamlls | schemas from SchemaStore.nvim; yamlls' own schema store off | one source of schemas |
| texlab | no build on save, chktex on open and save, latexindent without line-break changes | vimtex compiles; latexindent must not rewrap prose |

LSP keys are buffer-local and created on `LspAttach`. Definitions, references,
implementations and type definitions go through the snacks picker. Inside a diffview tab
they use a custom confirm action: a result in another file opens in a new tab (the snacks
`jump` action is called directly, because its `tab` action routes back through `confirm`),
and a result in the same file jumps in place.

## Formatting

conform.nvim runs on save (1.5 s timeout) and on `<leader>lf`.

| Filetype | Formatter |
|---|---|
| Lua | stylua |
| Python | ruff organize imports + ruff format |
| sh / bash | shfmt |
| JS, TS, JSX, TSX, CSS, HTML, JSON, JSONC, YAML | prettier |
| Markdown | rumdl (markdownlint fixes only; it never rewraps prose) |
| LaTeX | latexindent (from MacTeX) |
| anything else | the LSP formatter, when the server has one (Clojure, TOML, C…) |

TeX, plain TeX and BibTeX are not formatted on save: latexindent is slow and reindents the
whole file, so run `<leader>lf` when you want it. `:FormatToggle` turns format-on-save off
globally (`<leader>uf` does the same), `:FormatToggle!` only for the current buffer.

Linting comes from the language servers themselves (ruff, bashls + shellcheck, texlab +
chktex, lua_ls, rumdl), so there is no separate linter plugin.

## Completion

blink.cmp with sources LSP, path, snippets and buffer (plus lazydev in Lua files). Nothing is
preselected, so `<CR>` only accepts an item you picked and never swallows a newline in prose.
`<Tab>` / `<S-Tab>` and `C-j` / `C-k` move through the list and jump between snippet fields;
`C-Space` opens it or toggles the documentation, `C-e` closes it, `C-b` / `C-f` scroll the
documentation, `C-s` toggles the signature. Documentation and signature help show
automatically. The command line has its own completion with the same keys.

LuaSnip keeps history, enables autosnippets (needed by the LaTeX snippets) and reloads custom
snippets from `snippets/<filetype>.lua`.

## Treesitter

The `main` branch of nvim-treesitter is the rewrite for Neovim 0.11+: there is no
`nvim-treesitter.configs` module any more, parsers are compiled locally (needs the
`tree-sitter` CLI from the Brewfile and a C compiler from the Xcode tools), and highlighting
and indent are switched on by a `FileType` autocmd in `treesitter.lua`. Parsers installed:
bash, c, clojure, cpp, css, diff, html, javascript, json, latex, lua, luadoc, markdown,
markdown_inline, python, query, regex, ruby, toml, tsx, typescript, vim, vimdoc, yaml.
Installation is asynchronous and skips what already exists; without the CLI a warning
explains what to install. Filetypes without a parser are skipped silently.

LaTeX buffers do not start treesitter: vimtex handles highlighting, folds and concealment, and
vimtex advises against running both.

## Git diffs

| What | How |
|---|---|
| Signs and hunks | gitsigns: `]c` `[c`, stage, reset, preview, blame |
| Side-by-side diff of every change | diffview: `<leader>gv` |
| History | diffview: `<leader>gh` (file, or selected lines in visual mode), `<leader>gH` (repo) |
| A branch against `origin/HEAD` | diffview: `<leader>gV` |
| All hunks with preview | snacks picker: `<leader>gc` |

Inside diffview: `Tab` / `S-Tab` next / previous file, `-` stages or unstages the file under
the cursor in the panel, `g?` lists every key, `q` closes. Merge conflicts open in three
columns (ours · result · theirs), `[x` / `]x` move between conflicts and `<leader>co` / `ct` /
`cb` / `ca` take ours / theirs / base / all. `enhanced_diff_hl` shows deleted lines in red on
the left instead of as "changed".

**Colors.** Dracula paints added lines solid green with dark text, drops syntax colors on
changed lines and greys out the changed text. The overrides use tinted backgrounds instead,
so the code stays readable:

| Group | Background | Meaning |
|---|---|---|
| `DiffAdd` | `#2f4f42` (green 18% over the background) | added line |
| `DiffDelete` | `#4f323c` (red 18%), foreground `#6c4652` for the `╱` filler | removed line |
| `DiffChange` | `#34414e` (cyan 12%) | changed line |
| `DiffText` | `#466372` (cyan 30%), bold | the characters that changed |

Emacs uses the same values ([emacs.md](emacs.md#git-diffs)).

**LSP inside a diff.** Diffview marks old revisions as "not a file", so language servers skip
them, except the index copy (`diffview://…/.git/:0:/file`), which stays a normal buffer so
`:w` can stage it. Servers then attached to it and failed on a path that does not exist
(marksman crashed on it). A `BufFilePost` autocmd sets `buftype=acwrite` on `diffview://`
buffers: `:w` still works (diffview stages through `BufWriteCmd`) and Neovim's LSP treats the
buffer as virtual. The working-tree file, usually on the right, keeps its servers, and
navigation from it opens other files in new tabs (see LSP).

## LaTeX

**vimtex** compiles with latexmk in continuous mode and shows the PDF in **Skim** with
SyncTeX (zathura on Linux, the system viewer otherwise); **texlab** gives completion
(`\cite`, `\ref`, commands), chktex diagnostics, rename and go-to-definition; **LuaSnip**
expands the snippets; **latexindent** formats on demand. Requires MacTeX and Skim.

| Key in `.tex` | Action |
|---|---|
| `,ll` | toggle continuous compilation |
| `,lk` / `,lK` | stop the compiler / all compilers |
| `,lv` | open or refresh the PDF and run forward search |
| `,le` / `,lo` / `,lg` | errors / latexmk output / status |
| `,lt` / `,lT` | table of contents / toggle it |
| `,lc` / `,lC` | clean auxiliary files / also the PDF |
| `,li` / `,lw` / `,lr` | project info / word count / reload vimtex |
| `<leader>lf` | format with latexindent |
| `<leader>uc` | toggle conceal |

vimtex editing: `dse` / `cse` (environment), `dsc` / `csc` (command), `ie` / `ae`, `i$` / `a$`,
`tsf` (toggle fraction), `]]` / `[[` (sections).

Settings worth knowing:

- vimtex is not lazy-loaded by filetype: it handles its own loading.
- Skim: forward search on every compile, Skim comes to the front on `,lv`, reading bar on.
- The quickfix list opens only on errors, without stealing focus, and hides over/underfull
  box and font-shape warnings.
- TOC on the left, 40 columns. Conceal renders accents, ligatures, citations, Greek letters,
  math symbols, fractions, sub/superscripts and styles; the cursor line shows the source.
- vimtex's insert-mode maps (`` `a `` → `\alpha`) clash with the snippets and are off; its
  completion is off too, because texlab provides it through blink.cmp.
- A notification reports each successful or failed compilation; `,le` lists the errors.
- Buffer options (`after/ftplugin/tex.lua`): spell on, conceal level 2, no hard wrapping
  (`textwidth=0`, no `t` in `formatoptions`).
- The `,l…` keys are defined in `after/ftplugin/tex.lua` (not left to vimtex) so they carry
  descriptions for which-key.

**Inverse search (Skim → Neovim, Cmd+Shift+click on the PDF):** in *Skim → Preferences →
Sync* choose *Custom*, command `nvim`, arguments
`--headless -c "VimtexInverseSearch %line '%file'"`.

**Other engines:** put `% !TEX program = lualatex` (or `xelatex`) on the first line. For
`minted` / `-shell-escape`, add a `.latexmkrc` to the project with
`$pdflatex = 'pdflatex -shell-escape %O %S';`.

### Snippets

`snippets/tex.lua` has two kinds: autosnippets expand as soon as the trigger is typed and
check whether the cursor is in text or math (via vimtex's math-zone detection); regular
snippets appear in the completion menu. `<Tab>` / `<S-Tab>` move between fields.

| Context | Type | Result |
|---|---|---|
| text | `mk` · `dm` · `beg` | `$…$` · `\[…\]` · `\begin{…}…\end{…}` |
| math | `a//` · `(a+b)//` | `\frac{a}{}` · `\frac{a+b}{}` |
| math | `x2` · `__` · `td` · `sr` · `cb` | `x_2` · `_{}` · `^{}` · `^2` · `^3` |
| math | `;a` `;b` `;G` `;o`… | `\alpha` `\beta` `\Gamma` `\omega`… |
| math | `->` `=>` `<=` `!=` `...` `xx` `ooo` | `\to` `\implies` `\leq` `\neq` `\dots` `\times` `\infty` |
| math | `sum` `int` `lim` `part` `sq` `lr(` | sum, integral, limit, partial, root, `\left( \right)` |
| math | `RR` `NN` `ZZ` `QQ` `CC` | `\mathbb{R}`… |
| math | `sin` `cos` `log`… | `\sin` `\cos` `\log`… (only without a backslash already) |

Alphabetic triggers respect word boundaries; symbol triggers expand anywhere.

Menu snippets: `eqn`, `ali`, `thm`, `prf`, `ite`, `enu`, `fig`, `tab`, `sec` / `ssec`, `cit`,
`ref`, `eqr`, `doc` (full preamble)…

### Beamer

Beamer is a normal document class, so the workflow is the same: `,ll` compiles, `,lv` opens
the PDF (Skim: *View → Presentation* for full screen), and forward/inverse search work per
slide.

| Snippet | Result |
|---|---|
| `bdoc` | Beamer preamble + title slide + outline |
| `frm` | `\begin{frame}{…}…\end{frame}` |
| `fimg` | frame with a centered image |
| `col` | two columns |
| `blk` / `ablk` | block / alert block |
| `pau` | `\pause` |

## Markdown

No in-editor rendering. `,p` builds a standalone HTML page with **pandoc** (in Neovim's cache
directory) and opens it in the browser. Math written as `$…$`, `$$…$$`, `\(…\)` or `\[…\]` is
rendered as MathML, with no JavaScript or network, and images are embedded. After the first
`,p`, every save rebuilds the page; refresh the tab (Cmd+R). The page uses a small stylesheet
that follows the system's light or dark mode.

**rumdl** is the Markdown language server: markdownlint-compatible diagnostics as you type
(including broken relative links and `#anchors`), completion of paths and heading anchors in
links, `gd` / `gr` / rename on links and an outline for `<leader>fs`. On save it applies only
safe fixes (fence languages, list markers, spacing). Code actions (`<leader>la`) fix one issue
or ignore a rule for one line. Its rules are in `config/rumdl/rumdl.toml`, linked to
`~/.config/rumdl/rumdl.toml` and used when a project has no `.rumdl.toml` of its own:

- line length 100 (80 flags most prose), not checked in code blocks or tables;
- `<!-- rumdl-disable-line line-length -->` silences one line.

In Markdown, the backtick auto-pairs; in other filetypes it does not, because in LaTeX it
opens quotes (``` ``text'' ```).

## Debugging

nvim-dap with dap-ui (scopes, breakpoints, stacks and watches on the left; REPL and console at
the bottom) and virtual text. mason-nvim-dap installs and configures debugpy for Python.
Keys under `<leader>D` ([keymaps.md](keymaps.md#d-debug)).
