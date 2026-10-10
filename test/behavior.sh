#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

behavior_nvim() {
  section "Behavior: Neovim"
  require nvim git || return
  work_dir
  nvim_env
  sample_repo "$WORK/sample"
  export TEST_FILE="$WORK/sample/a.lua"
  if ! with_timeout 900 nvim --headless --cmd 'let g:loaded_spellfile_plugin=1' "+Lazy! restore" +qa >"$WORK/restore.txt" 2>&1; then
    fail "Lazy! restore"
    return
  fi
  run_nvim_lua "$REPO/test/nvim/behavior.lua"
}

behavior_emacs() {
  section "Behavior: Emacs"
  require emacs git || return
  work_dir
  emacs_env
  run_ert behavior -l test/emacs/boot.el -l test/emacs/behavior-tests.el
}

behavior_nvim
behavior_emacs
report "behavior"
