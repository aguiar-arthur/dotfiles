# LaTeX

Writing and building LaTeX: vimtex with latexmk and Skim, texlab, grammar with ltex-ls-plus,
and the snippets. Its relationships are in [map](map.md).

## Language

- **build folder**: `build/` next to the main file, where latexmk writes everything.
- **autosnippet**: a snippet that expands as you type, without the completion menu.
- **ABNT**: the Brazilian thesis norms, through abnTeX2.

## Files

| Path | Holds |
|---|---|
| `config/nvim/lua/plugins/tex.lua` | vimtex: Skim viewer, latexmk into `build/`, folds, quickfix filters, conceal, build notifications, the live build (start on open, save on idle, view sync) |
| `config/nvim/lua/dotfiles/vimtex.lua` | `compiler()`: `idle`, `running` or empty for the buffer's latexmk; the live build and the statusline both ask it |
| `config/nvim/after/ftplugin/tex.lua` | no hard wrap, `,lw`, which-key labels of the daily `,l` keys |
| `config/nvim/snippets/tex.lua` | the LaTeX snippets (documents, text, math, ABNT) |
| `config/nvim/after/lsp/texlab.lua` | texlab reads `build/`, chktex on open and save, latexindent |
| `config/nvim/after/lsp/ltex_plus.lua` | grammar in `pt-BR`, spelling rules off, UTF-16, quiet log |
| `config/latex/latexmkrc` | PDF output, BibTeX when a `.bib` exists, one-second polling, what `,lc` cleans; linked to `~/.latexmkrc` |
| `macos/nvim/link.sh` (`skim_preferences`) | Skim's inverse search to Neovim and reload on change |

## How it works

vimtex compiles with latexmk and shows the PDF in Skim with SyncTeX; texlab gives completion
and diagnostics (vimtex's own completion and insert maps are off). Keys under `,l` are vimtex's
own; which-key names the ones in daily use: `,ll` compile, `,lk` stop, `,lv` view / forward
search, `,le` errors, `,lt` contents, `,lc` / `,lC` clean, `,lx` reload, `,lw` count words (the
others show vimtex's `<Plug>` names). Cmd+Shift+click in Skim jumps back to the line. Put
`% !TEX program = lualatex` on the first line for another engine.

The build is live (`latex_live` in `settings.lua`, on by default): opening a `.tex` file
starts latexmk's continuous mode, a `.tex` buffer is saved on `CursorHold` (`updatetime` is
250 ms) and on `InsertLeave`, and after the first `,lv` every successful build calls
`VimtexView` again, so Skim follows the cursor.

Edits from outside (another program, an AI) rebuild the PDF too, since latexmk watches the
disk. On idle, an unmodified buffer is reloaded (`checktime`, scheduled because it does nothing
inside the autocmd itself), and a modified one is saved only when its file has not changed on
disk since it was read or written (`b:tex_stamp`); otherwise the save is skipped, so Neovim never
overwrites the other program's edit or stops at the "file changed" prompt.

Skim is not activated (`vimtex_view_skim_activate = 0`), so it never takes focus from Neovim;
`,lv` therefore does not bring it to the front. Skim opens by itself after the first successful
build (vimtex's `view_automatic`). With `latex_live = false` nothing starts or saves by itself
and `,ll` is the manual toggle.

Builds go to `build/`, so the project folder keeps only sources; texlab reads the same folder,
which keeps citation and label completion working. A `latexmkrc` in a project still wins over
`~/.latexmkrc`. Folds follow the preamble and sections. Treesitter highlight is off in LaTeX:
vimtex's syntax and conceal are used instead (see [core](core.md)). Lines are not hard-wrapped
(`textwidth=0`). LaTeX formats only on demand with `<leader>lf` (latexindent).

The snippets expand as you type, but never right after a `\` (typing `\sum` or `\begin` by hand
stays as typed), and `beg` only at the start of a line. `<=>` is typed as `<=` then `>`, `<->`
as `<-` then `>`; in math `x12` gives `x_{12}`. friendly-snippets are not loaded for LaTeX, so
these are the only ones.

For a Brazilian thesis, `abnt` expands to a complete abnTeX2 skeleton (cover, abstract in two
languages, contents, `abntex2cite` with `abntex2-alf`), and `capa`, `resumo`, `abstract`,
`citacao`, `citeonline` and `apud` insert the pieces. Only `abntex2` and `abntex2cite` ship
with MacTeX; `biblatex-abnt` does not, so citations go through BibTeX.

ltex-ls-plus checks grammar in Portuguese (`pt-BR`) by default. A comment such as
`% LTeX: language=en-US` switches the language from that line on. Its spelling rules are off:
vim spell already underlines typos, and one word list (`zg`) is simpler than two that disagree.
`<leader>uG` turns grammar off and on.

## Contract

Offers: nothing other contexts rely on.

Consumes:

- [code](code.md): texlab and ltex-ls-plus as servers. They share `.tex` buffers, so ltex is
  pinned to UTF-16 in its `after/lsp` file (the position encoding rule).
- [workspace](workspace.md): completion; LaTeX has its own snippets, not friendly-snippets.
- [install](install.md): Skim and `~/.latexmkrc` (`macos/nvim/link.sh`), and the Mason packages.
- [core](core.md): `settings` (spell languages, servers).

## Pitfalls

- An autosnippet that fires after `\` breaks typing commands by hand; add autosnippets through
  `auto()` in `snippets/tex.lua`, which refuses to expand after a backslash.
- `VimtexCompile` toggles, so the live start first asks `b:vimtex.compiler.is_running()`;
  without it, reloading vimtex (`,lx`) would stop the build it started. It checks that
  `b:vimtex.compiler` exists first: with vimtex's compiler off there is none, and opening a file
  raised `E716`.
- ltex-ls-plus logs at `warning` (`ltex-ls.logLevel`): its default, `fine`, wrote the text of
  every check into `~/.local/state/nvim/lsp.log`.
- Full tests start Neovim with `view_automatic` off and the build and view events recorded in
  `start_nvim`, so a test build never opens Skim.

## Checks

| What | Where |
|---|---|
| `,lw`, no hard wrap | `tests/keys.lua` |
| Live build, outside edits, view sync (stubs) | quick: `tests/autocmds.lua` |
| Skim preferences | quick: `Skim is set up for Neovim` in `tests/nvim.sh` |
| A real live build into `build/`, save on idle, ltex, `u G` | full: `test_tex` in `tests/tex.sh` |
| Every snippet expands, no trigger is defined twice, the common ones type what they should | quick: `tests/tex_snippets.lua` |
| Snippets typed for real | full: `test_snippets`, driven by `tests/snippets.lua` |

## Changing it

- **A snippet**: add it to `snippets/tex.lua` beside its kind, a typed case in
  `tests/snippets.lua`, a row in the README's snippet tables.
- **A vimtex option**: `init` in `tex.lua` (vimtex reads `g:` variables before it loads).
