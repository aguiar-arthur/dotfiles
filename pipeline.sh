#!/bin/bash

# Dotfiles Setup Pipeline
# This script sets up emacs, terminal, and various configurations

set -euo pipefail  # Exit on error, undefined vars, pipe failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.dotfiles-setup.log"

source "$SCRIPT_DIR/pipeline/pipeline_steps.sh" || {
    error "Failed to load bash functions from $SCRIPT_DIR/pipeline/pipeline_steps.sh"
    exit 1
}

source "$SCRIPT_DIR/pipeline/observability.sh" || {
    error "Failed to load bash functions from $SCRIPT_DIR/pipeline/observability.sh"
    exit 1
}

# Main execution
main() {
    log "Starting dotfiles setup pipeline"
    
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