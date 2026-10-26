DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEEP_BACKUPS=3

title() { printf '\n== %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
say() { printf '%-8s %s\n' "$1" "$2"; }

load_brew() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$candidate" ] && eval "$("$candidate" shellenv)" && return
  done
}

trust_taps() {
  local kind name
  while read -r kind name; do
    brew trust "--$kind" "$name" >/dev/null || return 1
  done < <(sed -nE 's#^(brew|cask) "([^"/]+/[^"/]+/[^"/]+)".*#\1 \2#p' "$1" |
    sed 's/^brew /formula /' | sort -u)
}

step_brew() {
  title "Homebrew and programs"
  have brew || load_brew
  if ! have brew; then
    echo "Installing Homebrew (it asks for your password)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
    load_brew
  fi
  trust_taps "$HERE/Brewfile" || return 1
  brew bundle --no-upgrade --file "$HERE/Brewfile"
}

step_link() {
  title "Links and app preferences"
  "$HERE/link.sh"
}

run_steps() {
  local step
  local -a failed=()
  for step in "$@"; do
    "step_$step" || failed+=("$step")
  done
  if [ "${#failed[@]}" -gt 0 ]; then
    printf '\nFailed: %s. Fix the errors above and run %s again.\n' "${failed[*]}" "${0#"$DOT/"}"
    return 1
  fi
  printf '\nDone: %s.\n' "$(basename "$HERE")"
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

pref_bool() {
  local domain="$1" key="$2"
  local current
  if current="$(defaults read "$domain" "$key" 2>/dev/null)" && [ "$current" = 1 ]; then
    say ok "$domain $key"
  else
    defaults write "$domain" "$key" -bool true
    say set "$domain $key"
  fi
}
