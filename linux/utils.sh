# Aliases
alias dotterm='cd $HOME/dotfiles/terminal && nvim .'

alias ll="eza -la"
alias la="eza -a"
alias ls="eza"
alias cat="bat"
alias grep="rg" 

# Exports
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.2.0/bin:$PATH"

# Sources
source $HOME/dotfiles/shared/terminal_functions.sh
source $HOME/dotfiles/shared/exports.sh

# Cosmetics
eval "$(starship init bash)"
fastfetch
