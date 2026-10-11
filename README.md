# Dotfiles

Personal macOS setup:

- **Neovim**: the editor, for everything (code, LaTeX, Markdown, git).
- **Starship** prompt and an **iTerm2** profile, both in Dracula colors.

## Install

```sh
git clone <repo> ~/dotfiles && cd ~/dotfiles
./install.sh
```

No options: every machine gets everything. `install.sh` installs Homebrew and the programs in
the `Brewfile`, runs `link.sh`, then installs the Neovim plugins, servers, parsers and spell
files through the linked `~/.config/nvim`. It asks for your password when Homebrew and MacTeX
install. Open a new terminal when it is done. Running it again only does what is missing; a
failed step does not stop the others, and the script names it at the end.

`link.sh` (also run on its own after a `git pull`):

- links `~/.config/nvim`, `~/.config/starship.toml`,
  `~/.config/rumdl/rumdl.toml` and the iTerm2 Dynamic Profile to this repository, moving
  whatever was there to `<name>.bak.<timestamp>` (three backups kept);
- adds one marked block to `~/.zshrc` that sources `config/zsh/dotfiles.zsh`: Homebrew on
  `PATH`, a valid `LANG` and the Starship prompt;
- makes "Dotfiles (Dracula)" iTerm2's default profile and sets Skim's inverse search to
  Neovim (if iTerm2 was running and the profile did not stick, run `./link.sh` again with
  iTerm2 closed).

## Update

| What | How |
|---|---|
| Programs | `brew update && brew upgrade` |
| Neovim plugins | `:Lazy update`, then commit `config/nvim/lazy-lock.json` if all is well |
| Neovim plugins, roll back | `git restore config/nvim/lazy-lock.json`, then `:Lazy restore` |
| Mason servers and tools | `:Mason`, then `U` |

## Per-machine settings

`config/nvim/lua/config/local.lua` (untracked, read when present) returns a table merged
over `lua/config/settings.lua`, for example `return { wrap = false, spelllang = { "en_us" } }`.
For a single project, a `.nvim.lua` at its root ([docs/neovim.md](docs/neovim.md)).

## Layout

```text
config/nvim/      Neovim (lazy.nvim, native LSP)        → docs/neovim.md
config/zsh/       dotfiles.zsh, sourced from ~/.zshrc
config/starship/  starship.toml
config/iterm2/    dracula.json (Dynamic Profile)
config/rumdl/     Markdown lint rules
Brewfile          every program
install.sh        installs everything (runs link.sh before Neovim)
link.sh           links, the ~/.zshrc block, app preferences
```

Changes are listed in [CHANGELOG.md](CHANGELOG.md). MIT, see [LICENSE](LICENSE).
