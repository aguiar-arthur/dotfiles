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

`bin/dotfiles` (on `PATH` through the zsh block) wraps the routine and keeps a way back:

```sh
cd ~/dotfiles && git pull && ./link.sh
brew update && brew upgrade
dotfiles update
```

`dotfiles update` (or `dotfiles update nvim` / `dotfiles update emacs`):

1. runs `:Lazy sync` headless and shows which plugins moved in `lazy-lock.json`;
2. backs up `~/.local/share/emacs/elpa` to `elpa.bak.<date>` (the newest three are kept),
   refreshes the package index and upgrades every package (`aa/update-packages`);
3. runs `dotfiles doctor`, and on a failure prints the rollback commands.

Use both editors for a while. If everything works, commit the new lock
(`git commit -m "Update Neovim plugins" config/nvim/lazy-lock.json`).

Nothing updates on its own; you decide when. `dotfiles update --test` also runs
`test/run.sh smoke keys behavior` against the new versions before telling you to commit the
lock ([testing.md](testing.md)).

| What | How |
|---|---|
| **These dotfiles** | `git pull`, then `./link.sh` (`./link.sh --check` shows what it would change); `./install.sh` when the Brewfile or the languages changed |
| **Programs and CLI tools** | `brew update && brew upgrade` (`--greedy` also upgrades casks that update themselves) |
| **MacTeX** | large; update it on its own with `brew upgrade --cask mactex` |
| **Brewfile changes** | `brew bundle` installs what is new · `brew bundle check` reports what is missing · `brew bundle cleanup` lists what is no longer listed (`--force` removes it); the groups in `brew/` take `--file brew/<group>.Brewfile` |
| **Neovim plugins** | `dotfiles update nvim`, or `:Lazy update` (`U` in `:Lazy`) |
| **Treesitter parsers** | `:TSUpdate` (also runs after nvim-treesitter updates) |
| **Mason tools** | `:Mason`, then `U`; `:MasonToolsUpdate` for the tools of the enabled languages |
| **Emacs packages** | `dotfiles update emacs`, or `M-x aa/update-packages` (backup, refresh, upgrade); `SPC l M` opens the package list |
| **Emacs itself** | `brew upgrade --cask emacs-app`, then restart Emacs |
| **Nerd Font icons in Emacs** | `M-x nerd-icons-install-fonts` (only if symbols look broken) |
| **Starship / iTerm2** | binaries come with `brew upgrade`; their configs are live |

Emacs never downloads the package index at startup (a slow server used to freeze it): the
index is refreshed by `aa/update-packages`, by the package list, and automatically when a
package is missing.

## When an update breaks something

| Editor | Command | What it does |
|---|---|---|
| Neovim | `dotfiles rollback nvim` | `git restore config/nvim/lazy-lock.json`, then `:Lazy restore`: back to the committed versions |
| Emacs | `dotfiles rollback emacs` | moves `elpa` aside to `elpa.broken.<date>` and copies the newest backup in; restart Emacs |
| Emacs | `dotfiles rollback emacs elpa.bak.<date>` | the same with an older backup (`dotfiles backups` lists them) |
| Emacs | `M-x aa/rollback-packages` | the same from inside Emacs, choosing the backup |

To hold back one Neovim plugin, add `commit = "<sha>"` (or `pin = true`) to its spec until
upstream fixes it, and remove it afterwards. Without an Emacs backup, reinstalling from scratch
(below) gets the current versions: that fixes a half-finished install, not a broken upstream
release.

## Adding and removing things

- **Neovim plugin:** a spec in `lua/plugins/` (languages in `lua/plugins/lang/`). Open
  `nvim` and commit the spec with the updated `lazy-lock.json`. To remove one, delete the
  spec, run `:Lazy clean` and commit the lock.
- **LSP server or tool:** add it to the language's entry in the `catalog` of
  `lua/config/settings.lua` (`servers`, `tools`, `parsers`, `executables`, or `system` for
  servers Mason does not manage, like clojure-lsp); settings go in `after/lsp/<server>.lua`.
  `./install.sh --skip brew --skip emacs` installs what is new. A new language
  also gets a key in `defaults.languages` ([customizing.md](customizing.md)).
- **Emacs package:** a `use-package` block in the matching `lisp/init-*.el`; it installs on
  the next start. To remove one, delete the block and run `M-x package-autoremove`.
- **Program:** the `Brewfile` when every machine needs it, a group in `brew/` otherwise; then
  `brew bundle`. Add it to `aa/doctor-executables` and the lists in `lua/dotfiles/health.lua`
  so the health reports look for it.
- **Key:** add it to both editors (`keymaps.lua` or the plugin spec ↔ `init-keys.el`) and to
  [keymaps.md](keymaps.md).

Every change that adds or changes behaviour updates the matching page in `docs/` and
`CHANGELOG.md`.

## Health and diagnostics

Start with the health reports; each line is `ok`, `info`, `WARN` or `ERROR` and says what to
run.

| Where | Command |
|---|---|
| Shell, everything | `dotfiles doctor`: Brewfile and groups, links and zsh block, both editors; exits 1 on an error |
| Neovim | `<Space>oh` (`:checkhealth dotfiles`): version, settings and `local.lua`, programs, plugins against the lock, Mason, fonts, spell files |
| Emacs | `SPC o h` (`M-x aa/doctor`): version, failed modules and `local.el`, theme, programs, font, packages, index age, backups |

Emacs also says it at startup when a module or `local.el` failed: "N part(s) of the
configuration failed at startup … SPC o h shows the details".

| | |
|---|---|
| **Neovim from scratch** | `rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim`, then `nvim` (plugins return at the versions in the lock) |
| **Emacs from scratch** | `rm -rf ~/.local/share/emacs/elpa`, then start Emacs (it reinstalls everything) |
| **Neovim, deeper** | `:checkhealth` · `:Lazy` (failed plugins in red) · `:Mason` · `:ConformInfo` · `:checkhealth vim.lsp` |
| **Neovim logs** | `~/.local/state/nvim/lsp.log` (language servers), `:messages` |
| **Emacs, deeper** | `*Warnings*` · `C-h e` (messages) · `M-x eglot-events-buffer` |
| **Emacs frozen at startup** | `emacs --debug-init`; if it stops at "Contacting host", the network is the problem |
| **Prompt** | `starship explain` · `starship timings` |
| **Configuration** | `test/run.sh` ([testing.md](testing.md)) |
