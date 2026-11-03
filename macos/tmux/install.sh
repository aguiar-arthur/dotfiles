#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

echo "Installing tmux and its tmux.conf. Homebrew may ask for your password."
run_steps brew link || exit 1
echo "A tmux server already running needs: tmux source-file ~/.config/tmux/tmux.conf"
