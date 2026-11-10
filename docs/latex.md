# LaTeX

Writing and building LaTeX: vimtex with latexmk and Skim, and texlab. Its relationships are in
[map](map.md).

## How it works

vimtex compiles with latexmk and shows the PDF in Skim with SyncTeX; texlab gives completion
(`\ref`, `\cite`), go to definition, symbols and chktex diagnostics (vimtex's own completion and
insert maps are off). Keys under `,l` are vimtex's own; which-key names the ones in daily use.
Cmd+Shift+click in Skim jumps back to the line. Put `% !TEX program = lualatex` on the first
line for another engine.

There is no LaTeX code of our own, only vimtex's and texlab's settings. Nothing builds by itself:
`,ll` starts latexmk's continuous mode, which rebuilds on each save until `,lk` (or `,ll` again)
stops it, and Skim reloads the PDF when it changes. Errors open vimtex's quickfix list. LaTeX
stays at building, reading and moving through a document: a live build, a grammar server or
snippets of our own cost more upkeep than they give.

Skim is not activated (`vimtex_view_skim_activate = 0`), so it never takes focus from Neovim;
`,lv` therefore does not bring it to the front. Skim opens by itself after the first successful
build (vimtex's `view_automatic`).

Builds go to `build/`, so the project folder keeps only sources; texlab reads the same folder,
which keeps citation and label completion working. A `latexmkrc` in a project still wins over
`~/.latexmkrc`. Folds follow the preamble and sections. Treesitter highlight is off in LaTeX:
vimtex's syntax and conceal are used instead (see [core](core.md)). Lines are not hard-wrapped
(`textwidth=0`). LaTeX formats only on demand with `<leader>lf` (latexindent). Snippets are
friendly-snippets' LaTeX ones, through the completion menu like any other language.

## Pitfalls

- Full tests start Neovim with `view_automatic` off and the build and view events recorded in
  `start_nvim`, so a test build never opens Skim.

## Checks

`tests/keys.lua` (`,lw`, no hard wrap); full: `test_tex` in `tests/tex.sh` (a real abnTeX2 build
into `build/` with `,ll`); Skim's preferences: quick, in `tests/nvim.sh`.

## Changing it

- **A vimtex option**: `init` in `tex.lua` (vimtex reads `g:` variables before it loads).
