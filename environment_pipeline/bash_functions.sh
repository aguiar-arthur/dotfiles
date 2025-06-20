create_symlink() {
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

create_directory_symlink() {
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
            ln -s "$file" "$target_file"
        fi
    done
}

append_text_to_file() {
    local target_file="$1"
    local append_text="$2"

    target_file="${target_file/#\~/$HOME}"

    if [[ ! -f "$target_file" ]]; then
        echo "Error: File '$target_file' does not exist."
        return 1
    fi

    if grep -Fxq "$append_text" "$target_file"; then
        return 0
    fi

    if [[ -n "$(tail -c1 "$target_file")" ]]; then
        echo "" >> "$target_file"
    fi

    echo "$append_text" >> "$target_file"
}
