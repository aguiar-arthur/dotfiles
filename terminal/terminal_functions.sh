git-prune-deleted-branches() {
  git checkout main
  git pull
  git fetch --prune
  git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D
}

list_files_without_word() {
    local search_word="$1"

    if [ -z "$search_word" ]; then
        echo "Usage: list_files_without_word <word>"
        return 1
    fi

    rg --files | while read -r file; do
        if ! rg -q "$search_word" "$file"; then
            echo "$file"
        fi
    done
}

list_files_with_word() {
    local search_word="$1"

    if [ -z "$search_word" ]; then
        echo "Usage: list_files_with_word <word>"
        return 1
    fi

    rg --files | while read -r file; do
        if rg -q "$search_word" "$file"; then
            echo "$file"
        fi
    done
}