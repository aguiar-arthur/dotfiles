export DOTFILES="${${(%):-%x}:A:h:h:h}"
path=("$DOTFILES/bin" $path)

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

alias e='emacsclient -n -c -a ""'
