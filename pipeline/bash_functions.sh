#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Load observability
# ============================================================================
load_or_exit() {
    local file=$1 desc=$2
    if ! source "$file"; then
        echo "❌ Failed to load $desc ($file)" >&2
        exit 1
    fi
}
load_or_exit "$HOME/dotfiles/pipeline/observability.sh" "observability"

# ============================================================================
# Helpers
# ============================================================================
expand_path() {
    local path="$1"
    echo "${path/#\~/$HOME}"
}

absolute_path() {
    local path
    path="$(expand_path "$1")"
    realpath "$path" 2>/dev/null || echo "$path"
}

# ============================================================================
# Core functions
# ============================================================================
create_symlink() {
    local src="$(absolute_path "$1")"
    local dst="$(absolute_path "$2")"

    if [ ! -e "$src" ]; then
        error "Source '$src' does not exist"
        return 1
    fi

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        log "Symlink already correct: $dst → $src"
        return 0
    fi

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        warning "Removing existing target: $dst"
        rm -rf "$dst"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst" && success "Symlink created: $dst → $src" || {
        error "Failed to create symlink: $dst"
        return 1
    }
}

create_directory_symlink() {
    local src="$(absolute_path "$1")"
    local dst="$(absolute_path "$2")"

    if [ ! -d "$src" ]; then
        error "Source directory '$src' does not exist"
        return 1
    fi

    create_symlink "$src" "$dst"
}

append_text_to_file() {
    local file="$(absolute_path "$1")"
    local text="$2"

    if [ ! -f "$file" ]; then
        error "File not found: $file"
        return 1
    fi

    if grep -Fxq "$text" "$file"; then
        log "Text already present in $file"
        return 0
    fi

    cp "$file" "$file.bak"
    [[ -n "$(tail -c1 "$file")" ]] && echo "" >> "$file"
    echo "$text" >> "$file" && echo "" >> "$file"
    success "Appended text to $file (backup at $file.bak)"
}

# ============================================================================
# Extended behavior
# ============================================================================
clone_or_update_repo() {
    local url="$1" dst="$(absolute_path "$2")"
    local name="${3:-$(basename "$url" .git)}"

    if [ ! -d "$dst/.git" ]; then
        log "Cloning $name into $dst"
        mkdir -p "$(dirname "$dst")"
        git clone "$url" "$dst" && success "$name cloned" || {
            error "Clone failed: $name"
            return 1
        }
    else
        log "Updating $name"
        if (cd "$dst" && git pull --ff-only); then
            success "$name updated"
        else
            warning "Failed to update $name"
            return 1
        fi
    fi
}

clone_repo_with_options() {
    local url="$1" dst="$(absolute_path "$2")" name="$3"
    shift 3; local opts=("$@")

    if [ ! -d "$dst" ]; then
        log "Cloning $name with options: ${opts[*]}"
        mkdir -p "$(dirname "$dst")"
        git clone "${opts[@]}" "$url" "$dst" && success "$name cloned" || {
            error "Clone failed: $name"
            return 1
        }
    else
        log "$name already exists, skipping"
    fi
}

execute_if_dir_exists() {
    local dir="$(absolute_path "$1")"
    local desc="$2"; shift 2
    local cmd=("$@")

    if [ -d "$dir" ]; then
        log "$desc"
        if "${cmd[@]}"; then
            success "$desc succeeded"
        else
            error "$desc failed"
            return 1
        fi
    else
        warning "Skipping $desc, directory not found: $dir"
        return 1
    fi
}

download_and_execute_script() {
    local url="$1" desc="$2"
    shift 2; local opts=("$@")

    log "$desc"
    local downloader=""
    if command -v wget &>/dev/null; then
        downloader="wget -O-"
    elif command -v curl &>/dev/null; then
        downloader="curl -fsSL"
    else
        error "No wget or curl available"
        return 1
    fi

    if sh -c "$($downloader "$url")" "" "${opts[@]}"; then
        success "$desc completed"
    else
        error "$desc failed"
        return 1
    fi
}

ensure_directory() {
    local dir="$(absolute_path "$1")" desc="${2:-$1}"
    if [ ! -d "$dir" ]; then
        log "Creating directory: $desc"
        mkdir -p "$dir" && success "Directory created: $desc" || {
            error "Failed to create: $desc"
            return 1
        }
    else
        log "Directory exists: $desc"
    fi
}

ensure_file() {
    local file="$(absolute_path "$1")"
    local template="${2:-}" desc="${3:-$file}"

    if [ ! -f "$file" ]; then
        log "Creating file: $desc"
        mkdir -p "$(dirname "$file")"
        if [ -n "$template" ] && [ -f "$template" ]; then
            cp "$template" "$file"
        else
            touch "$file"
        fi
        success "File created: $desc"
    else
        log "File exists: $desc"
    fi
}

load_config_into_file() {
    local target="$(absolute_path "$1")"
    local config="$(absolute_path "$2")"
    local desc="$3"

    if [ ! -f "$config" ]; then
        error "Config file missing: $config"
        return 1
    fi

    local load="(load! \"$config\")"
    ensure_file "$target" || return 1
    append_text_to_file "$target" "$load" && success "$desc" || {
        error "$desc failed"
        return 1
    }
}

setup_config_file() {
    local src="$(absolute_path "$1")"
    local dst="$(absolute_path "$2")"
    local desc="$3"
    local make_parent="${4:-true}"

    if [ ! -f "$src" ]; then
        warning "Source not found: $src"
        return 1
    fi

    [ "$make_parent" = "true" ] && ensure_directory "$(dirname "$dst")"
    log "$desc"
    create_symlink "$src" "$dst" && success "$desc" || {
        error "$desc failed"
        return 1
    }
}
