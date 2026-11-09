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
  if ! have latexmk || ! mason texlab; then
    skip "LaTeX project" "latexmk or texlab missing"
    return
  fi
  start_nvim "$T/tcc" main.tex
  probe "texlab attaches to tex" "$(clients texlab)" 1 60
  probe "vimtex folds by section" 'vim.wo.foldexpr' 'vimtex#fold#level(v:lnum)' 10
  probe "opening the file starts the live build" 'vim.g.test_compiled or 0' 1 180
  send ":call append(1, '% live')<CR>"
  probe "idle saves the file for the live build" 'vim.bo.modified and 1 or 0' 0 10
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

tex_programs() {
  local program missing=()
  for program in latexmk bibtex chktex texcount; do
    have "$program" || missing+=("$program")
  done
  [ "${#missing[@]}" -eq 0 ] || {
    echo "missing ${missing[*]}: run macos/nvim/tex.sh"
    return 1
  }
}

tex_packages_step() {
  local dir out="" log
  dir="$(mktemp -d)"
  log="$dir/log"
  cat >"$dir/tlmgr" <<'STUB'
#!/usr/bin/env bash
[ "$1" = info ] && exec cat "$TEX_INSTALLED"
echo "tlmgr $*" >>"$TEX_LOG"
[ "$1" != "${TEX_FAIL:-}" ]
STUB
  cat >"$dir/sudo" <<'STUB'
#!/usr/bin/env bash
echo "sudo $1" >>"$TEX_LOG"
[ "$1" = -v ] || exec "$@"
STUB
  chmod +x "$dir/tlmgr" "$dir/sudo"
  printf '%s\n' latexmk latexmk.universal-darwin chktex texcount abntex2 cm-super enumitem fontname relsize sansmathaccent >"$dir/all"
  grep -vxE 'chktex|relsize' "$dir/all" >"$dir/some"
  local -a env=(PATH="$dir:$PATH" TEX_LOG="$log")
  env "${env[@]}" TEX_INSTALLED="$dir/all" "$DOT/macos/nvim/tex.sh" >/dev/null 2>&1 || out="$out
with every package installed the step failed"
  [ -s "$log" ] && out="$out
with every package installed the step still ran: $(tr '\n' ';' <"$log")"
  env "${env[@]}" TEX_INSTALLED="$dir/some" "$DOT/macos/nvim/tex.sh" >/dev/null 2>&1 || out="$out
installing the missing packages failed"
  [ "$(grep "^tlmgr " "$log" | tr '\n' ';')" = "tlmgr update --self;tlmgr install chktex relsize;" ] || out="$out
the missing packages were not installed alone, after tlmgr updated itself: $(tr '\n' ';' <"$log")"
  env "${env[@]}" TEX_INSTALLED="$dir/some" TEX_FAIL=install "$DOT/macos/nvim/tex.sh" >/dev/null 2>&1 && out="$out
a failed tlmgr install was reported as done"
  : >"$log"
  env "${env[@]}" TEX_INSTALLED="$dir/some" TEX_FAIL=update "$DOT/macos/nvim/tex.sh" >/dev/null 2>&1 && out="$out
a tlmgr that could not update itself was reported as done"
  grep -q "^tlmgr install" "$log" && out="$out
tlmgr installed after it could not update itself"
  rm -rf "$dir"
  [ -z "$out" ] || {
    echo "${out#$'\n'}"
    return 1
  }
}
