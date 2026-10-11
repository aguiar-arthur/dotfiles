(( $+commands[brew] )) || eval "$(/opt/homebrew/bin/brew shellenv zsh 2>/dev/null)"
[[ -n $LANG && $LANG != (C|POSIX) && ! -d /usr/share/locale/$LANG ]] && export LANG=en_US.UTF-8

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
