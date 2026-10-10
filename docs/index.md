# Documentation

Everything about how this repository works lives here. The code has no comments: when you
want to know why something is configured the way it is, look it up in these pages.

| Page | Covers |
|---|---|
| [install.md](install.md) | Installing on a new Mac, what `install.sh` and the `Brewfile` do |
| [keymaps.md](keymaps.md) | Every `<Space>` (leader) and `,` (local leader) key, Neovim and Emacs side by side |
| [neovim.md](neovim.md) | Neovim: structure, plugins, LSP, formatting, LaTeX, Markdown, git diffs, design notes |
| [emacs.md](emacs.md) | Emacs: startup, modules, Org, notes, Clojure, git diffs, design notes |
| [terminal.md](terminal.md) | Starship prompt, iTerm2 profile, the blocks added to `~/.zshrc` |
| [customizing.md](customizing.md) | Settings and the untracked local files of both editors, Brewfile groups |
| [testing.md](testing.md) | `test/run.sh`: static checks, startup, keymap and invariant tests, CI |
| [maintenance.md](maintenance.md) | Updating, rolling back, adding things, resetting, diagnostics |

## Layout

```text
Brewfile                      what every machine needs (brew bundle)
brew/                         optional Brewfile groups: latex, clojure, python, ruby
install.sh                    links, the ~/.zshrc block, the git hook; --check, --uninstall
bin/dotfiles                  doctor, update, rollback, backups, install, test
CHANGELOG.md                  notable changes, newest first
AGENTS.md                     conventions for AI agents (CLAUDE.md points to it)
README.md                     short entry point
docs/                         this documentation
test/                         run.sh and the checks it runs (docs/testing.md)
.github/workflows/check.yml   CI: test/run.sh on Ubuntu and macOS for pushes and pull requests
.editorconfig                 shell formatting (Lua rules: config/nvim/stylua.toml)
.githooks/pre-commit          runs test/run.sh static before every commit
config/
  nvim/                       Neovim >= 0.11
  emacs/                      Emacs >= 29 (tested on 31.1)
  starship/starship.toml      prompt
  zsh/dotfiles.zsh            what the ~/.zshrc block sources
  rumdl/rumdl.toml            Markdown lint rules (user-level default)
  iterm2/dracula.json         iTerm2 Dynamic Profile
```

## Shared principles

- **Same keys in both editors.** `<Space>` is the leader and `,` the local leader. The leader
  groups use the same letters (`b c d D f g l m o S t u w`), so a key learned in one editor
  works in the other. [keymaps.md](keymaps.md) lists the few places where they differ.
- **Dracula everywhere:** editors, terminal and prompt, including the same diff colors.
- **Latest versions.** Plugins and packages track upstream; nothing is pinned. Neovim records
  the last working state in `lazy-lock.json` so it can roll back
  ([maintenance.md](maintenance.md)).
- **The repository holds configuration only.** Everything generated (plugins, packages,
  caches, history) lives under `~/.local/share` and `~/.local/state`.
