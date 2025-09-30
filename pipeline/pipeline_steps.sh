#!/usr/bin/env bash
set -euo pipefail

load_or_exit() {
    local file=$1 desc=$2
    if ! source "$file"; then
        echo "❌ Failed to load $desc ($file)" >&2
        exit 1
    fi
}

# Load required helpers
load_or_exit "$HOME/dotfiles/pipeline/bash_functions.sh" "bash functions"
load_or_exit "$HOME/dotfiles/pipeline/observability.sh" "observability"

check_dependencies() {
    local missing=()
    for dep in git wget sed; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

setup_emacs() {
    log "▶ Doom Emacs setup"

    # Clone Doom only if not present
    if [ ! -d "$HOME/.config/emacs" ]; then
        clone_repo_with_options \
            "https://github.com/doomemacs/doomemacs" \
            "$HOME/.config/emacs" \
            "Doom Emacs" \
            --depth 1 --single-branch || return 1
    fi

    [ -x "$HOME/.config/emacs/bin/doom" ] || {
        error "Doom binary missing"
        return 1
    }

    # Install Doom only once
    if [ ! -f "$HOME/.config/doom/init.el" ]; then
        "$HOME/.config/emacs/bin/doom" install
    fi

    ensure_directory "$HOME/.config/doom" "Doom config directory"

    setup_config_file "$HOME/dotfiles/config/doom/init.el" \
                      "$HOME/.config/doom/init.el" "Symlink init.el" false

    load_config_into_file "$HOME/.config/doom/config.el" \
                          "$HOME/dotfiles/config/doom/config.el" "Configuring config.el"

    load_config_into_file "$HOME/.config/doom/packages.el" \
                          "$HOME/dotfiles/config/doom/packages.el" "Configuring packages.el"

    "$HOME/.config/emacs/bin/doom" upgrade
    "$HOME/.config/emacs/bin/doom" build
    "$HOME/.config/emacs/bin/doom" sync

    success "✔ Doom Emacs ready"
}

setup_oh_my_zsh() {
    log "▶ Oh My ZSH setup"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        download_and_execute_script \
            "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" \
            "Installing Oh My ZSH" --unattended
    fi

    ensure_file "$HOME/.zshrc" \
                "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" ".zshrc configuration"

    # Idempotent theme change
    if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
        sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$HOME/.zshrc"
    else
        echo 'ZSH_THEME="agnoster"' >>"$HOME/.zshrc"
    fi

    success "✔ Oh My ZSH ready (theme=agnoster)"
}

setup_terminal_customization() {
    log "▶ Terminal customization"

    local utils="$HOME/dotfiles/terminal/utils.sh"
    if [ -f "$utils" ]; then
        if ! grep -Fxq "source $utils" "$HOME/.zshrc"; then
            echo "source $utils" >>"$HOME/.zshrc"
            success "Utils sourced in .zshrc"
        else
            log "Utils already sourced"
        fi
    else
        warning "Utils script not found at $utils"
    fi

    setup_config_file "$HOME/dotfiles/config/alacritty/alacritty.toml" \
                      "$HOME/.config/alacritty/alacritty.toml" \
                      "Alacritty config"

    clone_or_update_repo \
        "https://github.com/alacritty/alacritty-theme" \
        "$HOME/.config/alacritty/themes" \
        "Alacritty themes"

    success "✔ Terminal ready"
}
