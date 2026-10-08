# Installation

```sh
git clone <repo> ~/dotfiles && cd ~/dotfiles
brew bundle      # 1. install every program (neovim, emacs, starship, MacTeX, Skim, fonts...)
./install.sh     # 2. create the links and the ~/.zshrc blocks
```

Then:

1. Open a **new terminal** so Starship loads.
2. In iTerm2: *Settings → Profiles → "Dotfiles (Dracula)" → Other Actions → Set as Default*.
3. Open `nvim`. The first time, lazy.nvim installs the plugins at the versions in
   `lazy-lock.json`, Mason installs the LSP servers and formatters, and treesitter compiles
   the parsers. It takes a minute or two.
4. Open Emacs (`e` or the app). The first launch installs every package (a few minutes).
5. For LaTeX, set up Skim's inverse search ([neovim.md](neovim.md#latex)).
6. The first time you open a `.tex` or `.md` file, Neovim asks to download the Portuguese
   spell file; answer `y` once.

## What `install.sh` does

It only creates links and adds marked blocks to `~/.zshrc`. It never installs programs,
plugins or packages, and it is idempotent: running it again changes nothing.

| Does | Doesn't |
|---|---|
| `~/.config/nvim` → `config/nvim` | install programs (that is `brew bundle`) |
| `~/.config/emacs` → `config/emacs` | install Emacs packages (first launch does it) |
| `~/.config/starship.toml` → `config/starship/starship.toml` | install Neovim plugins (first `nvim` does it) |
| `~/.config/rumdl/rumdl.toml` → `config/rumdl/rumdl.toml` | set the iTerm2 profile as default (manual step above) |
| iTerm2 profile → `~/Library/Application Support/iTerm2/DynamicProfiles/` (macOS only) | |
| a marked block in `~/.zshrc` that runs `starship init zsh` | |
| a marked block in `~/.zshrc` with the `e` alias (`emacsclient -n -c -a ""`) | |
| a warning when `~/.emacs`, `~/.emacs.el` or `~/.emacs.d` exist | move or delete them |

When a target already exists and is not the right link, it is moved to
`<target>.bak.<timestamp>` before the link is created. The `~/.zshrc` blocks are delimited by
`# >>> dotfiles: … >>>` / `# <<< dotfiles: … <<<` lines and are added only when the opening
marker is missing.

Emacs loads `~/.emacs`, `~/.emacs.el` or `~/.emacs.d/init.el` in preference to
`~/.config/emacs`, so any of those left from an older setup hides this configuration. That is
why the script warns about them.

## Brewfile

| Group | Formulae / casks | Used by |
|---|---|---|
| Editors | `neovim`, cask `emacs-app` | — |
| Neovim tooling | `tree-sitter-cli` (compiles parsers), `node` (npm-based Mason servers) | Neovim |
| Search and files | `ripgrep`, `fd`, `fzf`, `bat`, `coreutils`, `findutils`, `jq` | both editors, shell |
| Git | `git-lfs`, `lazygit` | Neovim (`<leader>gg`) |
| Formatters for Emacs | `prettier`, `shfmt`, `stylua` | Emacs (apheleia); Neovim gets its own copies from Mason |
| Markdown lint | `rumdl` | the shell and agents (`rumdl check docs`); Neovim gets its own copy from Mason |
| Writing | `pandoc` (Markdown preview), `aspell` (Emacs spell check), casks `mactex`, `skim` | LaTeX, Markdown, Org |
| Clojure | `clojure`, `leiningen`, `clojure-lsp`, `clj-kondo` (tap `borkdude/brew`) | both editors |
| Python, Ruby | `pyenv`, `pipenv`, `ruby` | shell |
| Prompt and terminal | `starship`, casks `iterm2`, `font-jetbrains-mono-nerd-font` | terminal |
| Network | `curl`, `wget` | shell |

Every dependency goes in the Brewfile, never only in the docs. `brew bundle check` lists what
is missing on the current machine.
