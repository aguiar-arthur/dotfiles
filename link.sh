#!/usr/bin/env bash
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC="$HOME/.zshrc"
BEGIN="# >>> dotfiles >>>"
END="# <<< dotfiles <<<"
KEEP_BACKUPS=3

say() { printf '%-8s %s\n' "$1" "$2"; }

links() {
  printf '%s\n' \
    "config/nvim|$HOME/.config/nvim" \
    "config/starship/starship.toml|$HOME/.config/starship.toml" \
    "config/rumdl/rumdl.toml|$HOME/.config/rumdl/rumdl.toml" \
    "config/iterm2/dracula.json|$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles-dracula.json"
}

prune_backups() {
  local dst="$1" old i
  local -a all=()
  while IFS= read -r old; do all+=("$old"); done < <(ls -1d "$dst".bak.* 2>/dev/null | sort)
  for ((i = 0; i < ${#all[@]} - KEEP_BACKUPS; i++)); do
    rm -rf "${all[$i]}"
  done
}

link() {
  local src="$DOT/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say ok "$dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    say backup "$dst"
    prune_backups "$dst"
  fi
  ln -s "$src" "$dst"
  say link "$dst -> $src"
}

pref() {
  local domain="$1" key="$2" value="$3"
  local current
  if current="$(defaults read "$domain" "$key" 2>/dev/null)" && [ "$current" = "$value" ]; then
    say ok "$domain $key"
  else
    defaults write "$domain" "$key" -string "$value"
    say set "$domain $key"
  fi
}

app_preferences() {
  local skim=net.sourceforge.skim-app.skim
  pref com.googlecode.iterm2 "Default Bookmark Guid" \
    "$(sed -n 's/.*"Guid": "\(.*\)".*/\1/p' "$DOT/config/iterm2/dracula.json" | head -n 1)"
  pref "$skim" SKTeXEditorPreset ""
  pref "$skim" SKTeXEditorCommand nvim
  pref "$skim" SKTeXEditorArguments "--headless -c \"VimtexInverseSearch %line '%file'\""
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

while IFS='|' read -r src dst; do link "$src" "$dst"; done < <(links)
zshrc
app_preferences
echo "Done."
