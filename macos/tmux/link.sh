#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

link config/tmux/tmux.conf "$HOME/.config/tmux/tmux.conf"
echo "Done."
