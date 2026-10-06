# Dotfiles

Personal environment for macOS: **Neovim** (a general-purpose editor with a complete LaTeX
workflow), **Emacs** (Org mode and Clojure, with the same keys as Neovim), **Starship** (prompt)
and **iTerm2** (Dracula profile).

## Install

```sh
git clone <repo> ~/dotfiles && cd ~/dotfiles
brew bundle
./install.sh
```

`brew bundle` installs every program; `install.sh` only creates links and two marked blocks in
`~/.zshrc`. Plugins and packages install the first time each editor opens. Details and the
manual steps (iTerm2 profile, Skim inverse search) are in [docs/install.md](docs/install.md).

## Documentation

| Page | Covers |
|---|---|
| [docs/install.md](docs/install.md) | installation, `install.sh`, the Brewfile |
| [docs/keymaps.md](docs/keymaps.md) | every leader and local-leader key, Neovim and Emacs side by side |
| [docs/neovim.md](docs/neovim.md) | Neovim: plugins, LSP, formatting, LaTeX, Markdown, git diffs |
| [docs/emacs.md](docs/emacs.md) | Emacs: startup, modules, Org, Clojure, git diffs |
| [docs/terminal.md](docs/terminal.md) | Starship, iTerm2, zsh |
| [docs/maintenance.md](docs/maintenance.md) | updating, rollback, reset, diagnostics |

The code carries no comments; the reasons behind each setting are in `docs/`.

## License

MIT, see [LICENSE](LICENSE).
