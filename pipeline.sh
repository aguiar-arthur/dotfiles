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

source "$SCRIPT_DIR/pipeline/bash_functions.sh" || {
    error "Failed to load bash functions from $SCRIPT_DIR/pipeline/bash_functions.sh"
    exit 1
}

# ============================================================================
# EXTRACTED REUSABLE METHODS
# ============================================================================

# Clone or update a git repository
clone_or_update_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name="${3:-$(basename "$repo_url" .git)}"
    
    if [ ! -d "$target_dir/.git" ]; then
        log "Cloning $repo_name repository"
        if git clone "$repo_url" "$target_dir"; then
            success "$repo_name cloned successfully"
            return 0
        else
            error "Failed to clone $repo_name"
            return 1
        fi
    else
        log "$repo_name already exists, updating..."
        if (cd "$target_dir" && git pull); then
            success "$repo_name updated successfully"
            return 0
        else
            warning "Failed to update $repo_name"
            return 1
        fi
    fi
}

# Clone repository with specific options (depth, branch, etc.)
clone_repo_with_options() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name="$3"
    shift 3
    local git_options=("$@")
    
    if [ ! -d "$target_dir" ]; then
        log "Cloning $repo_name with options: ${git_options[*]}"
        if git clone "${git_options[@]}" "$repo_url" "$target_dir"; then
            success "$repo_name cloned successfully"
            return 0
        else
            error "Failed to clone $repo_name"
            return 1
        fi
    else
        log "$repo_name directory already exists, skipping clone"
        return 0
    fi
}

# Execute a command if directory exists
execute_if_dir_exists() {
    local dir="$1"
    local description="$2"
    shift 2
    local command=("$@")
    
    if [ -d "$dir" ]; then
        log "Executing: $description"
        if "${command[@]}"; then
            success "$description completed successfully"
            return 0
        else
            error "Failed to execute: $description"
            return 1
        fi
    else
        error "Directory $dir does not exist, cannot execute: $description"
        return 1
    fi
}

# Download and execute script with options
download_and_execute_script() {
    local script_url="$1"
    local description="$2"
    shift 2
    local script_options=("$@")
    
    log "$description"
    if sh -c "$(wget -O- "$script_url")" "" "${script_options[@]}"; then
        success "$description completed successfully"
        return 0
    else
        error "Failed: $description"
        return 1
    fi
}

# Ensure directory exists and create if needed
ensure_directory() {
    local dir="$1"
    local description="${2:-$dir}"
    
    if [ ! -d "$dir" ]; then
        log "Creating directory: $description"
        if mkdir -p "$dir"; then
            success "Directory created: $description"
            return 0
        else
            error "Failed to create directory: $description"
            return 1
        fi
    else
        log "Directory already exists: $description"
        return 0
    fi
}

# Ensure file exists and create if needed
ensure_file() {
    local file="$1"
    local template_file="${2:-}"
    local description="${3:-$file}"
    
    if [ ! -f "$file" ]; then
        log "Creating file: $description"
        if [ -n "$template_file" ] && [ -f "$template_file" ]; then
            if cp "$template_file" "$file"; then
                success "File created from template: $description"
                return 0
            else
                error "Failed to create file from template: $description"
                return 1
            fi
        else
            if touch "$file"; then
                success "File created: $description"
                return 0
            else
                error "Failed to create file: $description"
                return 1
            fi
        fi
    else
        log "File already exists: $description"
        return 0
    fi
}

# Replace text in file using sed
replace_text_in_file() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local description="$4"
    
    log "$description"
    if sed -i.bak "s|$pattern|$replacement|" "$file"; then
        success "$description completed successfully"
        return 0
    else
        error "Failed: $description"
        return 1
    fi
}

# Load configuration into existing file
load_config_into_file() {
    local target_file="$1"
    local config_file="$2"
    local description="$3"
    
    local load_text="(load \"$config_file\")"
    
    ensure_file "$target_file"
    
    log "$description"
    if append_text_to_file "$target_file" "$load_text"; then
        success "$description completed successfully"
        return 0
    else
        error "Failed: $description"
        return 1
    fi
}

# Setup configuration with symlink or file operations
setup_config_file() {
    local source_file="$1"
    local target_file="$2"
    local description="$3"
    local create_parent_dir="${4:-true}"
    
    if [ ! -f "$source_file" ]; then
        warning "Source file not found: $source_file"
        return 1
    fi
    
    if [ "$create_parent_dir" = "true" ]; then
        local parent_dir="$(dirname "$target_file")"
        ensure_directory "$parent_dir"
    fi
    
    log "$description"
    if create_symlink "$source_file" "$target_file"; then
        success "$description completed successfully"
        return 0
    else
        error "Failed: $description"
        return 1
    fi
}

# ============================================================================
# SETUP FUNCTIONS USING EXTRACTED METHODS
# ============================================================================

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