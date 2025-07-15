source "$HOME/dotfiles/pipeline/observability.sh" || {
    error "Failed to load bash functions from $HOME/dotfiles/pipeline/observability.sh"
    exit 1
}

# ============================================================================
# Core functions
# ============================================================================
create_symlink() {
    local source_file="$1"
    local target_link="$2"

    # Handle tilde expansion for both source and target
    source_file="${source_file/#\~/$HOME}"
    target_link="${target_link/#\~/$HOME}"

    if [ ! -e "$source_file" ]; then
        echo "Error: Source file '$source_file' does not exist" >&2
        return 1
    fi

    # Get absolute path for source to ensure symlink works from any location
    source_file="$(realpath "$source_file")"

    # Check if symlink already exists and points to correct target
    if [ -L "$target_link" ] && [ "$(readlink "$target_link")" = "$source_file" ]; then
        echo "Symlink already exists and is correct: $target_link -> $source_file"
        return 0
    fi

    # Handle existing targets that need to be replaced
    if [ -L "$target_link" ] || [ -f "$target_link" ]; then
        echo "Removing existing target: $target_link"
        rm -f "$target_link"
    elif [ -d "$target_link" ]; then
        echo "Warning: Target '$target_link' is a directory, skipping" >&2
        return 1
    fi

    # Ensure target directory exists
    mkdir -p "$(dirname "$target_link")"

    if ln -s "$source_file" "$target_link"; then
        echo "Created symlink: $target_link -> $source_file"
        ls -l "$target_link" 
        return 0
    else
        echo "Error: Failed to create symlink '$target_link'" >&2
        return 1
    fi
}

create_directory_symlink() {
    local source_dir="$1"
    local target_dir="$2"
    
    # Handle tilde expansion
    source_dir="${source_dir/#\~/$HOME}"
    target_dir="${target_dir/#\~/$HOME}"
    
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory '$source_dir' does not exist" >&2
        return 1
    fi
    
    # Get absolute path for source
    source_dir="$(realpath "$source_dir")"
    
    # Check if directory symlink already exists and points to correct target
    if [ -L "$target_dir" ] && [ "$(readlink "$target_dir")" = "$source_dir" ]; then
        echo "Directory symlink already exists and is correct: $target_dir -> $source_dir"
        return 0
    fi
    
    # Remove existing target only if it's not what we want
    if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
        echo "Removing existing target: $target_dir"
        rm -rf "$target_dir"
    fi
    
    # Ensure parent directory exists
    mkdir -p "$(dirname "$target_dir")"
    
    # Create the directory symlink
    if ln -s "$source_dir" "$target_dir"; then
        echo "Created directory symlink: $target_dir -> $source_dir"
        ls -ld "$target_dir"
        return 0
    else
        echo "Error: Failed to create directory symlink '$target_dir'" >&2
        return 1
    fi
}

append_text_to_file() {
    local target_file="$1"
    local append_text="$2"

    # Handle tilde expansion
    target_file="${target_file/#\~/$HOME}"

    if [[ ! -f "$target_file" ]]; then
        echo "Error: File '$target_file' does not exist." >&2
        return 1
    fi

    # Check if text already exists in file (idempotent check)
    if grep -Fxq "$append_text" "$target_file"; then
        echo "Text already exists in '$target_file', no changes needed"
        return 0
    fi

    # Create backup only if we're going to make changes
    if ! cp "$target_file" "$target_file.bak"; then
        echo "Error: Failed to create backup of '$target_file'" >&2
        return 1
    fi

    # Ensure file ends with newline
    if [[ -n "$(tail -c1 "$target_file")" ]]; then
        echo "" >> "$target_file"
    fi

    # Append the text
    if ! echo "$append_text" >> "$target_file"; then
        echo "Error: Failed to append text to '$target_file'" >&2
        return 1
    fi
    
    # Add blank line after appended text
    echo "" >> "$target_file"
    
    echo "Appended text to '$target_file' (backup saved as '$target_file.bak')"
    return 0
}

# ============================================================================
# Extended behavior
# ============================================================================
clone_or_update_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name="${3:-$(basename "$repo_url" .git)}"
    
    # Handle tilde expansion
    target_dir="${target_dir/#\~/$HOME}"
    
    if [ ! -d "$target_dir/.git" ]; then
        log "Cloning $repo_name repository"
        # Ensure parent directory exists
        mkdir -p "$(dirname "$target_dir")"
        if git clone "$repo_url" "$target_dir"; then
            success "$repo_name cloned successfully"
            return 0
        else
            error "Failed to clone $repo_name"
            return 1
        fi
    else
        log "$repo_name already exists, updating..."
        # Check if directory is a git repository and has remote
        if (cd "$target_dir" && git remote -v &>/dev/null && git pull); then
            success "$repo_name updated successfully"
            return 0
        else
            warning "Failed to update $repo_name (not a git repo or no remote configured)"
            return 1
        fi
    fi
}

clone_repo_with_options() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name="$3"
    shift 3
    local git_options=("$@")
    
    # Handle tilde expansion
    target_dir="${target_dir/#\~/$HOME}"
    
    if [ ! -d "$target_dir" ]; then
        log "Cloning $repo_name with options: ${git_options[*]}"
        # Ensure parent directory exists
        mkdir -p "$(dirname "$target_dir")"
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

execute_if_dir_exists() {
    local dir="$1"
    local description="$2"
    shift 2
    local command=("$@")
    
    # Handle tilde expansion
    dir="${dir/#\~/$HOME}"
    
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

download_and_execute_script() {
    local script_url="$1"
    local description="$2"
    shift 2
    local script_options=("$@")
    
    log "$description"
    # Add error handling for wget
    if command -v wget &> /dev/null; then
        if sh -c "$(wget -O- "$script_url")" "" "${script_options[@]}"; then
            success "$description completed successfully"
            return 0
        else
            error "Failed: $description"
            return 1
        fi
    elif command -v curl &> /dev/null; then
        if sh -c "$(curl -fsSL "$script_url")" "" "${script_options[@]}"; then
            success "$description completed successfully"
            return 0
        else
            error "Failed: $description"
            return 1
        fi
    else
        error "Neither wget nor curl is available for downloading script"
        return 1
    fi
}

ensure_directory() {
    local dir="$1"
    local description="${2:-$dir}"
    
    # Handle tilde expansion
    dir="${dir/#\~/$HOME}"
    
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

ensure_file() {
    local file="$1"
    local template_file="${2:-}"
    local description="${3:-$file}"
    
    # Handle tilde expansion
    file="${file/#\~/$HOME}"
    if [ -n "$template_file" ]; then
        template_file="${template_file/#\~/$HOME}"
    fi
    
    if [ ! -f "$file" ]; then
        log "Creating file: $description"
        # Ensure parent directory exists
        mkdir -p "$(dirname "$file")"
        
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

load_config_into_file() {
    local target_file="$1"
    local config_file="$2"
    local description="$3"
    
    # Handle tilde expansion
    target_file="${target_file/#\~/$HOME}"
    config_file="${config_file/#\~/$HOME}"
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        error "Config file does not exist: $config_file"
        return 1
    fi
    
    local load_text="(load! \"$config_file\")"
    
    if ! ensure_file "$target_file"; then
        return 1
    fi
    
    log "$description"
    if append_text_to_file "$target_file" "$load_text"; then
        success "$description completed successfully"
        return 0
    else
        error "Failed: $description"
        return 1
    fi
}

setup_config_file() {
    local source_file="$1"
    local target_file="$2"
    local description="$3"
    local create_parent_dir="${4:-true}"
    
    # Handle tilde expansion
    source_file="${source_file/#\~/$HOME}"
    target_file="${target_file/#\~/$HOME}"
    
    if [ ! -f "$source_file" ]; then
        warning "Source file not found: $source_file"
        return 1
    fi
    
    if [ "$create_parent_dir" = "true" ]; then
        local parent_dir="$(dirname "$target_file")"
        if ! ensure_directory "$parent_dir"; then
            return 1
        fi
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