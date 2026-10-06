# Maintenance

## What is pinned and what is not

Everything tracks the latest version. The only thing written down is the state that last
worked, so you can go back to it:

| Part | Updates to | Recorded in | Rollback |
|---|---|---|---|
| Neovim plugins | latest commit (`version = false`) | `config/nvim/lazy-lock.json` (in git) | `git restore` the lock, then `:Lazy restore` |
| Treesitter parsers | revisions chosen by the nvim-treesitter commit | indirectly, by that commit in the lock | same as plugins, then `:TSUpdate` |
| Mason tools (LSP servers, formatters) | latest release | nothing | `:MasonInstall <tool>@<version>` |
| Emacs packages | latest from GNU ELPA / MELPA / NonGNU | nothing (package.el has no lockfile) | restore a backup of `~/.local/share/emacs/elpa` |
| Programs (Brewfile) | latest Homebrew version | nothing | reinstall an older bottle if needed |

Two plugins follow a major version on purpose: `blink.cmp` (`1.*`, releases ship a prebuilt
binary, so no Rust toolchain is needed) and `LuaSnip` (`v2.*`).

The lock does not pin anything: `:Lazy update` still moves every plugin to its latest commit
and rewrites the lock. A fresh machine installs exactly the versions in the committed lock.

## Updating

A routine that keeps a way back:

```sh
cd ~/dotfiles && git pull && ./install.sh
brew update && brew upgrade
rm -rf ~/.local/share/emacs/elpa.bak && cp -a ~/.local/share/emacs/elpa{,.bak}
nvim +"Lazy update"
git diff --stat config/nvim/lazy-lock.json
```

1. Update the dotfiles (`install.sh` only matters when links or zshrc blocks changed).
2. Update programs and casks.
3. Back up the Emacs packages, then run `M-x aa/update-packages` in Emacs.
4. Update the Neovim plugins.
5. See which plugins moved.

Use both editors for a while. If everything works, commit the new lock
(`git commit -m "Update Neovim plugins" config/nvim/lazy-lock.json`) and delete
`~/.local/share/emacs/elpa.bak`.

| What | How |
|---|---|
| **These dotfiles** | `git pull`, then `./install.sh` |
| **Programs and CLI tools** | `brew update && brew upgrade` (`--greedy` also upgrades casks that update themselves) |
| **MacTeX** | large; update it on its own with `brew upgrade --cask mactex` |
| **Brewfile changes** | `brew bundle` installs what is new · `brew bundle check` reports what is missing · `brew bundle cleanup` lists what is no longer listed (`--force` removes it) |
| **Neovim plugins** | `:Lazy update` (or `U` in `:Lazy`); `:Lazy` shows pending updates |
| **Treesitter parsers** | `:TSUpdate` (also runs after nvim-treesitter updates) |
| **Mason tools** | `:Mason`, then `U`; `:MasonToolsUpdate` for the tools listed in `lsp.lua` |
| **Emacs packages** | `M-x aa/update-packages` (refreshes the index, then upgrades all); `SPC l M` opens the package list (`U` marks upgrades, `x` applies) |
| **Emacs itself** | `brew upgrade --cask emacs-app`, then restart Emacs |
| **Nerd Font icons in Emacs** | `M-x nerd-icons-install-fonts` (only if symbols look broken) |
| **Starship / iTerm2** | binaries come with `brew upgrade`; their configs are live |

Emacs never downloads the package index at startup (a slow server used to freeze it): the
index is refreshed by `aa/update-packages`, by the package list, and automatically when a
package is missing.

## When an update breaks something

**Neovim plugin.** `:Lazy update` has already rewritten the lock, so bring the old one back
from git first, then reinstall those commits:

```sh
git -C ~/dotfiles restore config/nvim/lazy-lock.json
nvim +"Lazy restore"
```

To hold back one plugin, add `commit = "<sha>"` (or `pin = true`) to its spec until upstream
fixes it, and remove it afterwards.

**Emacs package.** Put the backup back:

```sh
rm -rf ~/.local/share/emacs/elpa && mv ~/.local/share/emacs/elpa{.bak,}
```

Without a backup, reinstalling from scratch (below) gets the current versions: that fixes a
half-finished install, not a broken upstream release.

## Adding and removing things

- **Neovim plugin:** a spec in `lua/plugins/` (languages in `lua/plugins/lang/`). Open
  `nvim` and commit the spec with the updated `lazy-lock.json`. To remove one, delete the
  spec, run `:Lazy clean` and commit the lock.
- **LSP server or tool:** add it to `mason_servers` / `mason_tools` in `lua/plugins/lsp.lua`;
  settings go in `after/lsp/<server>.lua`. Tools Mason does not manage (like clojure-lsp) go
  in the Brewfile and in `system_servers`.
- **Emacs package:** a `use-package` block in the matching `lisp/init-*.el`; it installs on
  the next start. To remove one, delete the block and run `M-x package-autoremove`.
- **Program:** add it to the `Brewfile` and run `brew bundle`.
- **Key:** add it to both editors (`keymaps.lua` or the plugin spec ↔ `init-keys.el`) and to
  [keymaps.md](keymaps.md).

Every change that adds or changes behaviour updates the matching page in `docs/`.

## Reset and diagnostics

| | |
|---|---|
| **Neovim from scratch** | `rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim`, then `nvim` (plugins return at the versions in the lock) |
| **Emacs from scratch** | `rm -rf ~/.local/share/emacs/elpa`, then start Emacs (it reinstalls everything) |
| **Neovim health** | `:checkhealth` · `:Lazy` (failed plugins in red) · `:Mason` · `:ConformInfo` · `:checkhealth vim.lsp` |
| **Neovim logs** | `~/.local/state/nvim/lsp.log` (language servers), `:messages` |
| **Emacs health** | `*Warnings*` (a failed module shows `Module … failed`) · `C-h e` (messages) · `M-x eglot-events-buffer` |
| **Emacs frozen at startup** | `emacs --debug-init`; if it stops at "Contacting host", the network is the problem |
| **Prompt** | `starship explain` · `starship timings` |
| **Config check** | `bash -n install.sh` · `nvim --headless +qa` (no output means no errors) |

After a big Neovim or Emacs upgrade, run `:checkhealth` and look at `*Warnings*` once.
