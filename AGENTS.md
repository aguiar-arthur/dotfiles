# AGENTS.md

Personal dotfiles for macOS: Neovim, Starship and an iTerm2 profile. Keep them small: this
is one person's setup, not a product.

## Layout

```text
config/nvim/        Neovim >= 0.11: lazy.nvim, one spec per concern in lua/plugins/, native
                    LSP with per-server settings in after/lsp/, lazy-lock.json committed
config/zsh/         dotfiles.zsh, sourced by the one ~/.zshrc block
config/starship/    starship.toml
config/rumdl/       rumdl.toml (Markdown lint rules)
config/iterm2/      dracula.json (Dynamic Profile)
docs/               neovim.md (everything about the editor)
Brewfile            every program (includes Brewfile.nvim)
Brewfile.nvim       what Neovim needs, alone
install.sh          installs everything, running link.sh before Neovim
link.sh             links, the ~/.zshrc block, iTerm2 and Skim preferences
CHANGELOG.md        notable changes, newest first
```

## Rules

- **Simple first.** No tests, no CI, no health checks, no doctor, no flags. `./install.sh`
  installs everything and runs `link.sh` before the Neovim step (Neovim then uses the linked
  `~/.config/nvim`, as every day). The one exception to "no flags": both scripts take an
  optional `nvim` argument that limits them to Neovim (`Brewfile.nvim`, `~/.config/nvim` and
  the rumdl rules) for machines whose shell and terminal must stay untouched. Both stay
  idempotent in both modes and only do what is missing. Every network step in `install.sh`
  has a timeout or a failure path.
- **No comments in code**, in any file. Names and `desc` / `:wk` labels say what; a reason
  worth keeping goes in one sentence in `docs/`. Exceptions: `#!` lines and text the code
  writes or matches (the `# >>> dotfiles >>>` markers).
- **macOS only**, no branches for other systems.
- **English** in code, docs and commit messages; reply to the user in their language.
- **Every program goes in the Brewfile**; what Neovim needs goes in `Brewfile.nvim`, which
  the Brewfile includes.
- **Settings** a user may change live in `config/nvim/lua/config/settings.lua` (including the
  servers, Mason tools and parsers to install); per-machine overrides go in the untracked
  `lua/config/local.lua`, per-project ones in a trusted `.nvim.lua` (`exrc`).
- **Dracula** everywhere (editor, prompt, terminal), including diff colors.
- **Latest versions.** `config/nvim/lazy-lock.json` is committed as the way back after a bad
  plugin update (`:Lazy restore`); never run `:Lazy update` or `:Lazy sync` just to check
  something, they rewrite it.
- When a change is something the user would notice, add a line to `CHANGELOG.md` and update
  the README or the editor's page in `docs/`.

## Pitfalls that already cost time

- Language servers must not attach to `diffview://` buffers (old revisions, the index copy):
  they fail on paths that do not exist. Neovim gives those buffers `buftype=acwrite`.
- Neovim's own ftplugins for Lua, Markdown, help and query call `vim.treesitter.start()`
  after the `FileType` autocmds; anything that turns treesitter off must stop it again later.
- Snacks pickers: a custom `confirm` must call `require("snacks.picker.actions").jump`
  directly; actions such as `tab` route back through `confirm` and recurse.
- `mason-lspconfig` gets `automatic_enable = mason_servers`, never `true`: `true` enables any
  server left installed in Mason (a stale stylua server once ran in Lua files).
- blink.cmp registers its LSP capabilities when it loads, so it stays a dependency of
  nvim-lspconfig; otherwise servers started before the first insert lack them.
- Conjure is limited to Clojure (`conjure#filetypes`); its other clients would map keys in
  Lua and Python. `K` and `gd` stay with the language server.
- Snacks installs `vim.ui.input` / `vim.ui.select` and the dashboard on `UIEnter`, which a
  headless Neovim never fires: `:checkhealth snacks` errors there are not real.
- C/C++ debugging (codelldb) needs macOS developer mode (`sudo DevToolsSecurity -enable`);
  without it the session waits on a password dialog.

## Checking a change by hand

- Neovim: `nvim --headless "+qa"` prints nothing, and opening a file of the language you
  touched shows no error in `:messages`.
- Anything that needs a UI (LSP attach, Snacks, which-key, Conjure, DAP) is checked in a real
  terminal: write a Lua probe that waits with `vim.defer_fn`, writes what it sees to a file
  and quits, then run `sleep 30 | script -q /dev/null nvim -c "luafile probe.lua"` (the
  `sleep` keeps stdin open; without it Neovim gets EOF and quits). Work in a scratch
  project, point `XDG_STATE_HOME` at a scratch directory for anything that writes state
  (`:trust`), and stop only the processes you started, never with a broad `pkill`.
- Scripts: `bash -n install.sh link.sh` and `shfmt -d` on what you changed; Lua through
  `stylua` (rules in `config/nvim/stylua.toml`).
- Say plainly what you could not check (GUI, real language servers, LaTeX).

## Git

- Commit only when asked; messages in English, imperative, about the why.
- Do not stage or commit changes the user made by hand.
- For read-only inspection use `git --no-optional-locks status` / `diff`.
