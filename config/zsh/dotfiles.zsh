if (( ! $+commands[brew] )); then
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x $brew_bin ]] && eval "$($brew_bin shellenv zsh)" && break
  done
  unset brew_bin
fi
[[ -n $LANG && $LANG != (C|POSIX) && ! -d /usr/share/locale/$LANG ]] && export LANG=en_US.UTF-8
typeset -U path PATH

if [[ -z ${JAVA_HOME:-} && -x ${HOMEBREW_PREFIX:-/opt/homebrew}/opt/openjdk/bin/java ]]; then
  export JAVA_HOME="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
  path=("${HOMEBREW_PREFIX:-/opt/homebrew}/opt/openjdk/bin" $path)
fi

export EDITOR=nvim VISUAL=nvim

HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space

path_report() {
  local directory brew_prefix="${HOMEBREW_PREFIX:-}" source
  for directory in "${path[@]}"; do
    if [[ -n "$brew_prefix" && "$directory" == "$brew_prefix"/* ]]; then
      source="Homebrew"
    else
      source="system/user"
    fi
    printf '%-12s %s\n' "$source" "$directory"
  done
}

command_origin() {
  local command_name executable brew_prefix="${HOMEBREW_PREFIX:-}"
  for command_name in "$@"; do
    executable="$(whence -p "$command_name")"
    if [[ -z "$executable" ]]; then
      printf '%-12s %s (not found)\n' "missing" "$command_name"
    elif [[ -n "$brew_prefix" && "$executable" == "$brew_prefix"/* ]]; then
      printf '%-12s %s -> %s\n' "Homebrew" "$command_name" "$executable"
    else
      printf '%-12s %s -> %s\n' "system/user" "$command_name" "$executable"
    fi
  done
}

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
