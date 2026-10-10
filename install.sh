#!/usr/bin/env bash
set -uo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GROUPS_WANTED=()
SKIP=()
FAILED=()
STEP_OK=0

usage() {
  cat <<'USAGE'
usage: ./install.sh [--with GROUP]... [--all] [--skip STEP]...

Installs what the configuration needs; ./link.sh connects it to your home directory.

  --with GROUP   also install an optional Brewfile group from brew/ (latex, clojure, python, ruby)
  --all          install every group
  --skip STEP    skip a step: brew, nvim, emacs

steps, in order:
  brew    Homebrew itself if missing, then brew bundle (Brewfile and the chosen groups)
  nvim    plugins at the versions in lazy-lock.json, Mason servers and tools, treesitter parsers
  emacs   every package the configuration uses

Every step can run again safely; it only installs what is missing.
USAGE
}

available_groups() {
  local file
  for file in "$DOT"/brew/*.Brewfile; do
    [ -e "$file" ] && basename "$file" .Brewfile
  done
}

while [ $# -gt 0 ]; do
  case "$1" in
  --with)
    [ $# -ge 2 ] || {
      usage >&2
      exit 2
    }
    if [ ! -f "$DOT/brew/$2.Brewfile" ]; then
      printf 'unknown group: %s (available: %s)\n' "$2" "$(available_groups | tr '\n' ' ')" >&2
      exit 2
    fi
    GROUPS_WANTED+=("$2")
    shift 2
    ;;
  --all)
    while IFS= read -r group; do GROUPS_WANTED+=("$group"); done < <(available_groups)
    shift
    ;;
  --skip)
    case "${2:-}" in
    brew | nvim | emacs) SKIP+=("$2") ;;
    *)
      usage >&2
      exit 2
      ;;
    esac
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
  esac
done

title() { printf '\n== %s\n' "$*"; }
skipped() { [[ " ${SKIP[*]-} " == *" $1 "* ]]; }
have() { command -v "$1" >/dev/null 2>&1; }
failed() {
  STEP_OK=1
  printf 'ERROR  %s\n' "$1"
}

step_brew() {
  title "Homebrew and programs"
  if ! have brew; then
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      [ -x "$candidate" ] && eval "$("$candidate" shellenv)" && break
    done
  fi
  if ! have brew; then
    if [[ "$OSTYPE" != darwin* ]]; then
      failed "Homebrew is not installed; see https://brew.sh"
      return
    fi
    echo "Installing Homebrew (it asks for your password)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      failed "Homebrew installation"
      return
    }
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [ -x "$candidate" ] && eval "$("$candidate" shellenv)" && break
    done
  fi
  brew bundle --file "$DOT/Brewfile" || failed "brew bundle (Brewfile)"
  local group
  for group in "${GROUPS_WANTED[@]+"${GROUPS_WANTED[@]}"}"; do
    brew bundle --file "$DOT/brew/$group.Brewfile" || failed "brew bundle (brew/$group.Brewfile)"
  done
}

step_nvim() {
  title "Neovim: plugins, Mason servers and tools, treesitter parsers"
  if ! have nvim; then
    failed "nvim is not installed (run the brew step first)"
    return 1
  fi
  export XDG_CONFIG_HOME="$DOT/config"
  if nvim --headless "+Lazy! restore" +qa; then
    echo "ok     plugins at the versions in lazy-lock.json"
  else
    failed "Lazy! restore"
    return 1
  fi
  nvim --headless "+lua require('dotfiles.install').run()" || failed "Neovim tools or parsers"
  return "$STEP_OK"
}

step_emacs() {
  title "Emacs: packages"
  if ! have emacs; then
    failed "emacs is not installed (run the brew step first)"
    return 1
  fi
  export XDG_CONFIG_HOME="$DOT/config"
  if emacs --batch -l "$DOT/config/emacs/early-init.el" -l "$DOT/config/emacs/init.el" \
    --eval '(kill-emacs (if aa/failed-modules 1 0))'; then
    echo "ok     every package installed and every module loads"
  else
    failed "Emacs packages (a module failed to load; see the output above)"
  fi
  return "$STEP_OK"
}

run_step() {
  local step="$1"
  skipped "$step" && return
  STEP_OK=0
  if [ "$step" = brew ]; then
    step_brew
  else
    ("step_$step")
    STEP_OK=$?
  fi
  [ "$STEP_OK" -eq 0 ] || FAILED+=("$step")
}

run_step brew
run_step nvim
run_step emacs

if [ "${#FAILED[@]}" -gt 0 ]; then
  printf '\nSome steps failed: %s\n' "${FAILED[*]}"
  exit 1
fi
printf '\nInstalled. Next: ./link.sh, then open a new terminal and run dotfiles doctor.\n'
