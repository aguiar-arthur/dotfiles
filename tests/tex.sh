ltex_count() {
  echo "#vim.tbl_filter(function(d) return d.source == \"LTeX\" and (d.code == \"MORFOLOGIK_RULE_PT_BR\") $1 true end, vim.diagnostic.get(0)) > 0 and 1 or 0"
}

test_tex() {
  cat >"$T/tcc/main.tex" <<'TEX'
\documentclass[12pt,a4paper,brazil]{abntex2}
\usepackage[T1]{fontenc}
\usepackage[alf]{abntex2cite}
\titulo{Um trabalho}
\autor{Fulano}
\local{Brasil}
\data{2026}
\begin{document}
\imprimircapa
\tableofcontents
\chapter{Introdução}
Segundo \citeonline{knuth84}, o \TeX{} é bom.
Eles vai para casa com uma palavr errada.
\section{Segunda parte}
Texto.
\bibliographystyle{abntex2-alf}
\bibliography{referencias}
\end{document}
TEX
  printf '@book{knuth84, author={Knuth, Donald E.}, title={The TeXbook}, publisher={Addison-Wesley}, year={1984}, address={Reading}}\n' >"$T/tcc/referencias.bib"
  cat >"$T/compiled.lua" <<'LUA'
vim.g.vimtex_view_automatic = 0
vim.api.nvim_create_autocmd("User", {
  pattern = "VimtexEventCompileSuccess",
  callback = function()
    vim.g.test_compiled = 1
  end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "VimtexEventView",
  callback = function()
    vim.g.test_viewed = 1
  end,
})
LUA
  if ! have latexmk || ! mason texlab; then
    skip "LaTeX project" "latexmk or texlab missing"
    return
  fi
  start_nvim "$T/tcc" main.tex
  probe "texlab attaches to tex" "$(clients texlab)" 1 60
  probe "vimtex folds by section" 'vim.wo.foldexpr' 'vimtex#fold#level(v:lnum)' 10
  send ":luafile $T/compiled.lua<CR>:VimtexCompileSS<CR>"
  probe "VimtexCompileSS builds the thesis" 'vim.g.test_compiled or 0' 1 180
  probe "compiling never opens the PDF viewer" 'vim.g.test_viewed or 0' 0 3
  if [ -f "$T/tcc/build/main.pdf" ] && [ -f "$T/tcc/build/main.bbl" ]; then
    pass "PDF and bibliography land in build/"
  else
    fail "PDF and bibliography land in build/" "$(ls "$T/tcc/build" 2>&1)"
  fi
  if [ -z "$(find "$T/tcc" -maxdepth 1 \( -name '*.aux' -o -name '*.log' -o -name '*.pdf' \))" ]; then
    pass "the project folder keeps only sources"
  else
    fail "the project folder keeps only sources" "$(ls "$T/tcc")"
  fi
  if mason ltex-ls-plus; then
    probe "ltex_plus attaches to tex" "$(clients ltex_plus)" 1 90
    probe "ltex_plus reports grammar" "$(ltex_count '~=')" 1 90
    probe "ltex_plus leaves spelling to vim spell" "$(ltex_count '==')" 0 5
    keys Space u G
    probe "<leader>uG turns grammar off" "$(clients ltex_plus)" 0 15
    keys Space u G
    probe "<leader>uG turns grammar on" "$(clients ltex_plus)" 1 60
  else
    skip "ltex_plus attaches to tex" "not installed by Mason"
  fi
  stop_nvim
}

test_snippets() {
  printf '\\documentclass{article}\n\\begin{document}\nText.\n\\end{document}\n' >"$PROJ/snip.tex"
  start_nvim "$PROJ" snip.tex
  send ":3<CR>:luafile $DOT/tests/snippets.lua<CR>"
  probe "LaTeX snippets expand as typed" 'vim.g.test_snippets or ""' ok 90
  stop_nvim
}
