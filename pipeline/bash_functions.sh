source "$SCRIPT_DIR/observability.sh" || {
    error "Failed to load bash functions from $SCRIPT_DIR/observability.sh"
    exit 1
}

# ============================================================================
# Core functions
# ============================================================================
create_symlink() {
    source_file="$1"
    target_link="$2"

    if [ ! -e "$source_file" ]; then
        echo "Error: Source file '$source_file' does not exist" >&2
        return 1
    fi

    # Check if symlink already exists and points to correct target
    if [ -L "$target_link" ] && [ "$(readlink "$target_link")" = "$source_file" ]; then
        echo "Symlink already exists and is correct: $target_link -> $source_file"
        return 0
    fi

    # Handle existing targets that need to be replaced
    if [ -L "$target_link" ] || [ -f "$target_link" ]; then
        echo "Removing existing target: $target_link"
        rm -v "$target_link"
    elif [ -d "$target_link" ]; then
        echo "Warning: Target '$target_link' is a directory, skipping" >&2
        return 1
    fi

    # Ensure target directory exists
    mkdir -p "$(dirname "$target_link")"

    if ln -s "$source_file" "$target_link"; then
        echo "Created symlink: $target_link -> $source_file"
        ls -l "$target_link" 
    else
        echo "Error: Failed to create symlink '$target_link'" >&2
        return 1
    fi
}

create_directory_symlink() {
    source_dir="$1"
    target_dir="$2"
    
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory '$source_dir' does not exist" >&2
        return 1
    fi
    
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
    cp "$target_file" "$target_file.bak"

    # Ensure file ends with newline
    if [[ -n "$(tail -c1 "$target_file")" ]]; then
        echo "" >> "$target_file"
    fi

    # Append the text
    echo "$append_text" >> "$target_file"
    
    # Add blank line after appended text
    echo "" >> "$target_file"
    
    echo "Appended text to '$target_file' (backup saved as '$target_file.bak')"
}

# ============================================================================
# Enxtended behavior
# ============================================================================
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