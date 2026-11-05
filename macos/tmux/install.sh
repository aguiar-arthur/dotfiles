#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

step_whichkey() {
  title "whichkey-tmux"
  "$HERE/whichkey.sh"
}

echo "Installing tmux, its tmux.conf and the whichkey-tmux plugin. Homebrew may ask for your password."
run_steps brew link whichkey || exit 1
echo "A tmux server already running needs: tmux source-file ~/.config/tmux/tmux.conf"
