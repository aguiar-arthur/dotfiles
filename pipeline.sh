#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="$HOME/.dotfiles-setup.log"

load_or_exit() {
    local file=$1 desc=$2
    if ! source "$file"; then
        echo "❌ Failed to load $desc ($file)" >&2
        exit 1
    fi
}

# Load step definitions and observability helpers
load_or_exit "$HOME/dotfiles/pipeline/pipeline_steps.sh" "pipeline steps"
load_or_exit "$HOME/dotfiles/pipeline/observability.sh" "observability"

main() {
    log "▶ Starting dotfiles setup pipeline"
    check_dependencies

    local failed_steps=()
    local steps=("$@")

    # If no arguments given, run all
    if [ ${#steps[@]} -eq 0 ]; then
        steps=("emacs" "oh-my-zsh" "terminal")
    fi

    for step in "${steps[@]}"; do
        case $step in
            emacs)
                setup_emacs || failed_steps+=("emacs")
                ;;
            oh-my-zsh|zsh)
                setup_oh_my_zsh || failed_steps+=("oh-my-zsh")
                ;;
            terminal|terminal-customization)
                setup_terminal_customization || failed_steps+=("terminal-customization")
                ;;
            all)
                setup_emacs || failed_steps+=("emacs")
                setup_oh_my_zsh || failed_steps+=("oh-my-zsh")
                setup_terminal_customization || failed_steps+=("terminal-customization")
                ;;
            *)
                warning "Unknown step: $step"
                ;;
        esac
    done

    echo
    if [ ${#failed_steps[@]} -eq 0 ]; then
        success "✔ All requested setup steps completed"
        log "Pipeline finished at $(date)"
        echo
        echo "1. Restart your terminal or run: source ~/.zshrc"
        echo "2. Check logs at: $LOG_FILE"
    else
        error "❌ Failed steps: ${failed_steps[*]}"
        error "Check logs at: $LOG_FILE"
        exit 1
    fi
}

main "$@"
