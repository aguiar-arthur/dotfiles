#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

section "Keymaps: real leader maps against docs/keymaps.md"
require nvim emacs python3 git || {
  report "keys"
  exit $?
}

work_dir
export TEST_ROOT="$REPO"

sample_repo "$WORK/sample"

(
  nvim_env
  export TEST_OUT="$WORK/nvim.tsv" TEST_FILE="$WORK/sample/a.lua"
  with_timeout 600 nvim --headless --cmd 'let g:loaded_spellfile_plugin=1' "+Lazy! restore" +qa >/dev/null 2>&1
  with_timeout 180 nvim --headless --cmd 'let g:loaded_spellfile_plugin=1' "+luafile $REPO/test/keys/dump-nvim.lua" >/dev/null 2>&1
)
[ -s "$WORK/nvim.tsv" ] && ok "Neovim leader map dumped" || fail "Neovim leader map was not dumped"

(
  emacs_env
  export TEST_OUT="$WORK/emacs.tsv"
  cd "$REPO" && with_timeout 600 emacs --batch -Q -l test/emacs/boot.el -l test/keys/dump-emacs.el >/dev/null 2>&1
)
[ -s "$WORK/emacs.tsv" ] && ok "Emacs leader map dumped" || fail "Emacs leader map was not dumped"

if [ -s "$WORK/nvim.tsv" ] && [ -s "$WORK/emacs.tsv" ]; then
  result="$(python3 "$REPO/test/keys/compare.py" "$WORK/nvim.tsv" "$WORK/emacs.tsv" "$REPO/docs/keymaps.md")"
  summary="$(printf '%s\n' "$result" | head -n 1)"
  problems="$(printf '%s\n' "$result" | tail -n +2)"
  if [ -z "$problems" ]; then
    ok "$summary, no differences"
  else
    while IFS= read -r line; do fail "$line"; done <<<"$problems"
  fi
fi

report "keys"
