REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE="${DOTFILES_TEST_CACHE:-$REPO/.test-cache}"
STRICT="${DOTFILES_TEST_STRICT:-0}"
FAILS=0
SKIPS=0

ok() { printf '  ok    %s\n' "$*"; }
fail() {
  printf '  FAIL  %s\n' "$*"
  FAILS=$((FAILS + 1))
}
skip() {
  printf '  skip  %s\n' "$*"
  SKIPS=$((SKIPS + 1))
}
section() { printf '\n%s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

require() {
  local tool
  for tool in "$@"; do
    if ! have "$tool"; then
      if [ "$STRICT" = 1 ]; then
        fail "$tool is not installed"
      else
        skip "$tool is not installed"
      fi
      return 1
    fi
  done
}

repo_files() {
  if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    git --no-optional-locks -C "$REPO" ls-files -co --exclude-standard
  else
    (cd "$REPO" && find . -type f -not -path './.git/*' -not -path './.test-cache/*' | sed 's|^\./||')
  fi
}

WORKS=()

cleanup() {
  local dir
  for dir in ${WORKS[@]+"${WORKS[@]}"}; do rm -rf "$dir"; done
}
trap cleanup EXIT

work_dir() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")"
  WORKS+=("$WORK")
  mkdir -p "$CACHE"
}

report() {
  local label="$1"
  printf '\n%s: %d failed, %d skipped\n' "$label" "$FAILS" "$SKIPS"
  [ "$FAILS" -eq 0 ]
}

read_results() {
  local file="$1" line
  if [ ! -s "$file" ]; then
    fail "no results were written ($file)"
    return
  fi
  while IFS= read -r line; do
    case "$line" in
    "ok "*) ok "${line#ok }" ;;
    "FAIL "*) fail "${line#FAIL }" ;;
    *) printf '        %s\n' "$line" ;;
    esac
  done <"$file"
}

nvim_env() {
  export HOME="$WORK/home"
  export XDG_CONFIG_HOME="$WORK/config"
  export XDG_DATA_HOME="$CACHE/nvim-data"
  export XDG_STATE_HOME="$WORK/state"
  export XDG_CACHE_HOME="$WORK/cache"
  mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
  cp -R "$REPO/config/nvim" "$XDG_CONFIG_HOME/nvim"
  printf 'return { spelllang = { "en_us" } }\n' >"$XDG_CONFIG_HOME/nvim/lua/config/local.lua"
}

emacs_env() {
  export HOME="$WORK/home"
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$CACHE/emacs-data"
  mkdir -p "$HOME/.config" "$XDG_DATA_HOME"
  cp -R "$REPO/config/emacs" "$HOME/.config/emacs"
}

with_timeout() {
  local seconds="$1"
  shift
  if have timeout; then
    timeout "$seconds" "$@"
  elif have gtimeout; then
    gtimeout "$seconds" "$@"
  else
    "$@"
  fi
}

read_ert() {
  local file="$1" status="$2" line name found=0
  while IFS= read -r line; do
    name="$(printf '%s' "$line" | sed -E 's/^ +(passed|FAILED|SKIPPED) +[0-9]+\/[0-9]+ +//; s/ \([0-9.]+ sec\).*//')"
    case "$line" in
    *" passed "*) ok "$name" ;;
    *" FAILED "*) fail "$name" ;;
    *" SKIPPED "*) skip "$name" ;;
    *) continue ;;
    esac
    found=1
  done < <(grep -E '^ +(passed|FAILED|SKIPPED) +[0-9]+/[0-9]+ ' "$file")
  if [ "$found" -eq 0 ]; then
    fail "emacs produced no test results"
  fi
  if [ "$status" -ne 0 ]; then
    sed -n '/^Test .* condition:/,/^   FAILED/p' "$file" | grep -v '^  [#(a-z].*(' | head -40 | sed 's/^/        /'
    tail -n 5 "$file" | sed 's/^/        /'
  fi
}

run_ert() {
  local label="$1"
  shift
  local out="$WORK/ert-$label.txt" status
  (cd "$REPO" && emacs --batch -Q "$@" -f ert-run-tests-batch-and-exit) >"$out" 2>&1
  status=$?
  read_ert "$out" "$status"
}

run_nvim_lua() {
  local script="$1"
  export TEST_ROOT="$REPO" TEST_OUT="$WORK/nvim-out.txt"
  rm -f "$TEST_OUT"
  with_timeout 180 nvim --headless --cmd 'let g:loaded_spellfile_plugin=1' "+luafile $script" >"$WORK/nvim-stdout.txt" 2>&1
  read_results "$TEST_OUT"
}

sample_repo() {
  local dir="$1"
  mkdir -p "$dir"
  (
    cd "$dir" &&
      git init -q &&
      git config user.email test@example.com &&
      git config user.name test &&
      printf 'local a = 1\n' >a.lua &&
      git add a.lua &&
      git commit -qm initial &&
      printf 'local b = 2\n' >>a.lua
  )
}
