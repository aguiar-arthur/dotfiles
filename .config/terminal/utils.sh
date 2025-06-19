export PATH="$HOME/.config/emacs/bin:$PATH"

git-prune-deleted-branches() {
  git checkout main
  git pull
  git fetch --prune
  git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D
}
