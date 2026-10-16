have() { command -v "$1" >/dev/null 2>&1; }
pass() {
  printf 'pass   %s\n' "$1"
  PASSED=$((PASSED + 1))
}
fail() {
  printf 'FAIL   %s\n' "$1"
  [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/         /'
  FAILED=$((FAILED + 1))
}
skip() {
  printf 'skip   %s (%s)\n' "$1" "$2"
  SKIPPED=$((SKIPPED + 1))
}

lock_hash() { shasum "$DOT/config/nvim/lazy-lock.json" | cut -d' ' -f1; }

check() {
  local name="$1" out
  shift
  if out="$("$@" 2>&1)"; then
    pass "$name"
  else
    fail "$name" "$out"
  fi
}

check_silent() {
  local name="$1" out
  shift
  out="$("$@" 2>&1)"
  if [ -z "$out" ]; then
    pass "$name"
  else
    fail "$name" "$out"
  fi
}

lua_check() {
  check "$1" env DOT="$DOT" perl -e 'alarm 120; exec @ARGV' nvim --headless -n -i NONE \
    -c "lua local ok, e = pcall(dofile, '$DOT/tests/$2') if not ok then io.stderr:write(tostring(e)) vim.cmd('cquit 1') end"
}

tool() {
  local name="$1" tool="$2"
  shift 2
  if have "$tool"; then
    check "$name" "$@"
  else
    skip "$name" "$tool not installed"
  fi
}

TMUX=(tmux -L dotfiles-nvim-test)

limit() { perl -e 'alarm 5; exec @ARGV' "$@"; }
lua_eval() { limit nvim --server "$SOCK" --remote-expr "luaeval('$1')" 2>/dev/null; }
send() { limit nvim --server "$SOCK" --remote-send "$1" >/dev/null 2>&1; }
keys() { "${TMUX[@]}" send-keys "$@"; }

wait_for() {
  local expr="$1" want="$2" tries=$(($3 * 2)) got=""
  while [ "$tries" -gt 0 ]; do
    got="$(lua_eval "$expr")"
    [ "$got" = "$want" ] && return 0
    sleep 0.5
    tries=$((tries - 1))
  done
  LAST="$got"
  return 1
}

probe() {
  local name="$1" expr="$2" want="$3" seconds="${4:-10}"
  if wait_for "$expr" "$want" "$seconds"; then
    pass "$name"
  else
    fail "$name" "wanted '$want', got '$LAST'"
  fi
}

start_nvim() {
  stop_nvim
  "${TMUX[@]}" new-session -d -x 200 -y 50 -c "$1" "env TERM=xterm-256color nvim -n -i NONE --cmd 'let g:vimtex_view_automatic = 0' --cmd 'autocmd User VimtexEventCompileSuccess let g:test_compiled = 1' --cmd 'autocmd User VimtexEventView let g:test_viewed = 1' --listen '$SOCK' '$2'"
  wait_for 'vim.v.vim_did_enter' 1 20
}

stop_nvim() {
  "${TMUX[@]}" kill-server 2>/dev/null
  rm -f "$SOCK"
}

clients() { echo "#vim.lsp.get_clients({name=\"$1\"})"; }
mason() { [ -x "$XDG_DATA_HOME/nvim/mason/bin/$1" ]; }

setup() {
  local real_home="$HOME"
  if [ "$MODE" = fresh ]; then
    T="$(mktemp -d)"
  else
    T="${XDG_CACHE_HOME:-$real_home/.cache}/dotfiles-nvim-test"
    mkdir -p "$T"
  fi
  have brew && export HOMEBREW_CACHE="$(brew --cache)"
  export HOME="$T/home" XDG_DATA_HOME="$T/data" XDG_STATE_HOME="$T/state" XDG_CACHE_HOME="$T/cache"
  export PATH="$PATH:/Library/TeX/texbin"
  mkdir -p "$HOME"
  SOCK="$T/nvim.sock"
  PROJ="$T/proj"
  mkdir -p "$PROJ" "$T/tcc"
  trap cleanup EXIT
}

cleanup() {
  stop_nvim
  if [ "$MODE" = fresh ] && [ -n "${T:-}" ] && [ -d "$T" ]; then
    rm -rf "$T"
  fi
}

install() {
  local before
  before="$(lock_hash)"
  if "$DOT/install.sh" nvim >"$T/install.log" 2>&1; then
    pass "install.sh nvim in an empty home"
  else
    fail "install.sh nvim in an empty home" "$(tail -n 15 "$T/install.log")"
  fi
  if [ "$before" = "$(lock_hash)" ]; then
    pass "a fresh install leaves lazy-lock.json alone"
  else
    fail "a fresh install leaves lazy-lock.json alone" "the lockfile changed"
  fi
}

screen_has() {
  local tries=10
  while [ "$tries" -gt 0 ]; do
    "${TMUX[@]}" capture-pane -p | grep -q "$1" && return 0
    sleep 0.5
    tries=$((tries - 1))
  done
  return 1
}

menu_shows() {
  local label="$1" text="$2"
  keys ,
  if screen_has "$text"; then
    pass "$label"
  else
    fail "$label" "$("${TMUX[@]}" capture-pane -p | tail -n 12)"
  fi
  keys Escape
}
