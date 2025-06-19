#!/bin/sh

create_symlink() {
    if [ $# -ne 2 ]; then
        echo "Usage: create_symlink SOURCE_FILE TARGET_LINK" >&2
        return 1
    fi

    source_file="$1"
    target_link="$2"

    if [ ! -e "$source_file" ]; then
        echo "Error: Source file '$source_file' does not exist" >&2
        return 1
    fi

    [ -e "$target_link" ] && rm -v "$target_link"

    if ln -s "$source_file" "$target_link"; then
        ls -l "$target_link" 
    else
        echo "Error: Failed to create symlink '$target_link'" >&2
        return 1
    fi
}

create_directory_symlinks() {
    if [ $# -ne 2 ]; then
        echo "Usage: create_directory_symlinks SOURCE_DIR TARGET_DIR" >&2
        return 1
    fi

    source_dir="$1"
    target_dir="$2"

    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory '$source_dir' does not exist" >&2
        return 1
    fi

    mkdir -p "$target_dir"

    find "$source_dir" -type f -print0 | while IFS= read -r -d '' file; do
        rel_path="${file#$source_dir/}"
        target_file="$target_dir/$rel_path"

        mkdir -p "$(dirname "$target_file")"

        if [ ! -e "$target_file" ]; then
            echo "Creating symlink: $target_file -> $file"
            ln -s "$file" "$target_file"
        else
            echo "Warning: $target_file already exists, skipping"
        fi
    done
}

create_symlink "$HOME/dotfiles/.config/doom/init.el" "$HOME/.config/doom/init.el"
create_directory_symlinks "$HOME/dotfiles/.config/terminal" "$HOME/.config/terminal"