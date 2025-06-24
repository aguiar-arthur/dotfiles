#!/bin/bash

# Dotfiles Setup Pipeline
# This script sets up emacs, terminal, and various configurations

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/dotfiles"
LOG_FILE="$HOME/.dotfiles-setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Load bash functions
source "$SCRIPT_DIR/pipeline/bash_functions.sh" || {
    error "Failed to load bash functions from $SCRIPT_DIR/pipeline/bash_functions.sh"
    exit 1
}

# Check dependencies
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

# Setup emacs configuration
setup_emacs() {
    log "Starting emacs setup"
    
    log "1 - Installing Doom Emacs"
    if [ ! -d "$HOME/.config/emacs" ]; then
        if git clone --depth 1 --single-branch https://github.com/doomemacs/doomemacs ~/.config/emacs; then
            success "Doom Emacs cloned successfully"
        else
            error "Failed to clone Doom Emacs"
            return 1
        fi
    else
        log "Doom Emacs directory already exists, skipping clone"
    fi
    
    if "$HOME/.config/emacs/bin/doom" install; then
        success "Doom Emacs installed successfully"
    else
        error "Failed to install Doom Emacs"
        return 1
    fi
    
    # Ensure doom config directory exists
    mkdir -p "$HOME/.config/doom"
    
    log "2 - Creating symlink for init.el"
    if create_symlink "$DOTFILES_DIR/config/doom/init.el" "$HOME/.config/doom/init.el"; then
        success "Emacs init.el symlink created successfully"
    else
        error "Failed to create emacs init.el symlink"
        return 1
    fi
    
    log "3 - Configuring config.el"
    local config_el="$HOME/.config/doom/config.el"
    local config_el_text="(load \"$DOTFILES_DIR/config/doom/config.el\")"
    
    # Create config.el if it doesn't exist
    [ ! -f "$config_el" ] && touch "$config_el"
    
    if append_text_to_file "$config_el" "$config_el_text"; then
        success "Emacs config.el configured successfully"
    else
        error "Failed to configure emacs config.el"
        return 1
    fi
    
    log "4 - Configuring packages.el"
    local packages_el="$HOME/.config/doom/packages.el"
    local packages_el_text="(load \"$DOTFILES_DIR/config/doom/packages.el\")"
    
    # Create packages.el if it doesn't exist
    [ ! -f "$packages_el" ] && touch "$packages_el"
    
    if append_text_to_file "$packages_el" "$packages_el_text"; then
        success "Emacs packages.el configured successfully"
    else
        error "Failed to configure emacs packages.el"
        return 1
    fi
    
    success "Emacs setup completed"
}

# Setup Oh My ZSH
setup_oh_my_zsh() {
    log "Starting Oh My ZSH setup"
    
    # Check if Oh My ZSH is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "Oh My ZSH already installed, skipping installation"
    else
        log "1 - Installing Oh My ZSH"
        # Use RUNZSH=no to prevent automatic shell switching during script
        if sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            success "Oh My ZSH installed successfully"
        else
            error "Failed to install Oh My ZSH"
            return 1
        fi
    fi
    
    # Ensure .zshrc exists
    if [ ! -f "$HOME/.zshrc" ]; then
        warning ".zshrc not found, creating basic configuration"
        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    fi
    
    log "2 - Configuring zsh theme to agnoster"
    if sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$HOME/.zshrc"; then
        success "ZSH theme configured successfully"
        log "Note: Please restart your terminal or run 'source ~/.zshrc' to apply theme changes"
    else
        error "Failed to configure zsh theme"
        return 1
    fi
    
    success "Oh My ZSH setup completed"
}

# Setup terminal customization
setup_terminal_customization() {
    log "Starting terminal customization setup"
    
    log "1 - Adding utils shell commands to zsh configuration"
    local zshrc_file="$HOME/.zshrc"
    local utils_source="source $DOTFILES_DIR/terminal/utils.sh"
    
    if [ ! -f "$DOTFILES_DIR/terminal/utils.sh" ]; then
        warning "Utils script not found at $DOTFILES_DIR/terminal/utils.sh"
    else
        if append_text_to_file "$zshrc_file" "$utils_source"; then
            success "Utils shell commands added successfully"
        else
            error "Failed to add utils shell commands"
            return 1
        fi
    fi
    
    log "2 - Creating symlink for alacritty configuration"
    local alacritty_source="$DOTFILES_DIR/config/alacritty"
    local alacritty_target="$HOME/.config/alacritty"
    
    if [ ! -d "$alacritty_source" ]; then
        warning "Alacritty config directory not found at $alacritty_source"
    else
        if create_directory_symlink "$alacritty_source" "$alacritty_target"; then
            success "Alacritty configuration symlink created successfully"
        else
            error "Failed to create alacritty configuration symlink"
            return 1
        fi
    fi
    
    log "3 - Setting up alacritty themes"
    local themes_dir="$HOME/.config/alacritty/themes"
    
    # Only proceed if alacritty config exists
    if [ -d "$HOME/.config/alacritty" ]; then
        mkdir -p "$themes_dir"
        
        if [ ! -d "$themes_dir/.git" ]; then
            log "Cloning alacritty themes repository"
            if git clone https://github.com/alacritty/alacritty-theme "$themes_dir"; then
                success "Alacritty themes cloned successfully"
            else
                error "Failed to clone alacritty themes"
                return 1
            fi
        else
            log "Alacritty themes already cloned, updating..."
            if (cd "$themes_dir" && git pull); then
                success "Alacritty themes updated successfully"
            else
                warning "Failed to update alacritty themes"
            fi
        fi
    else
        warning "Alacritty config directory not found, skipping themes setup"
    fi
    
    success "Terminal customization setup completed"
}

# Main execution
main() {
    log "Starting dotfiles setup pipeline"
    log "Dotfiles directory: $DOTFILES_DIR"
    log "Log file: $LOG_FILE"
    
    # Check dependencies first
    check_dependencies
    
    local failed_steps=()
    
    # Run setup steps
    if ! setup_emacs; then
        failed_steps+=("emacs")
    fi
    
    if ! setup_oh_my_zsh; then
        failed_steps+=("oh-my-zsh")
    fi
    
    if ! setup_terminal_customization; then
        failed_steps+=("terminal-customization")
    fi
    
    # Final report
    echo
    if [ ${#failed_steps[@]} -eq 0 ]; then
        success "All setup steps completed successfully!"
        log "Setup completed at $(date)"
        echo
        echo "1. Restart your terminal or run: source ~/.zshrc"
        echo "2. Check the log file at: $LOG_FILE"
    else
        error "Some setup steps failed: ${failed_steps[*]}"
        error "Check the log file for details: $LOG_FILE"
        exit 1
    fi
}

# Run main function
main "$@"