# Changelog

Notable changes, newest first. Each entry says what changed for the person using the editors
and, when it matters, why. Plugin and package version bumps are not listed: `lazy-lock.json`
and `git log` have them.

## 2026-10-11

### Added

- Clojure in Neovim: Conjure evaluates code in a REPL, nvim-paredit edits s-expressions, and
  `,cj` starts an nREPL (deps.edn or Leiningen) and connects to it.
- Debugging JavaScript/TypeScript (js-debug-adapter) and C/C++ (codelldb), next to Python.
- Per-project settings: a trusted `.nvim.lua` at a project's root runs on startup (`exrc`).
- Treesitter text objects for functions (`af`/`if`), classes (`ac`/`ic`) and calls
  (`au`/`iu`) in every language, through mini.ai.
- `<leader>r` searches and replaces across the project (grug-far).

### Changed

- Emacs is gone: the repository is Neovim, Starship and iTerm2 only. `install.sh` no longer
  installs Emacs or its packages, `link.sh` no longer links `~/.config/emacs`, and the `e`
  alias, `emacs-app` and `aspell` are removed. Clojure files are edited in Neovim with
  clojure-lsp; the Clojure programs stay in the Brewfile.
- Installation is one command with no options: `./install.sh` installs everything (one
  Brewfile, including LaTeX as `mactex-no-gui`, Clojure, uv and ruby), downloads the
  Portuguese spell file and ends with `link.sh`, which also makes "Dotfiles (Dracula)"
  iTerm2's default profile and sets Skim's inverse search to Neovim.
- Every `<Space>u…` toggle in Neovim is global: it changes every window or buffer and the ones
  opened later. Conceal is on everywhere, not only in LaTeX.
- diffview.nvim, unmaintained since 2024, is replaced by its maintained fork
  diffview-plus.nvim (same commands and keys).
- Mason no longer installs stylua, shfmt, prettier and rumdl: the Brewfile has them.
  `:MasonUninstall stylua shfmt prettier rumdl` removes the old copies. debugpy is installed
  by `install.sh`, never on the first debug key.
- Neovim's settings list the servers, tools and parsers directly; the per-language switches
  are gone.
- The iTerm2 profile sets JetBrainsMono Nerd Font Mono 13 itself.
- The mini.nvim plugins come from `nvim-mini/`; floating windows take their border from
  `winborder`; the lazy.nvim update checker is off.

### Fixed

- Neovim enabled every language server installed in Mason, including old leftovers (a stylua
  server ran in Lua files); now only the servers listed in the settings start.
- `install.sh` hung forever when lazy.nvim could not be cloned (no network): Neovim waited
  for a key in a headless run. It now exits with an error.
- On a new Mac, Homebrew's programs were not on `PATH` in new terminals; the zsh block now
  puts them there.
- `config/zsh/dotfiles.zsh` replaces a `LANG` macOS has no locale for (`en_BR.UTF-8`) with
  `en_US.UTF-8`, and leaves `C` and `POSIX` alone.

### Removed

- Tests, CI, the pre-commit hook, the health checks (`:checkhealth dotfiles`, the startup
  warnings) and `bin/dotfiles` (doctor, update, rollback). The README lists the update
  commands.
- Every option of `install.sh` and `link.sh`, the `brew/` groups, and `gitleaks`, `fzf`,
  `bat`, `jq`, `coreutils`, `findutils`, `curl`, `wget` and `git-lfs` from the Brewfile.
- The docs pages for install, keymaps, customizing, maintenance, terminal and testing; the
  README and `docs/neovim.md` cover what is left.
- Dead entries: the `LazyVim` trigger in lazydev, `q`-to-close for file types that no longer
  exist, and options set to their default values.

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
