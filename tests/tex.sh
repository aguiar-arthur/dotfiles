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
  if ! have latexmk || ! mason texlab; then
    skip "LaTeX project" "latexmk or texlab missing"
    return
  fi
  start_nvim "$T/tcc" main.tex
  probe "texlab attaches to tex" "$(clients texlab)" 1 60
  probe "vimtex folds by section" 'vim.wo.foldexpr' 'vimtex#fold#level(v:lnum)' 10
  probe "opening the file does not start a build" 'vim.g.test_compiled or 0' 0 3
  keys ,ll
  probe ",ll builds the PDF" 'vim.g.test_compiled or 0' 1 180
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
  stop_nvim
}
