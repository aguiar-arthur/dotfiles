#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

section "Scripts: install.sh, link.sh, bin/dotfiles and the git hook in a throwaway HOME"
require git || {
  report "scripts"
  exit $?
}

work_dir
copy="$WORK/repo"
mkdir -p "$copy"
repo_files | while IFS= read -r f; do
  [ -f "$REPO/$f" ] && mkdir -p "$copy/$(dirname "$f")" && cp -p "$REPO/$f" "$copy/$f"
done
git -C "$copy" init -q
git -C "$copy" config user.email test@example.com
git -C "$copy" config user.name test
git -C "$copy" add -A
git -C "$copy" commit -qm snapshot --no-verify

export HOME="$WORK/home"
mkdir -p "$HOME/.config/nvim"
cat >"$HOME/.zshrc" <<'ZSH'
export KEEP_ME=1

# >>> dotfiles: starship >>>
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
# <<< dotfiles: starship <<<

# >>> dotfiles: emacs >>>
alias e='emacsclient -n -c -a ""'
# <<< dotfiles: emacs <<<
ZSH

check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then ok "$name"; else fail "$name"; fi
}

"$copy/link.sh" --check >/dev/null 2>&1
check "--check reports pending changes on a fresh HOME" test $? -eq 1

"$copy/link.sh" >"$WORK/first.txt" 2>&1
check "first run succeeds" test $? -eq 0
check "~/.config/nvim links to the repo" test "$(readlink "$HOME/.config/nvim")" = "$copy/config/nvim"
check "~/.config/emacs links to the repo" test "$(readlink "$HOME/.config/emacs")" = "$copy/config/emacs"
check "the replaced directory was backed up" compgen -G "$HOME/.config/nvim.bak.*"
check "~/.zshrc keeps the user's lines" grep -qx 'export KEEP_ME=1' "$HOME/.zshrc"
check "~/.zshrc has exactly one dotfiles block" test "$(grep -c '^# >>> dotfiles' "$HOME/.zshrc")" -eq 1
check "the old per-feature blocks are gone" bash -c "! grep -q 'dotfiles: starship' '$HOME/.zshrc'"
check "the block sources config/zsh/dotfiles.zsh" grep -q "$copy/config/zsh/dotfiles.zsh" "$HOME/.zshrc"
check "git uses .githooks" test "$(git -C "$copy" config --get core.hooksPath)" = .githooks

cp "$HOME/.zshrc" "$WORK/zshrc.after-first"
"$copy/link.sh" >"$WORK/second.txt" 2>&1
check "second run changes nothing" bash -c "! grep -vE '^(ok |Done\\.)' '$WORK/second.txt' | grep -q ."
check "second run leaves ~/.zshrc identical" cmp -s "$HOME/.zshrc" "$WORK/zshrc.after-first"
"$copy/link.sh" --check >/dev/null 2>&1
check "--check is clean after install" test $? -eq 0

for _ in 1 2 3 4; do
  rm "$HOME/.config/nvim"
  mkdir -p "$HOME/.config/nvim"
  sleep 1
  "$copy/link.sh" >/dev/null 2>&1
done
check "only the 3 newest backups are kept" test "$(compgen -G "$HOME/.config/nvim.bak.*" | wc -l)" -eq 3

if have zsh; then
  check "dotfiles.zsh puts bin/ on PATH" zsh -c "source '$copy/config/zsh/dotfiles.zsh'; [[ \$DOTFILES == '$copy' ]] && whence dotfiles >/dev/null"
else
  skip "zsh is not installed (dotfiles.zsh not sourced)"
fi

check "dotfiles help" "$copy/bin/dotfiles" help
"$copy/bin/dotfiles" nonsense >/dev/null 2>&1
check "dotfiles rejects an unknown command" test $? -eq 2

export XDG_DATA_HOME="$WORK/data"
mkdir -p "$XDG_DATA_HOME/emacs/elpa/pkg" "$XDG_DATA_HOME/emacs/elpa.bak.20260101-000000/pkg"
echo broken >"$XDG_DATA_HOME/emacs/elpa/pkg/version"
echo good >"$XDG_DATA_HOME/emacs/elpa.bak.20260101-000000/pkg/version"
check "dotfiles backups lists the Emacs backups" bash -c "'$copy/bin/dotfiles' backups | grep -q elpa.bak.20260101-000000"
"$copy/bin/dotfiles" rollback emacs >/dev/null 2>&1
check "dotfiles rollback emacs restores the newest backup" grep -qx good "$XDG_DATA_HOME/emacs/elpa/pkg/version"
check "the replaced packages are kept aside" compgen -G "$XDG_DATA_HOME/emacs/elpa.broken.*"

if have shfmt && have stylua && have rumdl; then
  check "the pre-commit hook passes on a clean tree" bash -c "cd '$copy' && .githooks/pre-commit"
  printf '\n# a comment\n' >>"$copy/link.sh"
  git -C "$copy" add link.sh
  (cd "$copy" && .githooks/pre-commit) >/dev/null 2>&1
  check "the pre-commit hook blocks a comment in code" test $? -ne 0
  git -C "$copy" checkout -q -- link.sh
  git -C "$copy" reset -q
else
  skip "pre-commit hook (needs shfmt, stylua and rumdl)"
fi

"$copy/link.sh" --uninstall >/dev/null 2>&1
check "--uninstall removes the links" test ! -L "$HOME/.config/nvim"
check "--uninstall removes the block" bash -c "! grep -q '^# >>> dotfiles' '$HOME/.zshrc'"
check "--uninstall keeps the user's lines" grep -qx 'export KEEP_ME=1' "$HOME/.zshrc"
check "--uninstall unsets the hooks" bash -c "! git -C '$copy' config --get core.hooksPath"

stubs="$WORK/stubs"
mkdir -p "$stubs"
cat >"$stubs/stub" <<'STUB'
#!/usr/bin/env bash
printf '%s %s | XDG_CONFIG_HOME=%s\n' "$(basename "$0")" "$*" "${XDG_CONFIG_HOME:-}" >>"$STUB_LOG"
case " ${STUB_FAIL:-} " in *" $(basename "$0") "*) exit 1 ;; esac
exit 0
STUB
chmod +x "$stubs/stub"
for tool in brew nvim emacs; do ln -s stub "$stubs/$tool"; done
export STUB_LOG="$WORK/calls.log"

installer() {
  : >"$STUB_LOG"
  PATH="$stubs:$PATH" "$copy/install.sh" "$@" >"$WORK/installer.txt" 2>&1
}

installer --help
check "install.sh --help" test $? -eq 0
installer --with nope
check "install.sh rejects an unknown group" test $? -eq 2
installer --skip nothing
check "install.sh rejects an unknown step" test $? -eq 2

installer --with latex
check "install.sh succeeds when every step does" test $? -eq 0
check "it runs brew bundle on the Brewfile" grep -q "^brew bundle --file $copy/Brewfile " "$STUB_LOG"
check "it adds the requested group" grep -q "^brew bundle --file $copy/brew/latex.Brewfile " "$STUB_LOG"
check "it leaves the other groups alone" bash -c "! grep -q 'clojure.Brewfile' '$STUB_LOG'"
check "it restores the Neovim plugins from the lock" grep -q '^nvim --headless +Lazy! restore +qa' "$STUB_LOG"
check "it installs Mason tools and parsers headless" grep -q "dotfiles.install" "$STUB_LOG"
check "it installs the Emacs packages" grep -q "^emacs --batch -l $copy/config/emacs/early-init.el" "$STUB_LOG"
check "editors read the repository's config, not ~/.config" bash -c "grep '^nvim\|^emacs' '$STUB_LOG' | grep -qv 'XDG_CONFIG_HOME=$copy/config$' && exit 1 || exit 0"
check "nothing is linked by install.sh" test ! -e "$HOME/.config/starship.toml"

installer --all
check "--all installs every group" test "$(grep -c '^brew bundle --file .*/brew/' "$STUB_LOG")" -eq "$(ls "$copy"/brew/*.Brewfile | wc -l)"

installer --skip brew --skip emacs
check "--skip leaves out the named steps" bash -c "! grep -qE '^(brew|emacs) ' '$STUB_LOG' && grep -q '^nvim ' '$STUB_LOG'"

STUB_FAIL=nvim installer
check "a failing step makes install.sh fail" test $? -eq 1
check "it names the failed step" grep -q "Some steps failed: nvim" "$WORK/installer.txt"
check "the steps after a failure still run" grep -q "^emacs " "$STUB_LOG"

report "scripts"
