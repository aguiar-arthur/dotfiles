# Changelog

Notable changes, newest first. Each entry says what changed for the person using the editors
and, when it matters, why. Plugin and package version bumps are not listed: `lazy-lock.json`
and `git log` have them.

## 2026-10-10

### Added

- `dotfiles` command (`bin/dotfiles`): `doctor`, `update`, `rollback`, `backups`, `install`,
  `link`, `test`.
- Health reports: `<Space>oh` (`:checkhealth dotfiles`) in Neovim and `SPC o h`
  (`aa/doctor`) in Emacs. Emacs also announces failed modules at startup.
- Per-machine settings: `lua/config/local.lua` and `config/emacs/local.el`, both ignored by
  git, over the defaults in `lua/config/settings.lua` and `lisp/init-settings.el`. Languages
  can be turned off.
- Emacs package backups before every update (newest three kept) and
  `aa/rollback-packages` / `dotfiles rollback emacs`.
- `install.sh` now installs everything (Homebrew, Brewfile and groups, Neovim plugins, Mason
  servers and tools, treesitter parsers, Emacs packages); the old linking script is
  `link.sh`, with `--check` and `--uninstall`. Pre-commit hook running the static checks.
- `test/run.sh` with five levels (static, scripts, smoke, keys, behavior) and CI on macOS for
  pushes and pull requests. Nothing runs on a schedule: updates happen with
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
- Treesitter parsers follow the enabled languages, like servers and tools; Mason servers are
  installed by mason-tool-installer together with the tools.
- Lua reformatted with stylua (two spaces, 100 columns).

### Fixed

- Obsolete Emacs APIs found by the byte-compile check: `if-let` / `when-let`,
  `org-edit-src-content-indentation`, `diff-hl-magit-pre-refresh`,
  `native-comp-deferred-compilation`; `magit-blame-quit` called interactively.

- `.gitignore` covers editor backups and locks, merge leftovers, rumdl's cache and compiled
  spell files.

- `test/run.sh` on macOS: temporary paths are compared after resolving `/var` →
  `/private/var` and the trailing `/` of `$TMPDIR`, and the Emacs tests load `early-init.el`
  before advising primitives, so Emacs.app does not try to compile native trampolines. A
  failing Emacs test run now prints the error instead of only a backtrace.

### Removed

- Linux handling: the Linux CI job, the Linuxbrew path and Linux message in `install.sh`, the
  macOS check around the iTerm2 link, the zathura / generic viewer fallback for LaTeX, the
  Linux font folder in the health report and the X11 case for `exec-path-from-shell`.
- Emacs `SPC h b`: it duplicated `SPC f k`.
