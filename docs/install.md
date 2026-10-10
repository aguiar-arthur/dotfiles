# Installation

Two scripts, kept apart on purpose:

| Script | Does | Never does |
|---|---|---|
| `install.sh` | installs: Homebrew, the programs in the Brewfiles, Neovim plugins, Mason servers and tools, treesitter parsers, Emacs packages | touch your home directory |
| `link.sh` | connects: links into `~/.config`, the `~/.zshrc` block, the git hook | install anything |

```sh
git clone <repo> ~/dotfiles && cd ~/dotfiles
./install.sh --with latex --with clojure     # 1. everything the configuration needs
./link.sh                                    # 2. links, the ~/.zshrc block, the git hook
exec zsh && dotfiles doctor                  # 3. is everything in place?
```

Either script can run again at any time; each only does what is missing.

Then:

1. In iTerm2: *Settings → Profiles → "Dotfiles (Dracula)" → Other Actions → Set as Default*.
2. For LaTeX, set up Skim's inverse search ([neovim.md](neovim.md#latex)).
3. Per-machine choices (theme, languages, font size…) go in the local files
   ([customizing.md](customizing.md)). Turning a language off there also means `install.sh`
   skips its servers, tools and parsers.
4. The first time you open a `.tex` or `.md` file, Neovim asks to download the Portuguese
   spell file; answer `y` once (or drop `pt_br` from `spelllang`).

## What `install.sh` does

```text
./install.sh [--with GROUP]... [--all] [--skip STEP]...
```

| Step | What it installs |
|---|---|
| `brew` | Homebrew itself when it is missing (its official installer, which asks for your password; macOS only), then `brew bundle` on the `Brewfile` and on each group given with `--with` (`--all` for every group in `brew/`) |
| `nvim` | the plugins at the versions in `lazy-lock.json` (`:Lazy! restore`), then the Mason servers and tools and the treesitter parsers of the enabled languages (`lua/dotfiles/install.lua`) |
| `emacs` | every package the configuration uses, by loading it once in batch mode; fails if a module does not load |

`--skip brew`, `--skip nvim` or `--skip emacs` leaves a step out. The editors read the
configuration straight from the repository (`XDG_CONFIG_HOME` points at `config/` for these
runs), so `install.sh` works before `link.sh` and never writes to `~/.config`. Plugins and
packages land where the editors normally keep them (`~/.local/share/nvim`,
`~/.local/share/emacs`).

Each step reports `ok` or `ERROR` lines; at the end the script lists the failed steps and exits
1, otherwise it points to `link.sh`. A failed step does not stop the next one. The Neovim step
gives up after a minute if Mason's registry does not answer and reports it, instead of
waiting forever as `:MasonToolsInstallSync` does.

Without `install.sh`, the editors still install what they need on first launch: lazy.nvim,
Mason and treesitter in the background, Emacs packages at startup. `install.sh` does it
up front, all at once, and tells you what failed.

## What `link.sh` does

It only creates links, one marked block in `~/.zshrc` and a git setting. It never installs
programs, plugins or packages, and it is idempotent: running it again changes nothing.

| Mode | Does |
|---|---|
| `./link.sh` | create or repair everything below |
| `./link.sh --check` | print what would change and exit 1 if anything would (nothing is written) |
| `./link.sh --uninstall` | remove the links that point into the repository, the `~/.zshrc` block and the git setting; backups stay |

| Item | Target |
|---|---|
| `~/.config/nvim` | → `config/nvim` |
| `~/.config/emacs` | → `config/emacs` |
| `~/.config/starship.toml` | → `config/starship/starship.toml` |
| `~/.config/rumdl/rumdl.toml` | → `config/rumdl/rumdl.toml` |
| iTerm2 Dynamic Profile (macOS only) | → `config/iterm2/dracula.json` |
| `~/.zshrc` | one block that sources `config/zsh/dotfiles.zsh` ([terminal.md](terminal.md#zsh)) |
| `git config core.hooksPath .githooks` | the pre-commit hook runs `test/run.sh static` |
| a warning when `~/.emacs`, `~/.emacs.el` or `~/.emacs.d` exist | move or delete them |

When a target already exists and is not the right link, it is moved to
`<target>.bak.<timestamp>` first; only the three newest backups of each target are kept.
`~/.zshrc` gets the same treatment before it is rewritten, and the older per-feature blocks
(`dotfiles: starship`, `dotfiles: emacs`) are replaced by the single block.

Emacs loads `~/.emacs`, `~/.emacs.el` or `~/.emacs.d/init.el` in preference to
`~/.config/emacs`, so any of those left from an older setup hides this configuration. That is
why the script warns about them.

The pre-commit hook blocks a commit that fails the static checks (formatting, comments in
code, broken Markdown, secrets). `git commit --no-verify` skips it when you must.

## `dotfiles`

`bin/dotfiles` is on `PATH` once the zsh block loads (after `link.sh` and a new shell):

| Command | Does |
|---|---|
| `dotfiles doctor` | Brewfile and groups, `link.sh --check`, `:checkhealth dotfiles`, `aa/doctor`; exit 1 on an error |
| `dotfiles update [nvim\|emacs] [--test]` | update with a backup, then `doctor`; `--test` also runs the tests on the new versions ([maintenance.md](maintenance.md#updating)) |
| `dotfiles rollback nvim\|emacs [backup]` | go back after a bad update |
| `dotfiles backups` | list the Emacs package backups |
| `dotfiles install [--with GROUP]… [--all] [--skip STEP]…` | `install.sh` |
| `dotfiles link [--check\|--uninstall]` | `link.sh` |
| `dotfiles test [level…]` | `test/run.sh` ([testing.md](testing.md)) |

## Brewfile

The `Brewfile` holds what every machine needs; `brew/` holds optional groups.

| File | Contents | Used by |
|---|---|---|
| `Brewfile` | editors: `neovim`, cask `emacs-app` | — |
| | `tree-sitter-cli` (compiles parsers), `node` (npm-based Mason servers) | Neovim |
| | `git`, `git-lfs`, `lazygit` | both editors, shell |
| | `ripgrep`, `fd`, `fzf`, `bat`, `jq`, `coreutils`, `findutils`, `curl`, `wget` | both editors, shell |
| | `prettier`, `shfmt`, `stylua` | Emacs (apheleia), the tests; Neovim gets its own copies from Mason |
| | `rumdl`, `gitleaks` | the tests and the pre-commit hook |
| | `pandoc` (Markdown preview), `aspell` (Emacs spell check) | Markdown, Org |
| | `starship`, casks `iterm2`, `font-jetbrains-mono-nerd-font` | terminal |
| `brew/latex.Brewfile` | casks `mactex`, `skim` | LaTeX |
| `brew/clojure.Brewfile` | `clojure`, `leiningen`, `clojure-lsp`, `clj-kondo` (tap `borkdude/brew`) | both editors |
| `brew/python.Brewfile` | `uv` (Python versions, environments and tools in one program) | shell |
| `brew/ruby.Brewfile` | `ruby` | shell |

`uv` replaces `pyenv` and `pipenv`, which earlier versions of the Brewfile installed: `uv python
install`, `uv venv` and `uv tool install` cover them. Removing them from the Brewfile does not
uninstall them; `brew bundle cleanup` lists them, `--force` removes them.

Every dependency goes in a Brewfile, never only in the docs. `brew bundle check` (with
`--file` for a group) lists what is missing; `dotfiles doctor` checks all of them.
