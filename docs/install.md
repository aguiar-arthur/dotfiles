# Install

Getting a Mac from nothing to this setup, and keeping it there: Homebrew and the parts in
`macos/` (their Brewfiles, `install.sh` and `link.sh`), the Mason packages, parsers and spell
files Neovim needs, the plugin lockfile, and the shell, prompt and terminal. Its relationships
are in [map](map.md).

## Language

- **part**: one folder in `macos/` (`nvim`, `terminal`, `apps`) with its own `Brewfile`,
  `install.sh` and (nvim, terminal) `link.sh`; it installs alone, so a machine whose shell and
  terminal must stay as they are runs only `macos/nvim/install.sh`.
- **step**: one of `brew`, `link`, `nvim` in a part's `install.sh`; a failed step does not stop
  the others, and a failed part does not stop `macos/install.sh`.
- **lockfile**: `config/nvim/lazy-lock.json`, the plugin commits; the way back after a bad
  update.

## Files

| Path | Holds |
|---|---|
| `macos/install.sh` | runs every part: terminal, apps, nvim |
| `macos/lib.sh` | what the parts share: `step_brew` (trusting third-party taps first), `step_link`, `run_steps`, `link` with backups, `pref` |
| `macos/nvim/` | `Brewfile` (what Neovim needs), `install.sh` (brew, link, nvim), `link.sh` (`~/.config/nvim`, rumdl, `~/.latexmkrc`, Skim) |
| `macos/terminal/` | `Brewfile` (Starship, tmux, iTerm2, the font), `install.sh` (brew, link), `link.sh` (Starship, the iTerm2 profile and default, `~/.zshrc`) |
| `macos/apps/` | `Brewfile` (programs that are neither), `install.sh` (brew) |
| `config/nvim/lua/dotfiles/install.lua` | headless install of Mason packages, parsers and spell files, with time limits |
| `config/nvim/lua/dotfiles/mason.lua` | which Mason packages the settings want and which are missing or broken |
| `config/nvim/lua/config/lazy.lua` | lazy.nvim cloned at the lockfile's commit |
| `config/nvim/lazy-lock.json` | plugin versions (committed) |
| `config/zsh/dotfiles.zsh` | Homebrew on `PATH`, a valid `LANG`, `JAVA_HOME`, `EDITOR` / `VISUAL`, history, `path_report`, `command_origin`, Starship |
| `config/starship/starship.toml` | the prompt, Dracula colors |
| `config/iterm2/dracula.json` | the "Dotfiles (Dracula)" Dynamic Profile |

## How it works

`macos/install.sh` runs the parts' `install.sh` (terminal, apps, nvim) and ends with `Done.`
or `Failed: <parts>`; each part runs its steps in order (`brew`, `link`, then `nvim` for
Neovim) and ends with `Done: <part>.` or `Failed: <steps>`. The nvim step needs
`~/.config/nvim` to link to this repository, so Neovim uses the same config as every day:
`Lazy! restore` puts plugins at the lockfile's commits (and runs their `build` steps, such as
codediff's library), then `dotfiles.install` installs the Mason packages, the parsers (with
the `tree-sitter` CLI) and the non-English spell files. Everything is idempotent and only does
what is missing; already installed programs are not upgraded (`brew bundle --no-upgrade`).

Each `link.sh` links its files, moving whatever was there to `<name>.bak.<timestamp>` (three
kept), and writes its app's preferences with `defaults` (Skim, iTerm2); the terminal one also
adds one marked block (`# >>> dotfiles >>>`) to `~/.zshrc` that sources `dotfiles.zsh`. Every
line they print starts with `ok` when nothing had to change.

## Contract

Offers: every program, link, Mason package, parser and spell file the other contexts assume is
there ([code](code.md) servers, [git](git.md) codediff library, [latex](latex.md) Skim and
`~/.latexmkrc`).

Consumes: [core](core.md) `settings` (which servers, tools, parsers and spell languages).

## Pitfalls

- The scripts live in `macos/` but link from the repository root (`DOT` in `lib.sh` is its
  parent folder), so `config/` stays where it is and they run from any working directory; a
  part finds its own `Brewfile` and `link.sh` through `HERE`, set before it sources `lib.sh`.
- Homebrew loads a formula or cask from a third-party tap (`owner/tap/name` in a Brewfile) only
  once it is trusted; `step_brew` runs `brew trust` for each before `brew bundle`.
- `:Lazy update` and `:Lazy sync` rewrite `lazy-lock.json`; never run them just to check
  something. The tests fail if the lockfile changes.
- Mason installs nothing when Neovim starts: a new server needs `macos/nvim/install.sh` again
  (`dotfiles/install.lua`; mason-tool-installer was dropped, it only duplicated that).
- Mason's Python tools (basedpyright, debugpy) run from a venv tied to Homebrew's Python minor
  version; a `brew upgrade` to a new one leaves them unable to start while Mason still calls
  them installed. `dotfiles.mason` counts such a package as missing, so `macos/nvim/install.sh`
  reinstalls it, and the quick tests say when one is broken.
- Every network step needs a timeout or a failure path: the Mason registry waits a minute, its
  installs 15 minutes, a spell file two; a failed Homebrew or plugin step fails its step.

## Checks

| What | Where |
|---|---|
| Mason wanted, missing and broken lists, spell files to fetch | `tests/helpers.lua` |
| Mason's Python tools on this machine can start | quick: `Mason's Python tools still have their Python` |
| Starting Neovim leaves the lockfile alone | quick: `starting nvim leaves lazy-lock.json alone` |
| Shell syntax and format of the scripts | quick: `shell syntax`, `shfmt` |
| `dotfiles.zsh` makes Neovim the editor, without comments | quick: `zsh: Neovim is the editor`, `no comments in shell` |
| `macos/nvim/install.sh` in an empty home | full: `install` in `tests/lib.sh`; `fresh` in a throwaway folder |

## Changing it

- **A program**: one line in the `Brewfile` of the part that needs it (`macos/apps/Brewfile`
  when it is neither Neovim nor terminal); a third-party tap needs nothing more, `step_brew`
  trusts it. Then the README's part table.
- **A Mason tool, parser or spell language**: the list in `settings.lua` (see [core](core.md));
  `install.lua` picks it up.
- **A new link**: one `link <src> <dst>` line in the part's `link.sh`; then the README's "What
  the `link.sh` files do".
- **A new part**: a folder in `macos/` with a `Brewfile` and an `install.sh` that sets `HERE`,
  sources `../lib.sh` and calls `run_steps`; add it to the loop in `macos/install.sh` and to
  the README's part table.
