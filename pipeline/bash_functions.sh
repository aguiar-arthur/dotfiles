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