#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

echo "Installing the terminal: Starship, tmux, iTerm2 and its font, the ~/.zshrc block. Homebrew may ask for your password."
run_steps brew link || exit 1
echo "Open a new terminal (or run: exec zsh)."
