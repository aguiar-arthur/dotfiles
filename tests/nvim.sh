#!/usr/bin/env bash
set -uo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-quick}"
PASSED=0
FAILED=0
SKIPPED=0

case "$MODE" in
quick | full | fresh) ;;
*)
  echo "usage: tests/nvim.sh [quick|full|fresh]" >&2
  exit 2
  ;;
esac

for part in lib core workspace code git markdown tex; do
  . "$DOT/tests/$part.sh"
done

skim_setup() {
  local domain=net.sourceforge.skim-app.skim skim=/Applications/Skim.app out=""
  if [ ! -d "$skim" ]; then
    skip "Skim is set up for Neovim" "Skim not installed"
    return
  fi
  [ -x "$skim/Contents/SharedSupport/displayline" ] || out="$out
displayline is missing from Skim"
  [ "$(defaults read "$domain" SKTeXEditorCommand 2>/dev/null)" = "$(command -v nvim)" ] || out="$out
SKTeXEditorCommand is not $(command -v nvim)"
  defaults read "$domain" SKTeXEditorArguments 2>/dev/null | grep -q VimtexInverseSearch || out="$out
SKTeXEditorArguments does not call VimtexInverseSearch"
  [ "$(defaults read "$domain" SKAutoReloadFileUpdate 2>/dev/null)" = 1 ] || out="$out
SKAutoReloadFileUpdate is off"
  if [ -z "$out" ]; then
    pass "Skim is set up for Neovim"
  else
    fail "Skim is set up for Neovim" "run ./link.sh:$out"
  fi
}

clock_frame() {
  local frame
  frame="$(bash "$DOT/config/nvim/dashboard/clock.sh" 1)" || return 1
  case "$frame" in *█*) ;; *) echo "no digits in the frame" && return 1 ;; esac
  case "$frame" in *"$(LC_ALL=C date +%Y)"*) ;; *) echo "no date under the digits" && return 1 ;; esac
  [ "$(printf '%s' "$frame" | wc -l)" -eq 10 ] || { echo "a frame must not end in a newline: the screen would scroll" && return 1; }
}

quick() {
  local before
  before="$(lock_hash)"
  check_silent "nvim starts without messages" nvim --headless "+qa"
  check "every Lua module loads" nvim --headless -l "$DOT/tests/modules.lua"
  check "Space c s copies the path, line:col and the code" nvim --headless -l "$DOT/tests/share.lua"
  lua_check "filetypes, format on save and the references list" files.lua
  lua_check "python, mason, spell files and the review base branch" helpers.lua
  lua_check "Space u toggles, also beside a codediff review" toggles.lua
  lua_check "]e, the TeX and Markdown keys, the preview and gq" keys.lua
  lua_check "yank highlight, focus reload, last line, q, new folders, resize" autocmds.lua
  if [ "$before" = "$(lock_hash)" ]; then
    pass "starting nvim leaves lazy-lock.json alone"
  else
    fail "starting nvim leaves lazy-lock.json alone" "the lockfile changed"
  fi
  skim_setup
  if [ "$(nvim --headless -c 'lua io.write(vim.o.spellfile)' +qa 2>&1)" -ef "$DOT/config/nvim/spell/en.utf-8.add" ]; then
    pass "zg writes to the versioned word list"
  else
    fail "zg writes to the versioned word list" "spellfile is not config/nvim/spell/en.utf-8.add"
  fi
  tool "stylua" stylua bash -c "cd '$DOT/config/nvim' && stylua --check . ../../tests"
  tool "shell syntax" bash bash -n "$DOT/install.sh" "$DOT/link.sh" "$DOT"/tests/*.sh "$DOT/config/nvim/dashboard/clock.sh"
  tool "shfmt" shfmt shfmt -d "$DOT/install.sh" "$DOT/link.sh" "$DOT"/tests/*.sh "$DOT/config/nvim/dashboard/clock.sh"
  tool "rumdl" rumdl rumdl check "$DOT" --config "$DOT/config/rumdl/rumdl.toml"
  check_silent "no comments in Lua" grep -rnE '^[[:space:]]*--' --include='*.lua' "$DOT/config/nvim" "$DOT/tests"
  check_silent "no comments in shell" grep -nE '^[[:space:]]*#([^!]|$)' "$DOT/install.sh" "$DOT/link.sh" "$DOT"/tests/*.sh "$DOT/config/nvim/dashboard/clock.sh"
  check "the dashboard clock draws its digits and date" clock_frame
}

full() {
  have tmux || {
    skip "full tests" "tmux not installed"
    return
  }
  local before
  before="$(lock_hash)"
  setup
  install
  test_look
  test_windows
  test_terminals
  test_tree_and_pickers
  test_claude
  test_claude_notices
  test_sessions
  test_lua
  test_run
  test_debug
  test_language_actions
  test_test_keys
  test_clojure
  test_review
  test_lazygit
  test_review_debug
  test_markdown
  test_notes
  test_tex
  test_snippets
  if [ "$before" = "$(lock_hash)" ]; then
    pass "the whole run leaves lazy-lock.json alone"
  else
    fail "the whole run leaves lazy-lock.json alone" "the lockfile changed"
  fi
}

quick
[ "$MODE" = quick ] || full

printf '\n%d passed, %d failed, %d skipped\n' "$PASSED" "$FAILED" "$SKIPPED"
[ "$FAILED" -eq 0 ]
