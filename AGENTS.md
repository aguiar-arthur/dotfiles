# AGENTS.md

Personal dotfiles for macOS: Neovim, Emacs, Starship and an iTerm2 profile. This file is the
harness for agents working in the repo. User-facing documentation lives in `docs/`; `README.md`
is a short entry point that links to it.

## Layout

```text
config/nvim/        Neovim >= 0.11 (lazy.nvim, native LSP in after/lsp/, snippets/)
                    lua/config/settings.lua (defaults), lua/dotfiles/health.lua
config/emacs/       Emacs >= 29.1: early-init.el, init.el, lisp/init-*.el (tested on 31.1)
config/zsh/         dotfiles.zsh, sourced by the one ~/.zshrc block
config/starship/    starship.toml
config/rumdl/       rumdl.toml (Markdown lint rules, user-level)
config/iterm2/      dracula.json (Dynamic Profile)
docs/               all documentation (index.md lists the pages)
test/               run.sh and the checks behind it (see Testing)
bin/dotfiles        doctor, update, rollback, backups, install, link, test
brew/               optional Brewfile groups (latex, clojure, python, ruby)
.githooks/          pre-commit: test/run.sh static
CHANGELOG.md        notable changes, newest first
.github/workflows/  CI: test/run.sh on Ubuntu and macOS
.editorconfig       shell formatting (Lua: config/nvim/stylua.toml)
install.sh          installs: Homebrew, Brewfiles, Neovim plugins/tools/parsers, Emacs packages
link.sh             links, the ~/.zshrc block, the git hook; installs nothing
Brewfile            what every machine needs
README.md           entry point: install commands and links to docs/
```

## No comments in code

This applies to every file in the repository: Lua, Emacs Lisp, shell, TOML, the Brewfile,
`.gitignore`, everything.

- **Do not write comments.** Code says *what*; the *why* goes in `docs/`. Names, small
  functions and `desc` / `:wk` labels carry the rest.
- **Document instead.** Every behaviour, default worth knowing, workaround or design decision
  has a place in `docs/` (see the map below). When you change code, update that page in the
  same change. If a reason would have needed a comment, it needs a sentence in the docs.
- **Allowed exceptions** (they are directives, not comments):
  - the first line of every `.el` file, exactly `;;; -*- lexical-binding: t -*-`;
  - the `#!` line of shell scripts;
  - text that the code writes or matches, such as the `# >>> dotfiles >>>` markers in
    `link.sh`;
  - values that merely contain `#` or `--`, such as colors (`"#282a36"`) or strings.
- **Docstrings** in Emacs Lisp stay, as one short line. Lua type annotations (`---@type`)
  are comments and are not used.
- **Reviewing:** a diff that adds a comment is incomplete. Move the text to `docs/` and remove
  it from the code. List Lua comments with treesitter (`(comment) @c` through
  `vim.treesitter.get_string_parser`) and Emacs Lisp comments with `comment-search-forward`;
  never strip them with a regex, since `--`, `;` and `#` also appear inside strings.

### Where documentation goes

| Change | Page |
|---|---|
| Installation, `install.sh`, `link.sh`, Brewfile | `docs/install.md` |
| Any key, in either editor | `docs/keymaps.md` (both columns) |
| Neovim behaviour, plugins, LSP, formatting, LaTeX, Markdown | `docs/neovim.md` |
| Emacs startup, modules, Org, Clojure, review | `docs/emacs.md` |
| Starship, iTerm2, zsh | `docs/terminal.md` |
| Updating, pinning, rollback, reset, diagnostics | `docs/maintenance.md` |
| Anything under `test/`, CI, what is or is not covered | `docs/testing.md` |
| A setting, the local files, a language, a Brewfile group | `docs/customizing.md` |
| Anything a user would notice | an entry in `CHANGELOG.md` (today's date, Added / Changed / Fixed / Removed) |
| A new page | add it to `docs/index.md` and to the table in `README.md` |

`docs/`, `README.md` and this file are linted by rumdl with `config/rumdl/rumdl.toml` (line
length 100, tables exempt).

## Conventions

- **English everywhere** in code, docs and commit messages, even when the user writes in
  Portuguese. Reply to the user in the language they used.
- **Documentation only in `docs/`**, plus the short root `README.md`. No other README files.
- **One `.gitignore`**, at the root. Never commit generated files.
- **Installing and linking stay separate.** `install.sh` installs (Homebrew, Brewfiles, editor
  plugins, tools, parsers, packages) and never touches `$HOME`; `link.sh` only links, writes
  the `~/.zshrc` block and sets the git hook, and never installs. Both stay idempotent. Editor
  installs in `install.sh` read the configuration from the repository (`XDG_CONFIG_HOME`), so
  it works before `link.sh`. Every install step has a timeout or a failure path: nothing may
  wait forever on the network.
- **Dependencies go in a Brewfile**, not in docs alone: the base `Brewfile` when every machine
  needs it (including the tools this file asks you to run), a group in `brew/` otherwise. A
  program the editors rely on also goes in the health checks (`aa/doctor-executables`,
  `lua/dotfiles/health.lua`, or a language's `executables` in `settings.lua`).
- **Anything a user may want to change is a setting**: a key in `lua/config/settings.lua` and a
  `defcustom` in `lisp/init-settings.el`, documented in `docs/customizing.md`. Never read
  machine-specific values from anywhere else, and never commit `lua/config/local.lua` or
  `config/emacs/local.el`.
- **Keymaps have parity** between Neovim and Emacs: `<Space>` leader, `,` local leader, the
  same groups (`b c d D f g l m o S t u w`). A key present in both does the same job; one
  leader key per action, no duplicates inside the leader tree. Change one side, check the
  other (`config/nvim/lua/config/keymaps.lua` and plugin `keys`,
  `config/emacs/lisp/init-keys.el`) and update `docs/keymaps.md`.
- **Theme is Dracula** across editors, terminal and prompt, including the diff colors.
- **Latest versions, nothing pinned**, except what `docs/maintenance.md` lists.
- Code should be short and readable: prefer `:custom` / `opts` over long `setq` / setup
  blocks.

## Invariants

Behaviour the user asked for and that broke before. Keep it when you touch nearby code; the
details are in the linked docs.

- **No LSP in virtual buffers.** Language servers must not attach to old revisions or index
  copies shown in a diff: they fail on paths that do not exist. Neovim gives `diffview://`
  buffers `buftype=acwrite`; Emacs skips buffers named `file.~REV~` in `aa/clojure-lsp`. A new
  server hook keeps the same guard. ([neovim.md](docs/neovim.md#git-diffs),
  [emacs.md](docs/emacs.md#git-diffs))
- **Navigation keeps the diff.** Inside a diff, `gd` / `gr` / `gi` and `<leader>l…` open a
  result in another file in a new tab and jump in place within the same file (`lsp_pick` in
  Neovim, `aa/call-keeping-diff` in Emacs).
- **Review works the same in both editors.** `<leader>gv` / `gV` open a file panel and a
  side-by-side diff; `Tab` / `S-Tab` move between files, `RET` and `-` act on the panel line,
  `q` closes. Emacs implements it in `init-review.el`.
- **UI toggles are global.** `<leader>u…` toggles apply to every window or buffer and to the
  ones opened later, not only the current one (`<leader>uw` is the model).
- **Emacs startup does no network and asks nothing.** A synchronous download froze startup,
  and a prompt in the daemon hangs invisibly.
- **Nothing fails silently.** A module or local file that fails is recorded, announced at
  startup (Emacs) or notified (Neovim), and shown as an error by `<leader>oh` / `SPC o h` and
  `dotfiles doctor`. A new failure path reports through the same channels.
- **Every update keeps a way back**: the committed `lazy-lock.json` for Neovim, `elpa.bak.*`
  for Emacs (`aa/update-packages` backs up first). Never add an update path without its
  rollback.
- **The file tree follows the current project** (`aa/tree-toggle`); do not bind `treemacs`
  directly, it shows whatever workspace it saved last. Its keys come from `treemacs-evil`
  (without it evil shadows them) and its git colors are set explicitly because Dracula paints
  modified files in the plain text color. Missing saved projects are removed without a prompt
  (`treemacs-missing-project-action`). Look at it in `emacs -nw` too: the tests check faces
  and keys, not the screen.
- **ediff sessions start on their first change**, so diffs are colored at once, as in Neovim.

## Neovim

- Plugins: one spec file per concern in `lua/plugins/`, languages in `lua/plugins/lang/`.
- `lua/config/settings.lua` holds the defaults and the language catalog (servers, tools,
  programs per language); `lsp.lua` takes its lists from there. A language plugin uses
  `cond = require("config.settings").languages.<name>`.
- LSP servers are configured in `after/lsp/<server>.lua` (native `vim.lsp.config`).
- `lazy-lock.json` is versioned: it does not pin anything (`:Lazy update` still tracks HEAD);
  it records the last working state so `:Lazy restore` can roll back a broken update. Never
  run `:Lazy update` or `:Lazy sync` just to verify something: they rewrite the lock.
- Snacks pickers: a custom `confirm` must call `require("snacks.picker.actions").jump`
  directly; actions such as `tab` route back through `confirm` and recurse.

## Emacs

- Generated data lives in `~/.local/share/emacs` (`aa/data-dir`, set in `early-init.el`;
  `no-littering` handles the rest). `config/emacs/` holds only configuration, and
  `.gitignore` whitelists `early-init.el`, `init.el` and `lisp/`. Never write into
  `user-emacs-directory` expecting it to be the repo.
- Packages come from MELPA, GNU and NonGNU ELPA through `use-package` with
  `use-package-always-ensure`. MELPA ranks above NonGNU on purpose.
- Never refresh the package index at startup: it is synchronous and froze Emacs when a server
  was slow. use-package refreshes it when a package is missing.
- Native compilation is **off** on purpose (macOS clang rejects its flags). Do not
  re-enable the JIT or subr trampolines. Code that touches it is guarded with
  `(featurep 'native-compile)`, so the same config also runs on builds without it.
- Modules load through `aa/load-module`: a failing one is recorded in `aa/failed-modules`,
  reported in `*Warnings*`, at startup and by `aa/doctor`, and the rest still load. Order:
  `init-settings`, then `local.el`, then the others, `init-health` last. Keep each module
  independent of the later ones; a new module goes in the list in `init.el`, in
  `test/emacs/smoke-tests.el` and in `docs/emacs.md`.
- Own helpers use the `aa/` prefix. Leader bindings go through `general.el` in `init-keys.el`.
- Org files live in `~/org`; Clojure uses CIDER + clojure-lsp via eglot.
- Pitfalls that already cost a debugging session:
  - a minor mode whose keys are bound for evil states must call `evil-normalize-keymaps` when
    it toggles, or the keys stay inactive until the state changes;
  - closing an ediff session lets magit kill buffers, so loops over `(buffer-list)` in cleanup
    code check `buffer-live-p` and never stay in a buffer that may die;
  - quit ediff programmatically with `ediff-keep-variants` bound to `t`, or it asks "Kill
    buffer A?" and blocks;
  - `(require 'magit)` does not load `magit-ediff`; require submodules you call;
  - xref decides whether to prompt from `this-command`: wrappers set it to the real command;
  - on builds with native compilation (Emacs.app from Homebrew), advising a primitive compiles
    a trampoline, which macOS clang rejects: load `early-init.el` (it disables trampolines)
    before any `advice-add`, as `test/emacs/boot.el` does.

## Testing

`test/run.sh` is the definition of "works". Run it (all levels, or the one that fits) before
saying a change is done, and report its result.

| Level | Checks |
|---|---|
| `static` | formatting, syntax, rumdl, parentheses, secrets, no comments in any file |
| `scripts` | `install.sh` (with stub `brew`/`nvim`/`emacs`), `link.sh`, `bin/dotfiles` and the hook in a throwaway `HOME` |
| `smoke` | both editors start from scratch without errors, warnings, network or prompts |
| `keys` | the real leader maps equal `docs/keymaps.md`, no duplicate actions |
| `behavior` | the invariants above (`test/nvim/behavior.lua`, `test/emacs/behavior-tests.el`) |

- **A bug fix comes with a test** that fails without the fix. Check that by reverting the fix
  in a copy; a test that never failed proves nothing.
- **A new invariant goes in the list above and in `behavior`.** A new leader key needs a row in
  `docs/keymaps.md` (both columns), or `keys` fails.
- Tests obey every rule of this file: no comments, English, `stylua` / `shfmt` formatting.
- Never edit `lazy-lock.json` by hand to make `smoke` pass; see Neovim above.
- The tests run on macOS too: compare paths after `pwd -P` (`$TMPDIR` ends in `/` and `/var`
  is a link to `/private/var`), and keep shell code working on bash 3.2 (no empty
  `"${array[@]}"` under `set -u`).
- What the tests cannot see (GUI, real language servers, LaTeX) still needs the manual steps
  below. Say plainly what was not tested.
- The pre-commit hook runs `static`; do not bypass it with `--no-verify` to land a change.
- In the user's environment, `dotfiles doctor` is the first diagnostic to run and to ask for.

## Verifying by hand

The checks above cover the routine. These steps are for what they do not: interactive
behaviour and debugging.

### Install and link scripts

- `scripts` covers both with stubs. A real `install.sh` run needs the network (Homebrew,
  GitHub, the Mason registry); off the Mac use `--skip brew` and point `HOME` and
  `XDG_DATA_HOME` at throwaway directories.

### Neovim from scratch

- Point `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME` at empty
  directories, copy `config/nvim`, run `nvim --headless "+Lazy! restore" +qa`, then open real
  files with `--headless` and read `:messages` from a deferred Lua callback.
- Headless pitfalls: the `pt` spell-file download prompt blocks every later event (give the
  test copy a `lua/config/local.lua` with `spelllang = { "en_us" }`, as `test/` does);
  `vim.lsp.enable` after a buffer's `FileType` needs `:edit` to attach; if Mason's registry is
  unreachable, put the server binary on `PATH`.
- `XDG_CONFIG_HOME` also moves Emacs' configuration directory (Emacs 29+). A shell that set it
  for Neovim must reset it to `$HOME/.config` before starting Emacs (`emacs_env` does).

### Emacs, also off the Mac

- On the Mac: start Emacs and check `*Warnings*` for `Module ... failed`.
- Elsewhere: build the `emacs-mirror/emacs` tag that matches `emacs --version` on the Mac
  (`mkdir -p info && touch info/emacs`, then `./autogen.sh`,
  `./configure --without-x --without-native-compilation`, `make src`) and run `src/emacs -nw`
  with `HOME` and `XDG_DATA_HOME` pointing at copies of the config and of
  `~/.local/share/emacs/elpa` (ask the user before copying it). Package archives may be
  unreachable there; the copied `elpa` is enough.
- Drive real keys through tmux when it is available (`tmux send-keys Space g v`; tmux is not
  in the Brewfile) and record state from Lisp (`M-:` calling a probe that writes to a file).
  In terminal Emacs `Escape` is the Meta prefix: never send it right before another key.
  Start it with `LANG=C.UTF-8`, or icons show as `?`.

### Reporting

Say plainly what was **not** tested (for example, keys that need a GUI or a real server).

## Git

- Commit only when asked. Keep messages in English, imperative, and focused on the why.
- Do not stage or commit unrelated changes the user made by hand.
- For read-only inspection use `git --no-optional-locks status` / `diff`: a plain
  `git status` writes `.git/index.lock`, and when it is interrupted or sandboxed the lock stays
  behind and blocks the user's git.

## Editing a copy of the repo

When you work on a copy and write files back (for example to the user's machine):

- compare checksums of the target files first, so you never overwrite edits the user made in
  the meantime;
- write every file of the change, then verify the checksums on the target: a dropped
  connection can leave a partial sync (it happened: `init-dev.el` arrived, `init-keys.el` did
  not);
- remove any temporary file you created outside the repo;
- the device bridge refuses to write files inside `.github/`; write them to a temporary folder
  in the repo and `mv` it into place with the device shell, after the user agreed.
