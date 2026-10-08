# AGENTS.md

Personal dotfiles for macOS: Neovim, Emacs, Starship and an iTerm2 profile. This file is the
harness for agents working in the repo. User-facing documentation lives in `docs/`; `README.md`
is a short entry point that links to it.

## Layout

```text
config/nvim/        Neovim >= 0.11 (lazy.nvim, native LSP in after/lsp/, snippets/)
config/emacs/       Emacs >= 29.1: early-init.el, init.el, lisp/init-*.el (tested on 31.1)
config/starship/    starship.toml
config/rumdl/       rumdl.toml (Markdown lint rules, user-level)
config/iterm2/      dracula.json (Dynamic Profile)
docs/               all documentation (index.md lists the pages)
install.sh          symlinks + marked ~/.zshrc blocks
Brewfile            every dependency
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
  - text that the code writes or matches, such as the `# >>> dotfiles: … >>>` markers in
    `install.sh`;
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
| Installation, `install.sh`, Brewfile | `docs/install.md` |
| Any key, in either editor | `docs/keymaps.md` (both columns) |
| Neovim behaviour, plugins, LSP, formatting, LaTeX, Markdown | `docs/neovim.md` |
| Emacs startup, modules, Org, Clojure, review | `docs/emacs.md` |
| Starship, iTerm2, zsh | `docs/terminal.md` |
| Updating, pinning, rollback, reset, diagnostics | `docs/maintenance.md` |
| A new page | add it to `docs/index.md` and to the table in `README.md` |

`docs/`, `README.md` and this file are linted by rumdl with `config/rumdl/rumdl.toml` (line
length 100, tables exempt).

## Conventions

- **English everywhere** in code, docs and commit messages, even when the user writes in
  Portuguese. Reply to the user in the language they used.
- **Documentation only in `docs/`**, plus the short root `README.md`. No other README files.
- **One `.gitignore`**, at the root. Never commit generated files.
- **`install.sh` installs nothing.** It only creates symlinks and the marked zshrc blocks, and
  stays idempotent. Neovim plugins, Mason tools and Emacs packages install on first launch.
- **Dependencies go in the `Brewfile`**, not in docs alone, including the tools this file asks
  you to run (rumdl, stylua, shfmt…).
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
- **The file tree follows the current project** (`aa/tree-toggle`); do not bind `treemacs`
  directly, it shows whatever workspace it saved last.

## Neovim

- Plugins: one spec file per concern in `lua/plugins/`, languages in `lua/plugins/lang/`.
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
- Modules load through `aa/load-module`: a failing one is reported in `*Warnings*` and the
  rest still load. Keep each module independent of the later ones; a new module goes in the
  list in `init.el` and in `docs/emacs.md`.
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
  - xref decides whether to prompt from `this-command`: wrappers set it to the real command.

## Verifying changes

There is no test suite; verify by loading, from scratch when the change touches startup or
packages.

### Static checks

- `bash -n install.sh`; run it twice in a throwaway `HOME` (second run changes nothing).
- `rumdl check docs README.md AGENTS.md`.
- No comments slipped in (see above) and `check-parens` passes on every edited `.el` file;
  an unbalanced file breaks its whole module.

### Neovim from scratch

- Point `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME` at empty
  directories, copy `config/nvim`, run `nvim --headless "+Lazy! restore" +qa`, then open real
  files with `--headless` and read `:messages` from a deferred Lua callback.
- Headless pitfalls: the `pt` spell-file download prompt blocks every later event (set
  `spelllang` to `en_us` in the test copy only); `vim.lsp.enable` after a buffer's `FileType`
  needs `:edit` to attach; if Mason's registry is unreachable, put the server binary on `PATH`.

### Emacs, also off the Mac

- On the Mac: start Emacs and check `*Warnings*` for `Module ... failed`.
- Elsewhere: build the `emacs-mirror/emacs` tag that matches `emacs --version` on the Mac
  (`mkdir -p info && touch info/emacs`, then `./autogen.sh`,
  `./configure --without-x --without-native-compilation`, `make src`) and run `src/emacs -nw`
  with `HOME` and `XDG_DATA_HOME` pointing at copies of the config and of
  `~/.local/share/emacs/elpa` (ask the user before copying it). Package archives may be
  unreachable there; the copied `elpa` is enough.
- Drive real keys through tmux (`tmux send-keys Space g v`) and record state from Lisp
  (`M-:` calling a probe that writes to a file). In terminal Emacs `Escape` is the Meta
  prefix: never send it right before another key.

### Keymaps

- Dump the real leader maps (`nvim_get_keymap` / `nvim_buf_get_keymap` after `VeryLazy` and
  an `LspAttach`; in Emacs walk `(evil-get-auxiliary-keymap general-override-mode-map
  'normal)` under `SPC`) and compare them with `docs/keymaps.md` in both directions.

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
- remove any temporary file you created outside the repo.
