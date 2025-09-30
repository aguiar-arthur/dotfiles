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

# List available setup steps (all functions starting with setup_)
available_steps() {
    declare -F | awk '{print $3}' | grep '^setup_' | sed 's/^setup_//'
}

main() {
    log "▶ Starting dotfiles setup pipeline"
    check_dependencies

    local failed_steps=()
    local steps=("$@")

    # If no arguments given, run all
    if [ ${#steps[@]} -eq 0 ]; then
        steps=("all")
    fi

    for step in "${steps[@]}"; do
        if [[ "$step" == "all" ]]; then
            for fn in $(available_steps); do
                if ! "setup_$fn"; then
                    failed_steps+=("$fn")
                fi
            done
        else
            if declare -f "setup_$step" >/dev/null 2>&1; then
                if ! "setup_$step"; then
                    failed_steps+=("$step")
                fi
            else
                warning "Unknown step: $step"
                echo "Available steps: $(available_steps | xargs)"
            fi
        fi
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
