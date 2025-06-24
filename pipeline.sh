#!/bin/sh

source ./pipeline/bash_functions.sh || {
    echo "Error: Failed to load bash functions"
    exit 1
}

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
echo "Starting Oh my ZSH setup"

echo "1 - Installing Oh my ZSH"
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

echo "2 - Changing zsh theme to agnoster"
sed -i -e 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' $HOME/.zshrc && source $HOME/.zshrc

echo "Oh my ZSH setup finished"
# end terminal

# terminal customization
echo "Starting terminal customization setup" 

echo "1 - Adding utils shell commands to the terminal source"
ZSHRC_FILE="$HOME/.zshrc"
ZSHRC_FILE_TEXT_TO_APPEND="source $HOME/dotfiles/terminal/utils.sh"
append_text_to_file "$ZSHRC_FILE" "$ZSHRC_FILE_TEXT_TO_APPEND"

echo "2 - Creating symlink for alacritty .config"
ALACRITTY_SOURCE="$HOME/dotfiles/config/alacritty"
ALACRITTY_TARGET="$HOME/.config/alacritty"
create_directory_symlink "$ALACRITTY_SOURCE" "$ALACRITTY_TARGET"

echo "3 - Cloning theme to alacritty"
mkdir -p $HOME/.config/alacritty/themes
if [ ! -d "$HOME/.config/alacritty/themes/.git" ]; then
    git clone https://github.com/alacritty/alacritty-theme $HOME/.config/alacritty/themes
fi

echo "terminal customization setup finished"
# end terminal customization