# Changelog

Notable changes, newest first. Each entry says what changed for the person using the editors
and, when it matters, why. Plugin and package version bumps are not listed: `lazy-lock.json`
and `git log` have them.

## 2026-10-10

### Added

- `dotfiles` command (`bin/dotfiles`): `doctor`, `update`, `rollback`, `backups`, `install`,
  `test`.
- Health reports: `<Space>oh` (`:checkhealth dotfiles`) in Neovim and `SPC o h`
  (`aa/doctor`) in Emacs. Emacs also announces failed modules at startup.
- Per-machine settings: `lua/config/local.lua` and `config/emacs/local.el`, both ignored by
  git, over the defaults in `lua/config/settings.lua` and `lisp/init-settings.el`. Languages
  can be turned off.
- Emacs package backups before every update (newest three kept) and
  `aa/rollback-packages` / `dotfiles rollback emacs`.
- `install.sh --check` and `--uninstall`; pre-commit hook running the static checks.
- `test/run.sh` with five levels (static, install, smoke, keys, behavior) and CI on Ubuntu
  and macOS for pushes and pull requests. Nothing runs on a schedule: updates happen with
  `dotfiles update` (`--test` also runs the tests on the new versions).
- `gitleaks` secret scan, `stylua.toml` and `.editorconfig`.
- Brewfile groups in `brew/` (latex, clojure, python, ruby); `uv` replaces `pyenv` and
  `pipenv`; `gitleaks` joins the base Brewfile.

### Changed

- `~/.zshrc` gets one block that sources `config/zsh/dotfiles.zsh`; the old `starship` and
  `emacs` blocks are migrated. Before, a change to a block never reached existing installs.
- Emacs file tree: `treemacs-evil` keys (it was unusable in `emacs -nw`), Dracula git colors
  (modified files looked unchanged), missing projects dropped without a prompt.
- ediff sessions start on their first change, so the diff is colored right away.
- Lua reformatted with stylua (two spaces, 100 columns).

### Fixed

- Obsolete Emacs APIs found by the byte-compile check: `if-let` / `when-let`,
  `org-edit-src-content-indentation`, `diff-hl-magit-pre-refresh`,
  `native-comp-deferred-compilation`; `magit-blame-quit` called interactively.

### Removed

- Emacs `SPC h b`: it duplicated `SPC f k`.
