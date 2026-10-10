#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
usage: test/run.sh [static|scripts|smoke|keys|behavior|all] [--clean]

  static    formatting, syntax, lint, secrets, no comments in code
  scripts   install.sh, link.sh, bin/dotfiles and the git hook in a throwaway HOME
  smoke     Neovim and Emacs start from scratch without errors
  keys      real leader maps against docs/keymaps.md
  behavior  the invariants listed in AGENTS.md
  all       everything above (default)

  --clean   delete the cache of plugins and packages first

environment:
  DOTFILES_TEST_STRICT=1   a missing tool is a failure, not a skip
  DOTFILES_TEST_CACHE=DIR  where plugins and packages are kept between runs
USAGE
}

levels=()
clean=0
for arg in "$@"; do
  case "$arg" in
  static | scripts | smoke | keys | behavior | all) levels+=("$arg") ;;
  --clean) clean=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
  esac
done
[ "${#levels[@]}" -eq 0 ] && levels=(all)

if [ "$clean" -eq 1 ]; then
  rm -rf "${DOTFILES_TEST_CACHE:-$HERE/../.test-cache}"
fi

status=0
for level in "${levels[@]}"; do
  if [ "$level" = all ]; then
    selected=(static scripts smoke keys behavior)
  else
    selected=("$level")
  fi
  for item in "${selected[@]}"; do
    bash "$HERE/$item.sh" || status=1
  done
done

if [ "$status" -eq 0 ]; then
  printf '\nall checks passed\n'
else
  printf '\nsome checks failed\n'
fi
exit "$status"
