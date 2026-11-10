#!/usr/bin/env bash
set -uo pipefail

unset VIRTUAL_ENV
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
QUICK_STATE="$(mktemp -d)"
trap 'rm -rf "$QUICK_STATE"' EXIT
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

for part in lib core workspace code git markdown tex tmux; do
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
    fail "Skim is set up for Neovim" "run macos/nvim/link.sh:$out"
  fi
}

mason_python() {
  local broken
  broken="$(nvim --headless -c "lua local m = require('dotfiles.install.mason') local b = m.broken() io.write(table.concat(vim.tbl_filter(function(n) return b[n] end, m.wanted(require('config.settings'))), ' '))" +qa 2>&1)"
  if [ -z "$broken" ]; then
    pass "Mason's Python tools still have their Python"
  else
    fail "Mason's Python tools still have their Python" "run macos/nvim/install.sh to reinstall: $broken"
  fi
}

clock_frame() {
  local frame
  frame="$(bash "$DOT/config/nvim/dashboard/clock.sh" 1)" || return 1
  case "$frame" in *█*) ;; *) echo "no digits in the frame" && return 1 ;; esac
  case "$frame" in *"$(LC_ALL=C date +%Y)"*) ;; *) echo "no date under the digits" && return 1 ;; esac
  [ "$(printf '%s' "$frame" | wc -l)" -eq 10 ] || { echo "a frame must not end in a newline: the screen would scroll" && return 1; }
}

zsh_eza() {
  local rc="$DOT/config/zsh/dotfiles.zsh"
  zsh -f -i -c "source '$rc'; [[ \$aliases[ls] == eza* ]] && eval 'll \"$DOT/macos\"' && eval 'lt \"$DOT/macos\"'" >/dev/null || {
    echo "ls, ll or lt does not run eza in an interactive shell"
    return 1
  }
  zsh -f -c "source '$rc'; (( ! \$+aliases[ls] ))" || {
    echo "a script that sources dotfiles.zsh gets the eza alias"
    return 1
  }
}

zsh_fzf() {
  local rc="$DOT/config/zsh/dotfiles.zsh"
  zsh -f -i -c "source '$rc'; [[ \$(bindkey '^R') == *fzf-history-widget && \$(bindkey '^T') == *fzf-file-widget && \$(bindkey '\ec') == *fzf-cd-widget && \$FZF_DEFAULT_OPTS == *282a36* ]]" || {
    echo "Ctrl-r, Ctrl-t or Alt-c does not run fzf in Dracula in an interactive shell"
    return 1
  }
  zsh -f -c "source '$rc'; [[ \$(bindkey '^R') != *fzf* ]]" || {
    echo "a script that sources dotfiles.zsh gets the fzf keys"
    return 1
  }
}

zsh_completion() {
  local rc="$DOT/config/zsh/dotfiles.zsh" dir out=""
  dir="$(mktemp -d)"
  ZDOTDIR="$dir" zsh -f -i -c "source '$rc'; (( \$+_comps[git] ))" </dev/null >/dev/null 2>&1 || out="$out
an interactive shell has no git completion"
  ZDOTDIR="$dir" zsh -f -c "source '$rc'; (( ! \$+functions[compinit] ))" || out="$out
a script that sources dotfiles.zsh runs compinit"
  rm -rf "$dir"
  [ -z "$out" ] || {
    echo "${out#$'\n'}"
    return 1
  }
}

zsh_prompt_gap() {
  local rc="$DOT/config/zsh/dotfiles.zsh" got wanted prompt
  prompt="$(STARSHIP_CONFIG="$DOT/config/starship/starship.toml" starship prompt)"
  case "$prompt" in
  $'\n'*) echo "Starship still starts the prompt with a blank line" && return 1 ;;
  esac
  got="$(TERM=xterm zsh -f -c "source '$rc'; source '$rc'; prompt_gap; print first; prompt_gap; print second; clear >/dev/null; prompt_gap; print third; print -l \$precmd_functions")"
  wanted=$'first\n\nsecond\nthird\nprompt_starship_precmd\nprompt_gap'
  [ "$got" = "$wanted" ] || {
    printf 'wanted:\n%s\ngot:\n%s\n' "$wanted" "$got"
    return 1
  }
}

link_backup() {
  local dir out=""
  dir="$(mktemp -d)"
  mkdir -p "$dir/Profiles"
  echo old >"$dir/plain"
  echo old >"$dir/Profiles/profile.json"
  (
    . "$DOT/macos/lib.sh"
    link config/git/ignore "$dir/plain"
    link config/iterm2/dracula.json "$dir/Profiles/profile.json" "$dir/profile.json"
  ) >/dev/null
  [ -L "$dir/plain" ] && [ -L "$dir/Profiles/profile.json" ] || out="$out
a file in the way was not replaced by the link"
  compgen -G "$dir/plain.bak.*" >/dev/null || out="$out
a backup does not sit beside its file"
  compgen -G "$dir/profile.json.bak.*" >/dev/null && ! compgen -G "$dir/Profiles/*.bak.*" >/dev/null || out="$out
the iTerm2 profile's backup stays in the folder iTerm2 loads every file of"
  rm -rf "$dir"
  [ -z "$out" ] || {
    echo "${out#$'\n'}"
    return 1
  }
}

zsh_helpers() {
  local rc="$DOT/config/zsh/dotfiles.zsh" dir got wanted
  dir="$(mktemp -d)"
  mkdir -p "$dir/brew/bin" "$dir/bin"
  printf '#!/bin/sh\n' >"$dir/brew/bin/fake"
  printf '#!/bin/sh\n' >"$dir/bin/plain"
  chmod +x "$dir/brew/bin/fake" "$dir/bin/plain"
  got="$(zsh -f -c "source '$rc'; HOMEBREW_PREFIX='$dir/brew'; path=('$dir/brew/bin' '$dir/bin'); command_origin fake plain nowhere; path_report")"
  rm -rf "$dir"
  wanted="Homebrew     fake -> $dir/brew/bin/fake
system/user  plain -> $dir/bin/plain
missing      nowhere (not found)
Homebrew     $dir/brew/bin
system/user  $dir/bin"
  [ "$got" = "$wanted" ] || {
    printf 'wanted:\n%s\ngot:\n%s\n' "$wanted" "$got"
    return 1
  }
}

quick() {
  local before marker
  before="$(lock_hash)"
  marker="$QUICK_STATE/started"
  touch "$marker"
  export XDG_STATE_HOME="$QUICK_STATE"
  check_silent "nvim starts without messages" nvim --headless "+qa"
  lua_check "the test harness: a crash fails only its case, stubs are undone" lib_check.lua
  check "every Lua module loads" perl -e 'alarm 120; exec @ARGV' nvim --headless -l "$DOT/tests/modules.lua"
  lua_check "Space c s copies the path, line:col and the code" share.lua
  lua_check "filetypes, format on save and the references list" files.lua
  lua_check "core: startup loads only what it must, ui2 is still there, the dashboard q" core.lua
  lua_check "install: Mason lists, spell files, parsers" install.lua
  lua_check "code: python, clojure, LSP progress, debugpy" code.lua
  lua_check "workspace: the float style, Claude" workspace.lua
  lua_check "git: reviews, Space b d, log pickers, base branch" git.lua
  lua_check "Space u toggles, also beside a codediff review" toggles.lua
  lua_check "]e, the TeX and Markdown keys, the preview, gq and the gr keys" keys.lua
  lua_check "treesitter highlight and indent per file type" treesitter.lua
  lua_check "yank highlight, focus reload, last line, q, new folders, resize" autocmds.lua
  if [ "$before" = "$(lock_hash)" ]; then
    pass "starting nvim leaves lazy-lock.json alone"
  else
    fail "starting nvim leaves lazy-lock.json alone" "the lockfile changed"
  fi
  skim_setup
  mason_python
  if [ "$(nvim --headless -c 'lua io.write(vim.o.spellfile)' +qa 2>&1)" -ef "$DOT/config/nvim/spell/en.utf-8.add" ]; then
    pass "zg writes to the versioned word list"
  else
    fail "zg writes to the versioned word list" "spellfile is not config/nvim/spell/en.utf-8.add"
  fi
  tool "stylua" stylua bash -c "cd '$DOT/config/nvim' && stylua --check . ../../tests"
  tool "shell syntax" bash bash -n "$DOT"/macos/*.sh "$DOT"/macos/*/*.sh "$DOT"/tests/*.sh "$DOT/config/nvim/dashboard/clock.sh"
  check "zsh: Neovim is the editor" zsh -f -c "source '$DOT/config/zsh/dotfiles.zsh' && [[ \$EDITOR == nvim && \$VISUAL == nvim ]]"
  check "zsh: emacs keys, even with EDITOR=nvim inherited from a parent shell" env EDITOR=nvim VISUAL=nvim zsh -f -i -c "source '$DOT/config/zsh/dotfiles.zsh'; [[ \$(bindkey -lL main) == 'bindkey -A emacs main' ]]"
  check "zsh: Tab completes git in a shell, a script skips compinit" zsh_completion
  check "zsh: command_origin and path_report tell Homebrew from the system" zsh_helpers
  check "link.sh: a file in the way becomes a backup, the iTerm2 profile's outside DynamicProfiles" link_backup
  tool "zsh: ls, ll and lt run eza in a shell, a script keeps ls" eza zsh_eza
  tool "zsh: Ctrl-r, Ctrl-t and Alt-c run fzf in a shell, a script keeps zsh's keys" fzf zsh_fzf
  tool "zsh: a blank line between prompts, none above the first or after clear" starship zsh_prompt_gap
  tool "tmux: the config loads and git commit opens Neovim" tmux tmux_config
  tool "tmux: C-h/j/k/l cross panes and Neovim's windows both ways, prefix t toggles the scratch popup" tmux tmux_keys
  tool "tmux: the config loads without whichkey-tmux" tmux tmux_without_whichkey
  tool "tmux: the whichkey step keeps its clone and refuses anything else" git tmux_whichkey_step
  tool "shfmt" shfmt shfmt -d "$DOT"/macos/*.sh "$DOT"/macos/*/*.sh "$DOT"/tests/*.sh "$DOT/config/nvim/dashboard/clock.sh"
  tool "rumdl" rumdl rumdl check "$DOT" --config "$DOT/config/rumdl/rumdl.toml"
  check "the dashboard clock draws its digits and date" clock_frame
  if [ -z "$(find "$REAL_STATE/nvim/sessions" -newer "$marker" 2>/dev/null)" ]; then
    pass "the quick tests leave your sessions alone"
  else
    fail "the quick tests leave your sessions alone" "a session was written to $REAL_STATE/nvim/sessions"
  fi
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
  test_servers_per_language
  test_language_actions
  test_test_keys
  test_clojure
  test_review
  test_lazygit
  test_review_debug
  test_markdown
  test_notes
  test_tex
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
