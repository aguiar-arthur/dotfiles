#!/usr/bin/env bash
# Cria os symlinks do dotfiles. Idempotente: pode rodar quantas vezes quiser.
# Se o destino já existir (e não for o link certo), ele é movido para <destino>.bak.<data>.
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

# Neovim e Starship (macOS e Linux)
link "$DOT/config/nvim" "$HOME/.config/nvim"
link "$DOT/config/starship/starship.toml" "$HOME/.config/starship.toml"

# iTerm2 (só macOS): o iTerm lê Dynamic Profiles desta pasta automaticamente
if [[ "$OSTYPE" == darwin* ]]; then
  link "$DOT/config/iterm2/dracula.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles-dracula.json"
fi

# Ativa o Starship no zsh (bloco marcado, adicionado uma única vez)
ZSHRC="$HOME/.zshrc"
MARK="# >>> dotfiles: starship >>>"
if ! grep -qF "$MARK" "$ZSHRC" 2>/dev/null; then
  cat >> "$ZSHRC" <<'ZSH'

# >>> dotfiles: starship >>>
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
# <<< dotfiles: starship <<<
ZSH
  echo "zshrc  bloco do starship adicionado em $ZSHRC"
else
  echo "ok     $ZSHRC (starship já configurado)"
fi

echo
echo "Pronto. Abra um novo terminal. No iTerm2: Settings > Profiles > 'Dotfiles (Dracula)' > Other Actions > Set as Default."
