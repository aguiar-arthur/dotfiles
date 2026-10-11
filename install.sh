#!/usr/bin/env bash
set -uo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=()
ONLY="${1:-}"
BREWFILE="$DOT/Brewfile"

case "$ONLY" in
"") ;;
nvim) BREWFILE="$DOT/Brewfile.nvim" ;;
*)
  echo "usage: ./install.sh [nvim]" >&2
  exit 2
  ;;
esac

title() { printf '\n== %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

load_brew() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$candidate" ] && eval "$("$candidate" shellenv)" && return
  done
}

step_brew() {
  title "Homebrew and programs"
  have brew || load_brew
  if ! have brew; then
    echo "Installing Homebrew (it asks for your password)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
    load_brew
  fi
  brew bundle --no-upgrade --file "$BREWFILE"
}

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
  nvim --headless "+Lazy! restore" +qa || return 1
  nvim --headless "+lua require('dotfiles.install').run()"
}

step_link() {
  title "Links and app preferences"
  "$DOT/link.sh" ${ONLY:+"$ONLY"}
}

if [ "$ONLY" = nvim ]; then
  echo "Installing Neovim only: its programs, ~/.config/nvim and its plugins. Homebrew may ask for your password."
else
  echo "Installing everything. Homebrew and MacTeX may ask for your password."
fi
for step in brew link nvim; do
  "step_$step" || FAILED+=("$step")
done

if [ "${#FAILED[@]}" -gt 0 ]; then
  printf '\nFailed: %s. Fix the errors above and run ./install.sh%s again.\n' "${FAILED[*]}" "${ONLY:+ $ONLY}"
  exit 1
fi
if [ "$ONLY" = nvim ]; then
  printf '\nDone. Your shell and terminal settings were not touched.\n'
else
  printf '\nDone. Open a new terminal (or run: exec zsh).\n'
fi
