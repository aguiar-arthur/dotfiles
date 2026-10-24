# Install

Getting a Mac from nothing to this setup, and keeping it there: Homebrew and the Brewfiles,
`install.sh`, `link.sh`, the Mason packages, parsers and spell files Neovim needs, the plugin
lockfile, and the shell, prompt and terminal. Its relationships are in [map](map.md).

## Language

- **nvim mode**: `install.sh nvim` / `link.sh nvim`, which touch only Neovim (`Brewfile.nvim`,
  `~/.config/nvim`, the rumdl rules, `~/.latexmkrc`, Skim's preferences) on a
  machine whose shell and terminal must stay as they are.
- **step**: one of `brew`, `link`, `nvim` in `install.sh`; a failed step does not stop the
  others.
- **lockfile**: `config/nvim/lazy-lock.json`, the plugin commits; the way back after a bad
  update.

## Files

| Path | Holds |
|---|---|
| `Brewfile` | every program; includes `Brewfile.nvim` |
| `Brewfile.nvim` | what Neovim needs, alone |
| `install.sh` | the three steps: brew (trusting third-party taps first), link, nvim |
| `link.sh` | links with backups, the `~/.zshrc` block, iTerm2 and Skim preferences |
| `config/nvim/lua/dotfiles/install.lua` | headless install of Mason packages, parsers and spell files, with time limits |
| `config/nvim/lua/dotfiles/mason.lua` | which Mason packages the settings want and which are missing |
| `config/nvim/lua/config/lazy.lua` | lazy.nvim cloned at the lockfile's commit |
| `config/nvim/lazy-lock.json` | plugin versions (committed) |
| `config/zsh/dotfiles.zsh` | Homebrew on `PATH`, a valid `LANG`, `JAVA_HOME`, `EDITOR` / `VISUAL`, history, `path_report`, `command_origin`, Starship |
| `config/starship/starship.toml` | the prompt, Dracula colors |
| `config/iterm2/dracula.json` | the "Dotfiles (Dracula)" Dynamic Profile |

## How it works

`install.sh` runs `brew`, `link`, `nvim` in that order and ends with `Done.` or
`Failed: <steps>`. The nvim step needs `~/.config/nvim` to link to this repository, so Neovim
uses the same config as every day: `Lazy! restore` puts plugins at the lockfile's commits (and
runs their `build` steps, such as codediff's library), then `dotfiles.install` installs the
Mason packages, the parsers (with the `tree-sitter` CLI) and the non-English spell files.
Everything is idempotent and only does what is missing; already installed programs are not
upgraded (`brew bundle --no-upgrade`).

`link.sh` links each file, moving whatever was there to `<name>.bak.<timestamp>` (three kept),
adds one marked block (`# >>> dotfiles >>>`) to `~/.zshrc` that sources `dotfiles.zsh`, and
writes the iTerm2 and Skim preferences with `defaults`. Every line it prints starts with `ok`
when nothing had to change.

## Contract

Offers: every program, link, Mason package, parser and spell file the other contexts assume is
there ([code](code.md) servers, [git](git.md) codediff library, [latex](latex.md) Skim and
`~/.latexmkrc`).

Consumes: [core](core.md) `settings` (which servers, tools, parsers and spell languages).

## Pitfalls

- Homebrew loads a formula or cask from a third-party tap (`owner/tap/name` in a Brewfile) only
  once it is trusted; `install.sh` runs `brew trust` for each before `brew bundle`.
- `:Lazy update` and `:Lazy sync` rewrite `lazy-lock.json`; never run them just to check
  something. The tests fail if the lockfile changes.
- Mason installs nothing when Neovim starts: a new server needs `./install.sh nvim` again
  (`dotfiles/install.lua`; mason-tool-installer was dropped, it only duplicated that).
- Every network step needs a timeout or a failure path: the Mason registry waits a minute, its
  installs 15 minutes, a spell file two; a failed Homebrew or plugin step fails its step.

## Checks

| What | Where |
|---|---|
| Mason wanted and missing lists, spell files to fetch | `tests/helpers.lua` |
| Starting Neovim leaves the lockfile alone | quick: `starting nvim leaves lazy-lock.json alone` |
| Shell syntax and format of the scripts | quick: `shell syntax`, `shfmt` |
| `dotfiles.zsh` makes Neovim the editor, without comments | quick: `zsh: Neovim is the editor`, `no comments in shell` |
| `install.sh nvim` in an empty home | full: `install` in `tests/lib.sh`; `fresh` in a throwaway folder |

## Changing it

- **A program**: one line in `Brewfile` (or `Brewfile.nvim` when Neovim needs it); a
  third-party tap needs nothing more, `install.sh` trusts it. Then the README's install list if
  it is a Neovim program.
- **A Mason tool, parser or spell language**: the list in `settings.lua` (see [core](core.md));
  `install.lua` picks it up.
- **A new link**: one `src|dst` line in `links()` in `link.sh`, under the `nvim` check if it is
  not for Neovim; then the README's "What `link.sh` does".
