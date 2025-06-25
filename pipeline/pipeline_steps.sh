SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/dotfiles"

source "$SCRIPT_DIR/bash_functions.sh" || {
    error "Failed to load bash functions from $SCRIPT_DIR/bash_functions.sh"
    exit 1
}

source "$SCRIPT_DIR/observability.sh" || {
    error "Failed to load bash functions from $SCRIPT_DIR/observability.sh"
    exit 1
}

check_dependencies() {
    local deps=("git" "wget" "sed")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        error "Please install the missing dependencies and try again"
        exit 1
    fi
}

setup_emacs() {
    log "Starting emacs setup"
    
    # 1. Clone Doom Emacs
    if ! clone_repo_with_options \
        "https://github.com/doomemacs/doomemacs" \
        "$HOME/.config/emacs" \
        "Doom Emacs" \
        --depth 1 --single-branch; then
        return 1
    fi
    
    # Install Doom Emacs if we just cloned it
    if [ ! -f "$HOME/.config/emacs/bin/doom" ]; then
        error "Doom binary not found after cloning"
        return 1
    fi
    
    # Only install if directory was just created
    if [ ! -f "$HOME/.doom.d/init.el" ] && [ ! -f "$HOME/.config/doom/init.el" ]; then
        if ! execute_if_dir_exists \
            "$HOME/.config/emacs" \
            "Installing Doom Emacs" \
            "$HOME/.config/emacs/bin/doom" install; then
            return 1
        fi
    fi
    
    # 2. Ensure doom config directory
    ensure_directory "$HOME/.config/doom" "Doom config directory"
    
    # 3. Setup configuration files
    if ! setup_config_file \
        "$DOTFILES_DIR/config/doom/init.el" \
        "$HOME/.config/doom/init.el" \
        "Creating symlink for init.el" \
        false; then
        return 1
    fi
    
    if ! load_config_into_file \
        "$HOME/.config/doom/config.el" \
        "$DOTFILES_DIR/config/doom/config.el" \
        "Configuring config.el"; then
        return 1
    fi
    
    if ! load_config_into_file \
        "$HOME/.config/doom/packages.el" \
        "$DOTFILES_DIR/config/doom/packages.el" \
        "Configuring packages.el"; then
        return 1
    fi
    
    # 4. Run doom sync
    if ! execute_if_dir_exists \
        "$HOME/.config/emacs" \
        "Running doom sync" \
        "$HOME/.config/emacs/bin/doom" sync; then
        return 1
    fi
    
    success "Emacs setup completed"
}

setup_oh_my_zsh() {
    log "Starting Oh My ZSH setup"
    
    # Install Oh My ZSH if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        if ! download_and_execute_script \
            "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" \
            "Installing Oh My ZSH" \
            --unattended; then
            return 1
        fi
    else
        log "Oh My ZSH already installed, skipping installation"
    fi
    
    # Ensure .zshrc exists
    ensure_file "$HOME/.zshrc" "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" ".zshrc configuration"
    
    # Configure theme
    if ! replace_text_in_file \
        "$HOME/.zshrc" \
        "^ZSH_THEME=.*" \
        "ZSH_THEME=\"agnoster\"" \
        "Configuring zsh theme to agnoster"; then
        return 1
    fi
    
    log "Note: Please restart your terminal or run 'source ~/.zshrc' to apply theme changes"
    success "Oh My ZSH setup completed"
}

setup_terminal_customization() {
    log "Starting terminal customization setup"
    
    # Add utils shell commands
    local utils_source="source $DOTFILES_DIR/terminal/utils.sh"
    if [ -f "$DOTFILES_DIR/terminal/utils.sh" ]; then
        if append_text_to_file "$HOME/.zshrc" "$utils_source"; then
            success "Utils shell commands added successfully"
        else
            error "Failed to add utils shell commands"
            return 1
        fi
    else
        warning "Utils script not found at $DOTFILES_DIR/terminal/utils.sh"
    fi
    
    # Setup alacritty configuration
    if ! setup_config_file \
        "$DOTFILES_DIR/config/alacritty/alacritty.toml" \
        "$HOME/.config/alacritty/alacritty.toml" \
        "Setting up alacritty configuration"; then
        warning "Alacritty configuration setup failed or file not found"
    fi
    
    # Setup alacritty themes
    if ! clone_or_update_repo \
        "https://github.com/alacritty/alacritty-theme" \
        "$HOME/.config/alacritty/themes" \
        "Alacritty themes"; then
        warning "Failed to setup alacritty themes"
    fi
    
    success "Terminal customization setup completed"
}