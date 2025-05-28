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

create_symlink "$HOME/dotfiles/.config/doom/init.el" "$HOME/.config/doom/init.el"