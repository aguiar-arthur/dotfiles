# Dotfiles

Personal macOS setup:

- **Neovim**: the editor, for everything (code, LaTeX, Markdown, git).
- **Starship** prompt and an **iTerm2** profile, both in Dracula colors.

## Install

On a Mac with macOS and an internet connection; nothing else is needed beforehand.

1. **Clone the repository.** On a new Mac, `git` asks to install the Command Line Tools
   first: accept, wait for it to finish, then run the command again.

   ```sh
   git clone https://github.com/aguiar-arthur/dotfiles.git ~/dotfiles
   ```

2. **Run the installer.** It takes a while the first time (MacTeX alone is several GB) and
   asks for your password when Homebrew and MacTeX install.

   ```sh
   cd ~/dotfiles && ./install.sh
   ```

   It goes through three steps, and a failed step does not stop the others:

   - **brew**: Homebrew, if missing, then every program in the `Brewfile` that is not
     installed yet (already installed ones are not upgraded);
   - **link**: `link.sh`, described below;
   - **nvim**: the plugins at the versions in `lazy-lock.json`, the Mason servers and tools,
     the treesitter parsers and the Portuguese spell file, through the linked
     `~/.config/nvim`.

   It ends with `Done.` or with `Failed: <steps>`; fix the errors printed above and run it
   again. Running it again only does what is missing.

3. **Quit iTerm2 (Cmd+Q) and open it again.** The new window uses the "Dotfiles (Dracula)"
   profile with JetBrains Mono Nerd Font, Homebrew on `PATH` and the Starship prompt. If the
   profile did not become the default, run `./link.sh` with iTerm2 closed.

4. **Open Neovim** (`nvim`) and run `:checkhealth` (see [Check](#check)).

Optional: to debug C/C++ programs, turn on developer mode once with
`sudo DevToolsSecurity -enable`; without it the debugger waits on a password dialog.

`link.sh` (also run on its own after a `git pull`):

- links `~/.config/nvim`, `~/.config/starship.toml`,
  `~/.config/rumdl/rumdl.toml` and the iTerm2 Dynamic Profile to this repository, moving
  whatever was there to `<name>.bak.<timestamp>` (three backups kept);
- adds one marked block to `~/.zshrc` that sources `config/zsh/dotfiles.zsh`: Homebrew on
  `PATH`, a valid `LANG` and the Starship prompt;
- makes "Dotfiles (Dracula)" iTerm2's default profile and sets Skim's inverse search to
  Neovim.

## Update

| What | How |
|---|---|
| Programs | `brew update && brew upgrade` |
| Neovim plugins | `:Lazy update`, then commit `config/nvim/lazy-lock.json` if all is well |
| Neovim plugins, roll back | `git restore config/nvim/lazy-lock.json`, then `:Lazy restore` |
| Mason servers and tools | `:Mason`, then `U` |

## Check

Nothing here changes anything; each command says what is missing or wrong.

| What | How | All good when |
|---|---|---|
| Programs | `brew bundle check --verbose --file ~/dotfiles/Brewfile` | `The Brewfile's dependencies are satisfied.` |
| Links, `~/.zshrc`, app preferences | `~/dotfiles/link.sh` (fixes what differs) | every line starts with `ok` |
| Neovim starts cleanly | `nvim --headless "+qa"` | it prints nothing |
| Everything inside Neovim | `:checkhealth` | no `ERROR` |
| Language servers in this buffer | `:checkhealth vim.lsp` | the server is under "Active Clients" |
| Plugins | `:Lazy` | nothing in red |
| Servers and tools from Mason | `:Mason` | all installed |
| Treesitter parsers | `:checkhealth nvim-treesitter` | the `tree-sitter` CLI is found, parsers listed |
| Formatters for this buffer | `:ConformInfo` | the formatter shows as ready |

Run `:checkhealth` in a real Neovim window: in `nvim --headless` the Snacks checks report
errors that are not real. When a check fails, `./install.sh` is the fix for anything
missing (a program, a server, a parser): it installs only what is not there.

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
