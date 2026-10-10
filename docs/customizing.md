# Customizing

Each editor reads its defaults from one settings file in the repository and then an optional
**local file** that git ignores. Put per-machine changes in the local file: the repository
stays the same on every machine, and `git pull` never conflicts with them.

| | Neovim | Emacs |
|---|---|---|
| Defaults | `config/nvim/lua/config/settings.lua` | `config/emacs/lisp/init-settings.el` |
| Local file | `config/nvim/lua/config/local.lua` | `config/emacs/local.el` |
| Format | returns a table merged into the defaults | Lisp run after the defaults, before the modules |
| A broken local file | a notification; the defaults stay; `<Space>oh` shows the error | a startup message and a warning; `SPC o h` shows the error |

Both files are optional. `<Space>oh` / `SPC o h` say whether one was loaded.

## Neovim

```lua
return {
  colorscheme = "habamax",
  wrap = false,
  format_on_save = false,
  spelllang = { "en_us" },
  languages = { tex = false, clojure = false, web = false },
}
```

| Key | Default | Effect |
|---|---|---|
| `colorscheme` | `"dracula"` | any installed colorscheme; an unknown name warns and falls back to Dracula |
| `wrap` | `true` | wrap long lines on screen at startup (`<Space>uw` still toggles) |
| `format_on_save` | `true` | initial state of `<Space>uf` |
| `spelllang` | `{ "en_us", "pt_br" }` | spelling languages; dropping `pt_br` also skips its download prompt |
| `languages` | all `true` | turning one off drops its servers and tools from Mason, its programs from the health report and, for `tex`, the vimtex plugin |

The language catalog in `settings.lua` says what each language brings:

| Language | Servers (Mason) | Tools (Mason) | Programs checked |
|---|---|---|---|
| `lua` | lua_ls | stylua | |
| `python` | basedpyright, ruff | | |
| `shell` | bashls | shfmt, shellcheck | |
| `tex` | texlab | | latexmk |
| `json`, `yaml` | jsonls, yamlls | prettier | |
| `toml` | taplo | | |
| `markdown` | rumdl | | |
| `web` | html, cssls, vtsls | prettier | |
| `c` | clangd | | |
| `clojure` | clojure_lsp (from the Brewfile group) | | clojure-lsp |

Tables merge deeply, so `languages = { tex = false }` keeps the other languages on. Turning a
language off does not uninstall what Mason already installed: `:Mason` removes it.

## Emacs

```elisp
(setq aa/theme 'modus-vivendi
      aa/font-height 150
      aa/wrap nil
      aa/autoformat nil
      aa/languages nil)
```

| Variable | Default | Effect |
|---|---|---|
| `aa/theme` | `dracula` | theme loaded at startup; dracula-theme is installed only when it is chosen |
| `aa/font-family` / `aa/variable-font-family` | JetBrainsMono Nerd Font Mono / JetBrainsMono Nerd Font | used when installed (GUI frames) |
| `aa/font-height` | `130` | 1/10 pt |
| `aa/wrap` | `t` | wrap long lines on screen (`SPC u w` still toggles) |
| `aa/autoformat` | `t` | format on save (`SPC u f` still toggles) |
| `aa/languages` | `(clojure)` | without `clojure`, `init-clojure` is not loaded and its programs are not checked |
| `aa/doctor-executables` | see the file | programs `aa/doctor` looks for |
| `aa/package-backups` | `3` | package backups `aa/update-packages` keeps |

All of them are `defcustom`s in the `aa` group, so `M-x customize-group RET aa` also works;
those choices land in `custom.el` under `~/.local/share/emacs/etc/`, outside the repository.

## Shell

`config/zsh/dotfiles.zsh` is what the `~/.zshrc` block sources ([terminal.md](terminal.md#zsh)).
Anything personal stays in `~/.zshrc` itself, outside the marked block.

## Programs

The `Brewfile` has what every machine needs; optional groups live in `brew/`:

```sh
brew bundle                                  # base
brew bundle --file brew/latex.Brewfile       # MacTeX and Skim (several GB)
brew bundle --file brew/clojure.Brewfile     # clojure, leiningen, clojure-lsp, clj-kondo
brew bundle --file brew/python.Brewfile      # uv
brew bundle --file brew/ruby.Brewfile        # ruby
```

Turn the matching language off in the local files when a group is not installed, so the
health reports do not warn about it.
