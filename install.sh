#!/usr/bin/env bash
set -uo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=()

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
  brew bundle --file "$DOT/Brewfile"
}

step_nvim() {
  title "Neovim: plugins, Mason servers and tools, treesitter parsers"
  have nvim || {
    echo "ERROR  nvim not found"
    return 1
  }
  XDG_CONFIG_HOME="$DOT/config" nvim --headless "+Lazy! restore" +qa || return 1
  XDG_CONFIG_HOME="$DOT/config" nvim --headless "+lua require('dotfiles.install').run()"
}

step_link() {
  title "Links and app preferences"
  "$DOT/link.sh"
}

echo "Installing everything. Homebrew and MacTeX may ask for your password."
for step in brew nvim link; do
  "step_$step" || FAILED+=("$step")
done

if [ "${#FAILED[@]}" -gt 0 ]; then
  printf '\nFailed: %s. Fix the errors above and run ./install.sh again.\n' "${FAILED[*]}"
  exit 1
fi
printf '\nDone. Open a new terminal (or run: exec zsh).\n'
