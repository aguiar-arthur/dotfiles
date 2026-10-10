#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

smoke_nvim() {
  section "Smoke: Neovim from scratch"
  require nvim git || return
  work_dir
  nvim_env
  if with_timeout 900 nvim --headless --cmd 'let g:loaded_spellfile_plugin=1' "+Lazy! restore" +qa >"$WORK/restore.txt" 2>&1; then
    ok "Lazy! restore at the versions in lazy-lock.json"
  else
    fail "Lazy! restore"
    tail -n 15 "$WORK/restore.txt" | sed 's/^/        /'
    return
  fi
  run_nvim_lua "$REPO/test/nvim/smoke.lua"
}

smoke_emacs() {
  section "Smoke: Emacs, batch"
  require emacs || return
  work_dir
  emacs_env
  if with_timeout 1800 emacs --batch -l "$HOME/.config/emacs/early-init.el" -l "$HOME/.config/emacs/init.el" >"$WORK/install.txt" 2>&1; then
    ok "packages installed"
  else
    fail "package install"
    tail -n 15 "$WORK/install.txt" | sed 's/^/        /'
    return
  fi
  run_ert smoke -l test/emacs/boot.el -l test/emacs/smoke-tests.el
}

smoke_nvim
smoke_emacs
report "smoke"
