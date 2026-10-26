#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

ZSHRC="$HOME/.zshrc"
BEGIN="# >>> dotfiles >>>"
END="# <<< dotfiles <<<"

iterm_preferences() {
  pref com.googlecode.iterm2 "Default Bookmark Guid" \
    "$(sed -n 's/.*"Guid": "\(.*\)".*/\1/p' "$DOT/config/iterm2/dracula.json" | head -n 1)"
}

zshrc() {
  touch "$ZSHRC"
  local base wanted
  base="$(awk -v b="$BEGIN" -v e="$END" '$0 == b { skip = 1; next } $0 == e { skip = 0; next } !skip' "$ZSHRC")"
  wanted="$(printf '%s\n\n%s\n%s\n%s' "$base" "$BEGIN" "[ -r \"$DOT/config/zsh/dotfiles.zsh\" ] && source \"$DOT/config/zsh/dotfiles.zsh\"" "$END" | sed '/./,$!d')"
  if [ "$wanted" = "$(cat "$ZSHRC")" ]; then
    say ok "$ZSHRC"
    return
  fi
  cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d%H%M%S)"
  prune_backups "$ZSHRC"
  printf '%s\n' "$wanted" >"$ZSHRC"
  say zshrc "$ZSHRC sources config/zsh/dotfiles.zsh"
}

link config/starship/starship.toml "$HOME/.config/starship.toml"
link config/iterm2/dracula.json "$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles-dracula.json"
zshrc
iterm_preferences
echo "Done."
