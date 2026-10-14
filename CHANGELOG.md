# Changelog

Notable changes, newest first. Each entry says what changed for the person using the editors
and, when it matters, why. Plugin and package version bumps are not listed: `lazy-lock.json`
and `git log` have them.

## 2026-10-13

### Changed

- `<leader>gV` reviews the branch against origin's default branch side by side (codediff.nvim):
  the changed files in a list, `]f` / `[f` between files, `]c` / `[c` between changes, and the
  real file on the right for `gd` and edits. The Snacks picker listed hunks only.
- Neovim 0.12 or newer is required: the grammar toggle (`<leader>uG`) uses its LSP API and
  failed on 0.11.
- The README explains each part of the editor with a table of its keys: completion, finding,
  editing, windows and terminals, code, run / test / debug, git, toggles, Clojure, LaTeX and
  Markdown, plus the shell, prompt and terminal files.
- The debugger moved from `<leader>D…` to `,d…` and is available only in Python, JavaScript
  and TypeScript buffers (same letters: `,db`, `,dc`, `,di`, `,do`, `,dO`, `,dr`, `,dl`, `,dt`,
  `,du`, `,de`, `,dB`).
- Git changes and history come from the Snacks picker (preview, `<Tab>` stages a hunk):
  `<leader>gV` lists the branch's changes against origin's default branch, `<leader>gh` the
  history of the file and the new `<leader>gL` that of the line. `<leader>gv` and `<leader>gH`
  are gone: `<leader>gc` and `<leader>gl` already do the same. Merge conflicts go to lazygit.

### Removed

- JavaScript and TypeScript support: vtsls, ESLint, js-debug-adapter, neotest-jest, prettier
  for JS/TS files, `,r` with node and the `typescript` / `tsx` parsers. HTML, CSS, JSON and
  YAML stay, with prettier and node (Mason installs their servers with npm).
  `:MasonUninstall vtsls eslint-lsp js-debug-adapter` and `:Lazy clean` remove the old copies.
- `<leader>ld`, `<leader>lr`, `<leader>lh` and `<leader>wh` / `wj` / `wk` / `wl` / `ww`: they
  repeated `gd`, `gr`, `K` and `C-h` / `C-j` / `C-k` / `C-l`.
- diffview-plus.nvim, a small fork of an abandoned project, which does not meet the new plugin
  rule (`AGENTS.md`).
- harpoon and nvim-dap-virtual-text, which repeat what is already here: files to come back to
  are uppercase marks (`mA`, then `'A`), listed with the new `<leader>fm`, and the dap-ui panels
  show the variables while debugging.
- C and C++ support: clangd, codelldb, the C/C++ parsers and `.clang-format` handling are gone,
  along with the C/C++ `,` keys. Existing Mason installs of clangd and codelldb stay on disk
  (`:MasonUninstall clangd codelldb` removes them). It comes back when it is needed, done
  properly.

### Added

- which-key names every menu: `<leader>h` (hunks, in a review), Conjure's `,ca` and `,ec`, and
  the vimtex keys that had no label (`,la`, `,ls`, `,lS`, `,lL`, `,lG`, `,lI`, `,lX`).
- `<leader>wh` / `wj` / `wk` / `wl` move between windows, as `C-h` / `C-j` / `C-k` / `C-l` do.
- In a review, `<leader>gf` (as `gf`) opens the file in the previous tab.
- `<leader>gD` reviews the working tree side by side, as `<leader>gV` does the branch.
- A new look: treesitter-context keeps the current function on top (`<leader>ux`), a Snacks
  status column groups signs, git and folds, and mini.statusline (Dracula colors) replaces
  lualine with the same information. The `:` line and messages stay Neovim's own.
- ESLint in JS/TS projects that have an ESLint config: its errors show next to vtsls's type
  errors, and `:LspEslintFixAll` fixes what it can. Other projects do not start it.
- `,` keys by file type: `,r` runs the file in one reused bottom terminal (Python, JS/TS, Lua,
  shell), `,t…` runs tests through Neotest (pytest and jest: the nearest test, the file, the
  project, a summary and the output; `,td` debugs a Python test), `,o` organizes imports
  wherever the language server offers it (ruff, vtsls) and `,s` sources a Lua file. The
  Conjure groups have which-key labels.
- `tests/nvim.sh` checks the Neovim setup by hand: `quick` (seconds) for startup, modules,
  lockfile, formatters and the no-comments rule; `full` also installs Neovim in an isolated
  home and drives a real Neovim in tmux (language servers, toggles, notes, a LaTeX build).
- LaTeX is set up for a thesis: builds go to `build/` (texlab follows), `link.sh` links a
  versioned `latexmkrc`, Skim reloads the PDF on change, and the `abnt` snippet expands to a
  full abnTeX2 skeleton with `capa`, `resumo`, `abstract`, `citacao`, `citeonline` and `apud`.
  Folds follow sections. ltex-ls-plus checks grammar in `pt-BR` (`% LTeX: language=en-US`
  switches it; `<leader>uG` toggles it). Spelling stays with vim spell (`zg`), so a typo is
  underlined once and an accepted word is accepted everywhere.
- Markdown is now a notes setup: render-markdown.nvim draws the buffer (`<leader>um` toggles
  it), and obsidian.nvim (no Obsidian app or account) handles the notes in `~/notes`
  (`notes.dir` in the settings): `<leader>n` finds, greps, creates and opens daily notes and
  lists backlinks, `[[links]]` complete and `<CR>` follows them. marksman serves the rest of
  Markdown. `<CR>` ticks a checkbox in a note and the pandoc preview (`,p`) stays.
- `ast-grep` is installed with the Neovim programs, so grug-far (`<leader>r`) can search and
  replace by code structure and `:checkhealth grug-far` no longer warns.
- `tmux` is installed by the main `Brewfile`, so `tests/nvim.sh full` can drive Neovim; a
  machine set up with `./install.sh nvim` skips those checks.
- `python` (Homebrew) is installed with the Neovim programs, so Mason builds `debugpy` against
  a current Python instead of Apple's 3.9, and the Python debugger falls back to it.

### Fixed

- `]c` / `[c` in a review follow its changes also in files the review opened itself; gitsigns
  took the keys there and jumped to the changes against the index.
- `<leader>uc` turns conceal off in Markdown buffers too; render-markdown set it back to 2.
- `,o` (organize imports) checks the buffer the server attached to, not the current one, before
  taking the key.
- `C-\` toggles the bottom terminal, as the README says; it opened the same floating terminal
  as `<leader>tf`.
- Language server hovers no longer get the Markdown preview key `,p` and its save hook: the
  Markdown ftplugin now skips buffers that are not files.
- `<leader>fF` lists the files git ignores too, as the README says; it used to skip them like
  `<leader>ff`.
- Words added with `zg` are now versioned in `config/nvim/spell/en.utf-8.add`, as the docs
  said; they used to land in `~/.local/share/nvim/site/spell/` and stay on one machine.
- `rumdl` no longer reports `CLAUDE.md`, which only holds the `@AGENTS.md` import.
- A first install checks out `lazy.nvim` at the commit in `lazy-lock.json` instead of the
  latest `stable` tag, so it no longer leaves the lockfile modified.
- In Clojure, `,o` is nvim-paredit's raise again: clojure-lsp's organize imports took it once
  the server attached (it stays under `<leader>la`).

## 2026-10-11

### Fixed (sixth review)

- The `⟳ latexmk` mark in the status line shows again while vimtex compiles; it called a
  vimtex function that does not exist and never appeared.
- Format on save no longer counts a bare `.editorconfig` (Lua, shell) or `pyproject.toml`
  (Python) as a style: stylua needs a `stylua.toml`, shfmt an `.editorconfig` section for
  shell files, ruff a `ruff.toml` or `[tool.ruff]`. TOML and Clojure, formatted by their
  language servers, now also need a `taplo.toml` or a cljfmt config.
- `<leader>gV` finds origin's default branch (`origin/HEAD`, else `origin/main` or
  `origin/master`) instead of failing in clones without `origin/HEAD`.
- The jump list drops entries of deleted buffers again (`jumpoptions` keeps `clean`).
- Debugger breakpoints and the stopped line have Dracula-colored signs instead of a plain `B`.

### Fixed (fifth review)

- `gq` wraps prose and comments again in Markdown, Python and Lua; the language server's
  range formatting had taken it over and left long lines as they were.
- Format on save now also needs a project style file for prettier (a prettier config),
  ruff (`pyproject.toml` or `ruff.toml`) and rumdl (`.rumdl.toml` or `.markdownlint.*`), so a
  `:w` no longer restyles JSON, YAML, Python or Markdown in someone else's project.
  `<leader>lf` still formats anywhere.
- Searching with `/` or `?` no longer opens a completion menu of buffer words; it opens on
  the `:` line only.
- Cancelling `<leader>DB` no longer sets a breakpoint with an empty condition.
- `,cj` reports a dead REPL even when `.nrepl-port` holds an invalid port.

### Fixed (fourth review)

- On the `:` command line the first `<Tab>` completes (it only showed the menu already shown)
  and `<CR>` runs a completed line at once instead of needing a second `<CR>`.
- Python buffers no longer mix UTF-8 (ruff) and UTF-16 (basedpyright) positions, which
  `:checkhealth vim.lsp` warned about.
- Lua and shell files format on save only in projects with a `stylua.toml` or
  `.editorconfig` (Lua) or an `.editorconfig` (shell), like C/C++ with `.clang-format`: a `:w`
  in someone else's file no longer restyles it (stylua would also turn its indentation into
  tabs).

### Fixed (third review)

- Debugging Python runs the file with the project's `.venv` (uv projects, not activated in
  the shell), so the project's imports work; before, debugpy used Mason's own Python.
- dap-ui stays open when the program ends, so its output can still be read.
- C and C++ format on save only in projects with a `.clang-format`; other code is not
  restyled to LLVM style by a `:w`.
- LaTeX math: `x12` gives `x_{12}` (it gave `x_12`, a subscript of one digit); `sin`, `log`
  and the other functions expand at the start of a line too; `<->` gives `\leftrightarrow`.

### Fixed (second review)

- In terminals, `C-\ C-n` leaves terminal mode again: `C-\` toggles the terminal only from
  normal mode, so it no longer opened a second terminal over lazygit or a REPL.
- The `,l` "vimtex (LaTeX)" label shows in every `.tex` buffer, and no longer in other
  buffers (in Clojure `,l` is Conjure's log).
- Snippets with transformations work (LuaSnip's `jsregexp` is built), and `<Tab>` no longer
  jumps back into a snippet already left.
- `q` closes a help or quickfix buffer that is the only window instead of failing.
- Markdown previews of files with the same name in different folders no longer overwrite
  each other.
- `,cj` pressed again while the REPL starts only says so; when the REPL dies before it is
  ready, the wait stops and the next `,cj` replaces its terminal with a new REPL.

### Added (Neovim only)

- `./install.sh nvim` and `./link.sh nvim` set up Neovim alone, for machines whose shell and
  terminal must not change: only the programs in the new `Brewfile.nvim` (which the main
  `Brewfile` includes), and only the `~/.config/nvim` and rumdl links. `~/.zshrc`, Starship,
  iTerm2 and app preferences are left alone.

### Changed (review)

- Enter in the command line runs the command at once: the completion menu no longer
  preselects its first item, which turned `:w` into `:wall` and `:set nu` into `:set number`
  and needed a second Enter.
- `<leader>lf` formats in every buffer, not only where a language server is attached.
- In LaTeX, `]` appears as soon as it is typed (vimtex's insert-mode `]]` is off); the `,l`
  keys are vimtex's own, with which-key labels, so `,lr` is its reverse search again (reload is
  `,lx`); `,lw` counts words. The `doc` and `bdoc` snippets no longer load `inputenc`.
- `,cj` in Clojure starts a new REPL when `.nrepl-port` is left over from one that died.
- Skim's inverse search calls Neovim by its full path, so it works when Skim is opened from
  the Finder (run `./link.sh` again).
- LaTeX autosnippets no longer fire right after a `\`, so `\sum`, `\int`, `\sqrt` or
  `\begin` typed by hand stay as typed; `beg` expands only at the start of a line, `<=>`
  gives `\iff` again, and `frm` / `blk` / `ablk` jump to the body before leaving.
- Terminals get every key: `jk`, `C-h/j/k/l` and `Esc Esc` are no longer mapped in terminal
  mode (they delayed `j` in lazygit and took `C-l` / `C-k` from the shell); a quick double
  `Esc` still returns to Neovim.
- `<leader>tf`, `<leader>th` and `<leader>tv` open three separate terminals instead of
  toggling the same one.
- `<Tab>` / `<S-Tab>` no longer switch buffers, so `<C-i>` moves forward in the jump list
  again; use `<leader>bn` / `<leader>bp` / `<leader>bb`.
- References of the word under the cursor are `]r` / `[r`, not `]]` / `[[`; `gi` is Vim's
  again (implementation stays on `<leader>li`).
- In insert mode `<Tab>` jumps to the next snippet field before moving in the menu.
- Treesitter indents only the languages in `settings.treesitter_indent`.
- A `:setlocal` of wrap, relative numbers, conceal or spell survives switching buffers; the
  global `<leader>u` toggles only reset it when they change. `vim.b.keep_local_opts = true`
  opts a buffer out of them entirely.
- Treesitter parsers missing at startup install only in an interactive Neovim, so the
  headless runs of `install.sh` never quit in the middle of a parser build.
- `install.sh` runs `link.sh` before the Neovim step, which now uses the linked
  `~/.config/nvim` instead of overriding `XDG_CONFIG_HOME` (that also hid
  `~/.config/git/config` from the git that lazy.nvim runs).
- Neovim no longer checks Mason on every start; `./install.sh` installs servers and tools.
- `./install.sh` no longer upgrades Homebrew programs that are already installed
  (`brew bundle --no-upgrade`); `brew upgrade` stays the way to update them.

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
