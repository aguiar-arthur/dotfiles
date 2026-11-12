#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

URL=https://github.com/aguiar-arthur/whichkey-tmux.git
DIR="$HOME/.config/tmux/plugins/whichkey-tmux"

die() {
  echo "ERROR  $1"
  exit 1
}

have git || die "git not found"
if [ -d "$DIR/.git" ]; then
  origin="$(git -C "$DIR" remote get-url origin 2>/dev/null)"
  case "${origin%.git}" in
  */aguiar-arthur/whichkey-tmux | *:aguiar-arthur/whichkey-tmux) ;;
  *) die "$DIR is a clone of ${origin:-a repository without origin}, not $URL; move it away and run again" ;;
  esac
  if GIT_TERMINAL_PROMPT=0 perl -e 'alarm 120; exec @ARGV' git -C "$DIR" pull --quiet --ff-only; then
    say pull "$DIR"
  else
    say kept "$DIR (could not pull: network, local changes or a diverged branch)"
  fi
elif [ -e "$DIR" ] || [ -L "$DIR" ]; then
  die "$DIR exists but is not a clone of $URL; move it away and run again"
else
  mkdir -p "$(dirname "$DIR")"
  if ! GIT_TERMINAL_PROMPT=0 perl -e 'alarm 120; exec @ARGV' git clone --quiet "$URL" "$DIR"; then
    rm -rf "$DIR"
    die "could not clone $URL (network?)"
  fi
  say clone "$DIR"
fi
[ -x "$DIR/whichkey.tmux" ] || die "$DIR/whichkey.tmux is missing or not executable"
