# Installation

```sh
git clone <repo> ~/dotfiles && cd ~/dotfiles
brew bundle                                  # 1. the programs every machine needs
brew bundle --file brew/latex.Brewfile       #    optional groups, as needed (customizing.md)
./install.sh                                 # 2. links, the ~/.zshrc block, the git hook
dotfiles doctor                              # 3. in a new terminal: is everything in place?
```

Then:

1. Open a **new terminal** so the zsh block loads (prompt, `e`, `dotfiles`).
2. In iTerm2: *Settings → Profiles → "Dotfiles (Dracula)" → Other Actions → Set as Default*.
3. Open `nvim`. The first time, lazy.nvim installs the plugins at the versions in
   `lazy-lock.json`, Mason installs the LSP servers and formatters of the enabled languages,
   and treesitter compiles the parsers. It takes a minute or two.
4. Open Emacs (`e` or the app). The first launch installs every package (a few minutes).
5. For LaTeX, install the `latex` group and set up Skim's inverse search
   ([neovim.md](neovim.md#latex)).
6. Per-machine choices (theme, languages, font size…) go in the local files
   ([customizing.md](customizing.md)).
7. The first time you open a `.tex` or `.md` file, Neovim asks to download the Portuguese
   spell file; answer `y` once (or drop `pt_br` from `spelllang`).

## What `install.sh` does

It only creates links, one marked block in `~/.zshrc` and a git setting. It never installs
programs, plugins or packages, and it is idempotent: running it again changes nothing.

| Mode | Does |
|---|---|
| `./install.sh` | create or repair everything below |
| `./install.sh --check` | print what would change and exit 1 if anything would (nothing is written) |
| `./install.sh --uninstall` | remove the links that point into the repository, the `~/.zshrc` block and the git setting; backups stay |

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

`bin/dotfiles` is on `PATH` once the zsh block loads:

| Command | Does |
|---|---|
| `dotfiles doctor` | Brewfile and groups, `install.sh --check`, `:checkhealth dotfiles`, `aa/doctor`; exit 1 on an error |
| `dotfiles update [nvim\|emacs] [--test]` | update with a backup, then `doctor`; `--test` also runs the tests on the new versions ([maintenance.md](maintenance.md#updating)) |
| `dotfiles rollback nvim\|emacs [backup]` | go back after a bad update |
| `dotfiles backups` | list the Emacs package backups |
| `dotfiles install [--check\|--uninstall]` | `install.sh` |
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
