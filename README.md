# Dotfiles

Personal environment configuration for macOS: **Neovim** (a general-purpose editor with a
complete LaTeX workflow), **Starship** (prompt) and **iTerm2** (Dracula profile).

## Layout

```
Brewfile                      programs and fonts (brew bundle)
install.sh                    creates the symlinks and enables starship in zsh
config/
  nvim/                       Neovim >= 0.11
  starship/starship.toml      two-line prompt, "pill" style, Dracula colors
  iterm2/dracula.json         iTerm2 Dynamic Profile (Dracula colors)
```

## Installation

```sh
git clone <repo> ~/dotfiles && cd ~/dotfiles
brew bundle      # 1. install the programs (neovim, starship, lazygit, MacTeX, Skim, Nerd Font...)
./install.sh     # 2. create the links and hook starship into ~/.zshrc
```

Then:

1. Open a **new terminal** (so Starship loads).
2. In iTerm2: *Settings → Profiles → "Dotfiles (Dracula)" → Other Actions → Set as Default*.
3. Open `nvim`. The first time, lazy.nvim installs the plugins, Mason installs the
   LSP servers/formatters and treesitter compiles the parsers (takes a minute or two).
4. For LaTeX, set up Skim's inverse search (see [LaTeX](#latex)).

### What `install.sh` does (and doesn't do)

| Does | Doesn't |
|---|---|
| `~/.config/nvim` → `config/nvim` | install programs (that's `brew bundle`) |
| `~/.config/starship.toml` → `config/starship/starship.toml` | install nvim plugins (happens when you open `nvim`) |
| iTerm2 profile → `~/Library/Application Support/iTerm2/DynamicProfiles/` | set the iTerm2 profile as default (manual step above) |
| adds a marked block to `~/.zshrc` that runs `starship init zsh` (once) | |

It is idempotent: you can run it again without duplicating anything. If a target already
exists and is not the correct link, it is moved to `<target>.bak.<timestamp>` before the
link is created.

External requirements for Neovim: a **Nerd Font** in the terminal, `git`, `rg`, `fd`, `node`
(some Mason servers), `tree-sitter-cli` + a C compiler (parsers), `lazygit`
(optional), **MacTeX** (`latexmk`, `latexindent`, `chktex`) and **Skim** for LaTeX.
All of this comes from the Brewfile; use `:checkhealth` to diagnose anything missing.

---

## Neovim

Modular configuration for **Neovim ≥ 0.11** (tested on 0.12): a general-purpose editor (LSP,
completion, git, debug, picker, explorer, integrated terminal) with a complete LaTeX
workflow. Leader = `<Space>`, localleader = `,`.

### Structure

```
config/nvim/
  init.lua                    entry point (checks version, loads config/*)
  lua/config/
    options.lua               options and leaders
    keymaps.lua               "core" keymaps (windows, buffers, diagnostics...)
    autocmds.lua              yank highlight, restore cursor, spell/wrap for prose...
    lazy.lua                  lazy.nvim bootstrap
  lua/plugins/                one spec per topic
    snacks.lua                picker, explorer, terminal, lazygit, dashboard, notifications
    completion.lua            blink.cmp + LuaSnip
    lsp.lua                   nvim-lspconfig + mason (server/tool list at the top)
    formatting.lua            conform.nvim
    treesitter.lua            nvim-treesitter (main branch)
    editor.lua                gitsigns, flash, harpoon, mini.{ai,surround,pairs}, trouble, todo, sessions
    debug.lua                 nvim-dap (+ UI, debugpy)
    ui.lua / colorscheme.lua  lualine, which-key, icons, Dracula
    lang/tex.lua              vimtex
    lang/markdown.lua         render-markdown
  after/lsp/<server>.lua      per-server overrides (lua_ls, basedpyright, jsonls, yamlls, texlab)
  after/ftplugin/tex.lua      buffer options and keymaps for LaTeX
  snippets/tex.lua            LaTeX snippets (LuaSnip)
```

### Discovering keymaps

- Press `<Space>` and wait: which-key shows the groups and, inside them, every keymap.
- `<Space>?` opens the keymap panel; `<Space>fk` searches all keymaps.
- In a `.tex` file the same applies to `,` (vimtex keymaps).

### Keymaps (`<Space>` = leader)

| Prefix | Group | Examples |
|---|---|---|
| `<leader>f` | file/find (snacks picker) | `ff` files · `fg` grep · `fr` recent · `fb` buffers · `fc` config · `fk` keymaps · `fs` symbols · `fR` resume |
| `<leader>o` | open | `op` explorer · `of` reveal current file · `on` notification history |
| `<leader>l` | lsp | `ld` definition · `lr` references · `ln` rename · `la` code action · `lf` format · `ll` diagnostics |
| `<leader>d` | diagnostics (Trouble) | `dx` · `dd` buffer · `dq` quickfix · `dt` TODOs |
| `<leader>g` | git | `gg` lazygit · `gs` stage hunk · `gp` preview · `gb` blame · `gl` log · `]c`/`[c` hunks |
| `<leader>b` / `w` | buffer / window | `bd` close buffer · `bb` list · `wv`/`ws` splits · `Ctrl-h/j/k/l` navigate |
| `<leader>t` | terminal | `tf` float · `th` horizontal · `tv` vertical · `Ctrl-\` toggle |
| `<leader>m` | harpoon | `ma` add · `mm` menu · `m1…m5` jump |
| `<leader>D` | debug (DAP) | `Db` breakpoint · `Dc` continue · `Di/Do/DO` step · `Du` UI |
| `<leader>S` | sessions | `Sr` restore · `Sl` last |
| `<leader>u` | toggles | `us` spell · `uw` wrap · `uc` conceal · `uf` auto-format · `uh` inlay hints |
| `s` / `S` | flash | quick jump / treesitter selection |
| `gsa gsd gsr` | surround | add / delete / replace |

### LaTeX

Workflow: **vimtex** compiles (continuous latexmk) and opens the PDF in **Skim** with SyncTeX;
**texlab** provides completion (`\cite`, `\ref`, commands), diagnostics (chktex), rename and
go-to-definition; **LuaSnip** expands math snippets; **latexindent** formats.

Keymaps in `.tex` files (`<localleader>` = `,`):

| Keymap | Action |
|---|---|
| `,ll` | toggle continuous compilation (latexmk) |
| `,lv` | open/refresh the PDF and run forward search |
| `,le` / `,lo` / `,lg` | errors / latexmk output / status |
| `,lt` / `,lT` | table of contents (TOC) / toggle |
| `,lc` / `,lC` | clean auxiliary files / + PDF |
| `,lw` | word count |
| `<leader>lf` | format with latexindent (deliberately not run on save) |
| `<leader>uc` | toggle conceal (rendered symbols) |

vimtex editing: `dse`/`cse` (environment), `dsc`/`csc` (command), `ie`/`ae` (environment),
`i$`/`a$` (inline math), `tsf` (toggle fraction), `]]`/`[[` (sections).

**Skim → Neovim (inverse search, Cmd+Shift+click on the PDF):** in
*Skim → Preferences → Sync* choose *Custom*, *Command* `nvim` and *Arguments*
`--headless -c "VimtexInverseSearch %line '%file'"`.

**Another engine** (lualatex/xelatex): first line of the file `% !TEX program = lualatex`.
For `minted`/`-shell-escape`, create a `.latexmkrc` in the project with
`$pdflatex = 'pdflatex -shell-escape %O %S';`.

#### Snippets (`snippets/tex.lua`)

Autosnippets (expand by themselves):

| Context | Type | Result |
|---|---|---|
| text | `mk` · `dm` · `beg` | `$…$` · `\[…\]` · `\begin{…}…\end{…}` |
| math | `a//` · `(a+b)//` | `\frac{a}{}` · `\frac{a+b}{}` |
| math | `x2` · `__` · `td` · `sr` · `cb` | `x_2` · `_{}` · `^{}` · `^2` · `^3` |
| math | `;a` `;b` `;G` `;o`… | `\alpha` `\beta` `\Gamma` `\omega`… |
| math | `->` `=>` `<=` `!=` `...` `xx` `ooo` | `\to` `\implies` `\leq` `\neq` `\dots` `\times` `\infty` |
| math | `sum` `int` `lim` `part` `sq` `lr(` | summation, integral, limit, partial derivative, root, `\left( \right)` |
| math | `RR` `NN` `ZZ` `QQ` `CC` | `\mathbb{R}`… |

Snippets via the completion menu: `eqn`, `ali`, `thm`, `prf`, `ite`, `enu`, `fig`, `tab`,
`sec`/`ssec`, `cit`, `ref`, `eqr`, `doc` (full preamble)… Add your own in
`snippets/tex.lua` (or create `snippets/<filetype>.lua`).

### LSP, formatting and debug

| Language | LSP | Formatter |
|---|---|---|
| Lua | lua_ls (+ lazydev) | stylua |
| Python | basedpyright + ruff | ruff |
| LaTeX/BibTeX | texlab | latexindent |
| Bash | bashls (+ shellcheck) | shfmt |
| JS/TS/HTML/CSS/JSON/YAML/MD | vtsls, html, cssls, jsonls, yamlls, marksman | prettier |
| TOML · C/C++ | taplo · clangd | LSP |
| Clojure | clojure-lsp (from the Brewfile; enabled if on PATH) | LSP |

To add a server: add its name to `mason_servers` (top of `lua/plugins/lsp.lua`)
and, if it needs tweaks, create `after/lsp/<name>.lua`. Formatters live in `formatting.lua`.
Auto-format on save: `<leader>uf` (global) or `:FormatToggle!` (current buffer only).

### Notes

- The first time you open a `.tex`/`.md` file, Neovim offers to download the dictionaries
  (`en`, `pt`) for spell checking.
- Treesitter parsers are compiled locally on the first run.

---

## Starship

Two-line prompt, with icons (Nerd Font) and contextual information:

```
(mac) (~/dotfiles) (main !1 ?2) +4 (py 3.13) ───────────────── 3s  11:10
❯
```

(Each item in parentheses is a colored "pill" with an icon.)

- **Line 1:** OS, directory, git branch with status (`!` modified, `?` untracked,
  `+` staged, `⇡⇣` ahead/behind) and added/removed lines, versions of
  Python/Node/Lua/Ruby/Rust/Go/Java/C (only when the directory is that kind of project); on
  the right, duration of commands longer than 2 s and the time.
- **Line 2:** user/host (only over ssh or as root), sudo, background jobs, error code and
  the `❯` (red when the last command failed).
- To customize: edit `config/starship/starship.toml`. Colors are in
  `[palettes.dracula]` and each module has its own `format`/`symbol`. Icons are written as
  `\uXXXX` escapes, so the file is plain ASCII.

## iTerm2

`config/iterm2/dracula.json` is a **Dynamic Profile**: iTerm2 reads the file on its own and
shows the "Dotfiles (Dracula)" profile. It inherits the *Default* profile (including the font) and
only changes:

- Dracula palette (16 ANSI colors, background, cursor, selection)
- *Option* as Meta/Esc+ (required for Neovim's `Alt-j/k` keymaps)
- bar cursor, slight transparency with blur, 140×40, 100k-line scrollback

The font must be a **Nerd Font** for the prompt and Neovim icons to show up
(the Brewfile installs JetBrainsMono Nerd Font). To change the font, set it in the profile
inside iTerm2 or add `"Normal Font"` to the JSON.

## Maintenance

- **Update programs:** `brew update && brew upgrade`
- **Update nvim plugins:** `:Lazy update` (the `lazy-lock.json` lockfile is in
  `.gitignore`; remove the `**/lazy-lock.json` line to version it and get
  reproducible versions across machines)
- **Clean nvim install:** `rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim`
- **Diagnostics:** `:checkhealth` in Neovim · `starship explain` in the shell

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
