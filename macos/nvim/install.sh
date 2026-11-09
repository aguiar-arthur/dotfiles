#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

step_nvim() {
  title "Neovim: plugins, Mason servers and tools, treesitter parsers"
  have nvim || {
    echo "ERROR  nvim not found"
    return 1
  }
  [ "$(readlink "$HOME/.config/nvim")" = "$DOT/config/nvim" ] || {
    echo "ERROR  ~/.config/nvim does not link to $DOT/config/nvim"
    return 1
  }
  perl -e 'alarm 900; exec @ARGV' nvim --headless "+Lazy! restore" +qa || return 1
  nvim --headless "+lua require('dotfiles.install').run()"
}

echo "Installing Neovim: its programs (with MacTeX, a large download), ~/.config/nvim and its plugins. Homebrew and MacTeX may ask for your password; the shell and terminal are left alone."
run_steps brew link nvim
