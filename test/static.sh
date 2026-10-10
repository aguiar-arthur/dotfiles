#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

section "Static checks"
cd "$REPO" || exit 1

shell_files() {
  printf '%s\n' install.sh link.sh bin/dotfiles .githooks/pre-commit test/*.sh test/lib/*.sh
}

check_syntax() {
  local f
  for f in $(shell_files); do
    if bash -n "$f" 2>/dev/null; then ok "bash -n $f"; else fail "bash -n $f"; fi
  done
}

check_shell_format() {
  require shfmt || return
  local f
  for f in $(shell_files); do
    if shfmt -d "$f" >/dev/null 2>&1; then ok "shfmt $f"; else fail "shfmt $f (run: shfmt -w $f)"; fi
  done
}

check_zsh() {
  local f
  if ! have zsh; then
    skip "zsh is not installed (zsh -n config/zsh)"
    return
  fi
  for f in config/zsh/*.zsh; do
    if zsh -n "$f" 2>/dev/null; then ok "zsh -n $f"; else fail "zsh -n $f"; fi
  done
}

check_secrets() {
  require gitleaks || return
  local copy
  copy="$(mktemp -d)"
  repo_files | while IFS= read -r f; do
    [ -f "$f" ] && mkdir -p "$copy/$(dirname "$f")" && cp "$f" "$copy/$f"
  done
  if gitleaks dir "$copy" --no-banner --log-level error >/dev/null 2>&1; then
    ok "gitleaks: no secrets in the repository files"
  else
    fail "gitleaks found something (run: gitleaks dir . -v)"
  fi
  rm -rf "$copy"
}

check_lua_format() {
  require stylua || return
  if stylua --config-path config/nvim/stylua.toml --check config/nvim test >/dev/null 2>&1; then
    ok "stylua"
  else
    fail "stylua (run: stylua --config-path config/nvim/stylua.toml config/nvim test)"
  fi
}

check_markdown() {
  require rumdl || return
  if rumdl check --config config/rumdl/rumdl.toml docs README.md AGENTS.md CHANGELOG.md >/dev/null 2>&1; then
    ok "rumdl docs README.md AGENTS.md CHANGELOG.md"
  else
    fail "rumdl (run: rumdl check docs README.md AGENTS.md)"
  fi
}

check_json() {
  require python3 || return
  local f
  for f in config/nvim/lazy-lock.json config/iterm2/dracula.json; do
    if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>/dev/null; then
      ok "json $f"
    else
      fail "json $f"
    fi
  done
}

check_elisp() {
  require emacs || return
  local out
  out="$(emacs --batch -l "$REPO/test/static/parens.el" -- "$REPO" 2>&1)"
  if [ -z "$out" ]; then ok "check-parens and lexical-binding header"; else
    fail "elisp structure"
    printf '        %s\n' "$out"
  fi
}

check_comments() {
  local out
  if have nvim; then
    out="$(nvim --headless -l "$REPO/test/static/comments.lua" "$REPO" 2>&1)"
    if [ -z "$out" ]; then ok "no comments in Lua"; else
      fail "comments in Lua"
      printf '        %s\n' "$out"
    fi
  else
    require nvim
  fi
  if have emacs; then
    out="$(emacs --batch -l "$REPO/test/static/comments.el" -- "$REPO" 2>&1)"
    if [ -z "$out" ]; then ok "no comments in Emacs Lisp"; else
      fail "comments in Emacs Lisp"
      printf '        %s\n' "$out"
    fi
  else
    require emacs
  fi
  if have python3 && have shfmt; then
    out="$(repo_files | python3 "$REPO/test/static/comments.py" "$REPO" 2>&1)"
    if [ -z "$out" ]; then ok "no comments in shell, Python, TOML and other text files"; else
      fail "comments in other files"
      printf '        %s\n' "$out"
    fi
  else
    require python3 shfmt
  fi
}

check_syntax
check_zsh
check_shell_format
check_lua_format
check_markdown
check_json
check_elisp
check_comments
check_secrets
report "static"
