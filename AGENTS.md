# AGENTS.md

Personal dotfiles for macOS: Neovim, Emacs, Starship and an iTerm2 profile. This file is the
harness for agents working in the repo. User-facing documentation lives in `docs/`; `README.md`
is a short entry point that links to it.

## Layout

```text
config/nvim/        Neovim >= 0.11 (lazy.nvim, native LSP in after/lsp/, snippets/)
config/emacs/       Emacs >= 29: early-init.el, init.el, lisp/init-*.el
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
  it from the code. Lua comments can be listed with treesitter (`(comment) @c`), Emacs Lisp
  comments with `comment-search-forward`; never strip them with a regex, since `--`, `;` and
  `#` also appear inside strings.

### Where documentation goes

| Change | Page |
|---|---|
| Installation, `install.sh`, Brewfile | `docs/install.md` |
| Any key, in either editor | `docs/keymaps.md` (both columns) |
| Neovim behaviour, plugins, LSP, formatting, LaTeX, Markdown | `docs/neovim.md` |
| Emacs startup, modules, Org, Clojure | `docs/emacs.md` |
| Starship, iTerm2, zsh | `docs/terminal.md` |
| Updating, pinning, rollback, reset, diagnostics | `docs/maintenance.md` |
| A new page | add it to `docs/index.md` and to the table in `README.md` |

`docs/` is linted by rumdl with `config/rumdl/rumdl.toml` (line length 100, tables exempt).

## Conventions

- **English everywhere** in code, docs and commit messages, even when the user writes in
  Portuguese. Reply to the user in the language they used.
- **Documentation only in `docs/`**, plus the short root `README.md`. No other README files.
- **One `.gitignore`**, at the root. Never commit generated files.
- **`install.sh` installs nothing.** It only creates symlinks and the marked zshrc blocks, and
  stays idempotent. Neovim plugins, Mason tools and Emacs packages install on first launch.
- **Dependencies go in the `Brewfile`**, not in docs alone.
- **Keymaps have parity** between Neovim and Emacs: `<Space>` leader, `,` local leader, the
  same groups (`b c d D f g l m o S t u w`). A key present in both does the same job; one
  leader key per action, no duplicates inside the leader tree. Change one side, check the
  other (`config/nvim/lua/config/keymaps.lua` and plugin `keys`,
  `config/emacs/lisp/init-keys.el`) and update `docs/keymaps.md`.
- **Theme is Dracula** across editors, terminal and prompt, including the diff colors.
- **Latest versions, nothing pinned**, except what `docs/maintenance.md` lists.
- Code should be short and readable: prefer `:custom` / `opts` over long `setq` / setup
  blocks.

## Neovim

- Plugins: one spec file per concern in `lua/plugins/`, languages in `lua/plugins/lang/`.
- LSP servers are configured in `after/lsp/<server>.lua` (native `vim.lsp.config`).
- `lazy-lock.json` is versioned: it does not pin anything (`:Lazy update` still tracks HEAD);
  it records the last working state so `:Lazy restore` can roll back a broken update.
- Check: `nvim --headless "+Lazy! sync" +qa` and `:checkhealth`.

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
  re-enable the JIT or subr trampolines.
- Modules load through `aa/load-module`: a failing one is reported in `*Warnings*` and the
  rest still load. Keep each module independent of the later ones.
- Own helpers use the `aa/` prefix. Leader bindings go through `general.el` in `init-keys.el`.
- Org files live in `~/org`; Clojure uses CIDER + clojure-lsp via eglot.

## Verifying changes

There is no test suite; verify by loading.

- `bash -n install.sh`, and run it in a throwaway `HOME` to confirm it is idempotent.
- Neovim: `nvim --headless +qa` must print no errors.
- Emacs: start it and check `*Warnings*` for `Module ... failed`. Emacs and the packages can be
  tested off the Mac too: build Emacs from the `emacs-mirror/emacs` tag that matches the
  installed version and run it with a copy of `~/.local/share/emacs/elpa`.
- Check parenthesis balance in every edited `.el` file before handing it over; an unbalanced
  file breaks its whole module.
- No comments slipped in (see above), and `rumdl check docs README.md AGENTS.md` passes.
- Say plainly what was **not** tested (for example, when Emacs is not available in the sandbox).

## Git

- Commit only when asked. Keep messages in English, imperative, and focused on the why.
- Do not stage or commit unrelated changes the user made by hand.
