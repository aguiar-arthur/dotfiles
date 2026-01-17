git_prune_deleted_branches() {
  git checkout main
  git pull
  git fetch --prune
  git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D
}

