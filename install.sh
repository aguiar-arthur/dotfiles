#!/usr/bin/env bash
# Creates the dotfiles symlinks. Idempotent: safe to run as many times as you like.
# If the target already exists (and is not the right link), it is moved to <target>.bak.<timestamp>.
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok     $dst"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    echo "backup $dst"
  fi
  ln -s "$src" "$dst"
  echo "link   $dst -> $src"
}

# Neovim and Starship (macOS and Linux)
link "$DOT/config/nvim" "$HOME/.config/nvim"
link "$DOT/config/starship/starship.toml" "$HOME/.config/starship.toml"

# iTerm2 (macOS only): iTerm reads Dynamic Profiles from this folder automatically
if [[ "$OSTYPE" == darwin* ]]; then
  link "$DOT/config/iterm2/dracula.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles-dracula.json"
fi

# Enable Starship in zsh (marked block, added only once)
ZSHRC="$HOME/.zshrc"
MARK="# >>> dotfiles: starship >>>"
if ! grep -qF "$MARK" "$ZSHRC" 2>/dev/null; then
  cat >> "$ZSHRC" <<'ZSH'

# >>> dotfiles: starship >>>
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
# <<< dotfiles: starship <<<
ZSH
  echo "zshrc  starship block added to $ZSHRC"
else
  echo "ok     $ZSHRC (starship already configured)"
fi

echo
echo "Done. Open a new terminal. In iTerm2: Settings > Profiles > 'Dotfiles (Dracula)' > Other Actions > Set as Default."
