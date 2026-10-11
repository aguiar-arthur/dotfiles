#!/usr/bin/env bash
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC="$HOME/.zshrc"
BEGIN="# >>> dotfiles >>>"
END="# <<< dotfiles <<<"
KEEP_BACKUPS=3
MODE=link
PENDING=0

usage() {
  cat <<'USAGE'
usage: ./link.sh [--check | --uninstall]

  (none)       create the links, the ~/.zshrc block and the git hooks
  --check      show what would change and exit 1 if anything would
  --uninstall  remove the links, the ~/.zshrc block and the git hooks
USAGE
}

case "${1:-}" in
"") ;;
--check) MODE=check ;;
--uninstall) MODE=uninstall ;;
-h | --help)
  usage
  exit 0
  ;;
*)
  usage >&2
  exit 2
  ;;
esac

say() { printf '%-8s %s\n' "$1" "$2"; }

links() {
  printf '%s\n' \
    "config/nvim|$HOME/.config/nvim" \
    "config/emacs|$HOME/.config/emacs" \
    "config/starship/starship.toml|$HOME/.config/starship.toml" \
    "config/rumdl/rumdl.toml|$HOME/.config/rumdl/rumdl.toml" \
    "config/iterm2/dracula.json|$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles-dracula.json"
}

prune_backups() {
  local dst="$1" old
  local -a all=()
  while IFS= read -r old; do all+=("$old"); done < <(ls -1d "$dst".bak.* 2>/dev/null | sort)
  local excess=$((${#all[@]} - KEEP_BACKUPS))
  local i
  for ((i = 0; i < excess; i++)); do
    rm -rf "${all[$i]}"
    say prune "${all[$i]}"
  done
}

link() {
  local src="$DOT/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say ok "$dst"
    return
  fi
  if [ "$MODE" = check ]; then
    say change "$dst would link to $src"
    PENDING=1
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

unlink_one() {
  local src="$DOT/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    rm "$dst"
    say remove "$dst"
  fi
}

strip_blocks() {
  awk '
    /^# >>> dotfiles(: [a-z]+)? >>>$/ { skip = 1; next }
    /^# <<< dotfiles(: [a-z]+)? <<<$/ { skip = 0; next }
    !skip { print }
  ' "$1" | awk '{ lines[NR] = $0 } END { n = NR; while (n > 0 && lines[n] == "") n--; for (i = 1; i <= n; i++) print lines[i] }'
}

wanted_zshrc() {
  local base
  base="$(strip_blocks "$ZSHRC")"
  if [ -n "$base" ]; then
    printf '%s\n\n' "$base"
  fi
  printf '%s\n%s\n%s\n' "$BEGIN" "[ -r \"$DOT/config/zsh/dotfiles.zsh\" ] && source \"$DOT/config/zsh/dotfiles.zsh\"" "$END"
}

zshrc() {
  [ -e "$ZSHRC" ] || : >>"$ZSHRC"
  local wanted
  if [ "$MODE" = uninstall ]; then
    wanted="$(strip_blocks "$ZSHRC")"
    [ -n "$wanted" ] && wanted="$wanted"$'\n'
  else
    wanted="$(wanted_zshrc)"$'\n'
  fi
  if printf '%s' "$wanted" | cmp -s - "$ZSHRC"; then
    say ok "$ZSHRC"
    return
  fi
  if [ "$MODE" = check ]; then
    say change "$ZSHRC would get the dotfiles block (old blocks removed)"
    PENDING=1
    return
  fi
  cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d%H%M%S)"
  prune_backups "$ZSHRC"
  printf '%s' "$wanted" >"$ZSHRC"
  if [ "$MODE" = uninstall ]; then
    say remove "dotfiles block from $ZSHRC"
  else
    say zshrc "$ZSHRC sources config/zsh/dotfiles.zsh"
  fi
}

hooks() {
  [ -d "$DOT/.git" ] || return 0
  local current
  current="$(git -C "$DOT" config --get core.hooksPath || true)"
  case "$MODE" in
  uninstall)
    if [ "$current" = .githooks ]; then
      git -C "$DOT" config --unset core.hooksPath
      say remove "git hooks"
    fi
    ;;
  check)
    if [ "$current" = .githooks ]; then say ok "git hooks"; else
      say change "git would use .githooks"
      PENDING=1
    fi
    ;;
  *)
    if [ "$current" = .githooks ]; then say ok "git hooks"; else
      git -C "$DOT" config core.hooksPath .githooks
      say hooks "git uses .githooks (pre-commit runs test/run.sh static)"
    fi
    ;;
  esac
}

warn_old_emacs() {
  local old
  for old in "$HOME/.emacs" "$HOME/.emacs.el" "$HOME/.emacs.d"; do
    if [ -e "$old" ]; then
      say WARN "$old exists: Emacs loads it instead of ~/.config/emacs (move it away)"
    fi
  done
}

while IFS='|' read -r src dst; do
  if [ "$MODE" = uninstall ]; then unlink_one "$src" "$dst"; else link "$src" "$dst"; fi
done < <(links)
zshrc
hooks
[ "$MODE" = uninstall ] || warn_old_emacs

case "$MODE" in
check)
  if [ "$PENDING" -eq 0 ]; then echo "Nothing to change."; else echo "Run ./link.sh to apply."; fi
  exit "$PENDING"
  ;;
uninstall) echo "Removed. Backups (*.bak.*) were left in place." ;;
*) echo "Done. Open a new terminal. In iTerm2: Settings > Profiles > 'Dotfiles (Dracula)' > Other Actions > Set as Default." ;;
esac
