#!/bin/sh

source ./pipeline/bash_functions.sh || {
    echo "Error: Failed to load bash functions"
    exit 1
}
# nix
echo "Starting nix setup"

echo "1 - creating nix config symlink" 
create_directory_symlink "$HOME/dotfiles/config/nix" "$HOME/.config/nix"

echo "nix setup finished"
# end nix

# emacs
echo "Starting emacs setup"

echo "1 - Creating symlink for init.el"
create_symlink "$HOME/dotfiles/config/doom/init.el" "$HOME/.config/doom/init.el"

echo "2 - Appending files into config.el"
CONFIG_EL="$HOME/.config/doom/config.el"
CONFIG_EL_TEXT_TO_APPEND='(load "'"$HOME"'/dotfiles/config/doom/config.el")'
append_text_to_file "$CONFIG_EL" "$CONFIG_EL_TEXT_TO_APPEND"

echo "3 - Appending files into packages.el"
PACKAGES_EL="$HOME/.config/doom/packages.el"
PACKAGES_EL_TEXT_TO_APPEND='(load "'"$HOME"'/dotfiles/config/doom/packages.el")'
append_text_to_file "$PACKAGES_EL" "$PACKAGES_EL_TEXT_TO_APPEND"

echo "emacs setup finished"
# end emacs

# terminal
echo "Starting terminal setup"

echo "1 - Adding utils shell commands to the terminal source"
ZSHRC_FILE="$HOME/.zshrc"
ZSHRC_FILE_TEXT_TO_APPEND="source $HOME/dotfiles/config/terminal/utils.sh"
append_text_to_file "$ZSHRC_FILE" "$ZSHRC_FILE_TEXT_TO_APPEND"

echo "terminal setup finished"
# end terminal