# AGENTS.md

Personal dotfiles for macOS: Neovim, Emacs, Starship and an iTerm2 profile.
`README.md` is the single user-facing doc; this file is for agents working in the repo.

## Layout

```text
config/nvim/        Neovim >= 0.11 (lazy.nvim, native LSP in after/lsp/, snippets/)
config/emacs/       Emacs >= 29: early-init.el, init.el, lisp/init-*.el
config/starship/    starship.toml
config/rumdl/       rumdl.toml (Markdown lint rules, user-level)
config/iterm2/      dracula.json (Dynamic Profile)
install.sh          symlinks + marked ~/.zshrc blocks
Brewfile            every dependency
```

## Conventions

- **English everywhere** in code, comments, docs and commit messages, even when the
  user writes in Portuguese. Reply to the user in the language they used.
- **One README**, at the root. Do not add per-directory READMEs. Update it when keymaps,
  dependencies or layout change.
- **One `.gitignore`**, at the root. Never commit generated files.
- **`install.sh` installs nothing.** It only creates symlinks and the marked zshrc blocks, and
  stays idempotent. Neovim plugins, Mason tools and Emacs packages install on first launch.
- **Dependencies go in the `Brewfile`**, not in docs alone.
- **Keymaps have parity** between Neovim and Emacs: `<Space>` leader, `,` local leader, the
  same prefixes (`b c d D f g l m o S t u w`). Change one side, check the other
  (`config/nvim/lua/config/keymaps.lua`, `config/emacs/lisp/init-keys.el`).
- **Theme is Dracula** across editors, terminal and prompt.
- Code should be short and readable: prefer `:custom`/`opts` over long `setq`/setup blocks,
  comment the *why*, not the *what*.

## Neovim

- Plugins: one spec file per concern in `lua/plugins/`, languages in `lua/plugins/lang/`.
- LSP servers are configured in `after/lsp/<server>.lua` (native `vim.lsp.config`).
- `lazy-lock.json` is versioned: it does not pin anything (`:Lazy update` still tracks HEAD),
  it records the last working state so `:Lazy restore` can roll back a broken update.
- Check: `nvim --headless "+Lazy! sync" +qa` and `:checkhealth`.

## Emacs

- Generated data lives in `~/.local/share/emacs` (`aa/data-dir`, set in `early-init.el`;
  `no-littering` handles the rest). `config/emacs/` holds only configuration, and
  `.gitignore` whitelists `early-init.el`, `init.el` and `lisp/`. Never write into
  `user-emacs-directory` expecting it to be the repo.
- Packages come from MELPA, GNU and NonGNU ELPA through `use-package` with
  `use-package-always-ensure`. MELPA ranks above NonGNU on purpose.
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
- Emacs: `emacs --batch --init-directory ~/.config/emacs` (installs packages on first run),
  or just start Emacs and check `*Warnings*` for `Module ... failed`.
- Check parenthesis balance in every edited `.el` file before handing it over; an unbalanced
  file breaks its whole module.
- Say plainly what was **not** tested (for example, when Emacs is not available in the sandbox).

## Git

- Commit only when asked. Keep messages in English, imperative, and focused on the why.
- Do not stage or commit unrelated changes the user made by hand.
