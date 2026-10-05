# Dotfiles

Personal environment configuration for macOS: **Neovim** (a general-purpose editor with a
complete LaTeX workflow), **Emacs** (Org mode and Clojure, with the same keymaps as Neovim),
**Starship** (prompt) and **iTerm2** (Dracula profile).

## Layout

```text
Brewfile                      programs and fonts (brew bundle)
install.sh                    creates the symlinks and enables starship in zsh
AGENTS.md                     conventions for AI agents working in this repo (CLAUDE.md points to it)
config/
  nvim/                       Neovim >= 0.11
  emacs/                      Emacs >= 29 (Org + Clojure, evil keymaps mirroring nvim)
  starship/starship.toml      two-line prompt, "pill" style, Dracula colors
  rumdl/rumdl.toml            Markdown lint rules (user-level default)
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
3. Open `nvim`. The first time, lazy.nvim installs the plugins (at the versions in
   `lazy-lock.json`), Mason installs the LSP servers/formatters and treesitter compiles the
   parsers (takes a minute or two).
4. Open Emacs (`e` or the app). The first launch installs every package (a few minutes);
   `install.sh` warns if an old `~/.emacs.d` would shadow this config.
5. For LaTeX, set up Skim's inverse search (see [LaTeX](#latex)).

### What `install.sh` does (and doesn't do)

| Does | Doesn't |
|---|---|
| `~/.config/nvim` → `config/nvim` | install programs (that's `brew bundle`) |
| `~/.config/emacs` → `config/emacs` | install Emacs packages (they install on first launch) |
| `~/.config/starship.toml` → `config/starship/starship.toml`, `~/.config/rumdl/rumdl.toml` → `config/rumdl/rumdl.toml` | install nvim plugins (happens when you open `nvim`) |
| iTerm2 profile → `~/Library/Application Support/iTerm2/DynamicProfiles/` | set the iTerm2 profile as default (manual step above) |
| adds a marked block to `~/.zshrc` that runs `starship init zsh` (once) | |
| adds the `e` alias (`emacsclient`, starts a daemon if needed) to `~/.zshrc` (once) | |
| warns if `~/.emacs`, `~/.emacs.el` or `~/.emacs.d` would shadow `~/.config/emacs` | move or delete them |

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

```text
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
  after/lsp/<server>.lua      per-server overrides (lua_ls, basedpyright, jsonls, yamlls, texlab)
  after/ftplugin/tex.lua      buffer options and keymaps for LaTeX
  after/ftplugin/markdown.lua browser preview (pandoc)
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
| `<leader>g` | git | `gg` lazygit · `gv` diff view · `gh` file history · `gs` stage hunk · `gp` preview · `gb` blame · `gl` log · `]c`/`[c` hunks |
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

#### Beamer (slides)

Beamer is a normal LaTeX document class (included in MacTeX), so the same workflow applies:
`,ll` compiles, `,lv` opens the PDF in Skim (View → Presentation for full screen), and
forward/inverse search work per slide. Snippets (completion menu):

| Type | Result |
|---|---|
| `bdoc` | full Beamer preamble + title slide + outline |
| `frm` | `\begin{frame}{…}…\end{frame}` |
| `fimg` | frame with a centered image |
| `col` | two-column layout |
| `blk` / `ablk` | block / alert block |
| `pau` | `\pause` |

### Git diffs

| Keymap | Shows |
|---|---|
| `<leader>gv` | **diff view** (diffview.nvim): every changed file in a side panel, each one side by side; toggles |
| `<leader>gV` | the current branch against `origin/HEAD` (what a PR would contain) |
| `<leader>gh` / `<leader>gH` | history of this file / of the repo, each commit as a diff (in visual mode: history of the selected lines) |
| `<leader>gd` · `<leader>gp` | quick diff of the buffer against the index · preview the hunk under the cursor (gitsigns) |
| `]c` / `[c` | next / previous hunk (also inside the diff view) |

Inside the diff view: `Tab`/`S-Tab` next/previous file, `-` stages or unstages a file in the
panel, `g?` lists every key, `q` closes. With merge conflicts the view opens three columns
(ours · result · theirs): `[x`/`]x` jump between conflicts, `<leader>co`/`ct`/`cb`/`ca` take ours /
theirs / base / all.

Diff colors are tinted backgrounds (green added, red removed, blue changed, brighter blue for
the exact characters that changed), so syntax highlighting stays readable. Removed lines show as
`╱` on the other side. Emacs gets the same keys through magit, with word-level highlighting.

### Markdown

No in-editor rendering: `,p` (in a markdown file) builds an HTML page with **pandoc**
and opens it in the browser. Math written as `$...$`, `$$...$$`, `\(...\)` or `\[...\]` is
rendered as MathML (no internet needed), and images are embedded. After the first `,p`, each
save rebuilds the page; refresh the browser tab (Cmd+R) to see it. Needs `pandoc` (Brewfile).

**rumdl** is the Markdown language server (Rust, single binary from Mason). It lints with
markdownlint-compatible rules as you type (broken relative links and `#anchors` included),
completes file paths and heading anchors inside links, gives `gd`/`gr`/rename on links and an
outline for `<leader>fs`. On save it applies only safe fixes (fence languages, list markers,
spacing) and never rewraps paragraphs. Code actions (`<leader>la`) fix one issue or ignore a
rule for that line. Rules live in `config/rumdl/rumdl.toml` (line length 100); a project's own
`.rumdl.toml` takes precedence.

### LSP, formatting and debug

| Language | LSP | Formatter |
|---|---|---|
| Lua | lua_ls (+ lazydev) | stylua |
| Python | basedpyright + ruff | ruff |
| LaTeX/BibTeX | texlab | latexindent |
| Bash | bashls (+ shellcheck) | shfmt |
| JS/TS/HTML/CSS/JSON/YAML | vtsls, html, cssls, jsonls, yamlls | prettier |
| Markdown | rumdl (lint, links, outline) | rumdl |
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

## Emacs

Emacs for **Org mode** and **Clojure**, using **evil** so the keymaps match the Neovim setup:
`<Space>` is the leader (`C-SPC` in insert state), `,` is the local leader. Needs Emacs ≥ 29
(`brew bundle` installs `emacs-app`). Packages (MELPA/ELPA) install on the first launch,
never from `install.sh` (give it a few minutes).

The repo holds only configuration. Everything generated (packages, native-comp cache, backups,
history, databases) goes to `~/.local/share/emacs` (`early-init.el`, `no-littering`), and
`.gitignore` whitelists just `early-init.el`, `init.el` and `lisp/`.

```text
config/emacs/
  early-init.el               data dir, byte-code only (no native-comp), clean frame
  init.el                     package archives, no-littering, loads lisp/* (failing modules are skipped)
  lisp/
    init-core.el              defaults, macOS (Option = Meta), fonts, sessions
    init-ui.el                Dracula, modeline, vertico/consult/embark/corfu, treemacs, dashboard
    init-evil.el              evil, surround, commentary, avy, evil-org
    init-dev.el               project, eglot (LSP), flymake, format (eglot/apheleia), magit, diff-hl, eat, harpoon
    init-org.el               ~/org layout, TODOs, capture, agenda, babel (incl. Clojure), export
    init-notes.el             org-roam: linked notes and daily notes
    init-clojure.el           clojure-mode, CIDER, clojure-lsp, smartparens
    init-keys.el              every SPC / , keymap (read this to see them all)
```

### Same keys as Neovim

| Neovim | Emacs |
|---|---|
| `<leader>ff` `fg` `fr` `fb` `fk` `fs` `f/` | project files · ripgrep · recent · buffers · bindings · imenu · search in buffer (consult) |
| `<leader>op` `of` | treemacs · reveal file |
| `<leader>l…` `gd` `gr` `gi` `K` | eglot + xref + eldoc (definition, references, rename, code action, format…) |
| `<leader>d…` `]d` `[d` `]e` `[e` | flymake diagnostics |
| `<leader>g…` `]c` `[c` | magit (in place of lazygit and diffview: `gv` diff, `gh`/`gH` history) + diff-hl hunks (stage, reset, preview) |
| `<leader>b…` `w…` `Ctrl-h/j/k/l` `Tab` | buffers · windows · navigation (same keys) |
| `<leader>t…` `Ctrl-\` | terminal (eat) |
| `<leader>m…` | harpoon-style marks, per project (own implementation) |
| `<leader>S…` · `<leader>u…` | sessions · toggles (spell, wrap, numbers, diagnostics, auto-format) |
| `s` `S` · `gsa gsd gsr` · `gc` · `Alt-j/k` | avy jump · surround · comment · move lines |

Differences: `<leader>D` is the **CIDER** debugger/tracer (not DAP); `<leader>lM` lists packages
(no Mason); `<leader>od` opens the dashboard (recent files, projects, today's agenda); `Tab`
cycles headings in Org buffers and switches buffers elsewhere. Extra letters Neovim does not
use: `<leader>a` (agenda), `<leader>i` (capture), `<leader>n` (notes), `<leader>h` (help),
`<leader>.` (embark actions, also `C-.`). `<leader>ug` toggles indent guides.

### Org

Files live in `~/org` (created on first start, nothing overwritten): `inbox.org`, `tasks.org`,
`calendar.org`, `journal.org`, `slides/`, `archive/`.

- **Flow:** capture with `<leader>it` (task), `ie` (event), `in` (note), `ii` (idea), `im`
  (meeting), `ij` (journal); review with `<leader>ai` (inbox), then refile with `,r`.
- **Agenda:** `<leader>ad` day · `aw` week · `an` next actions · `aW` waiting · `ap` projects ·
  `as` stuck projects · `ar` weekly review · `af` open an Org file · `a/` grep in `~/org`.
- **In an Org buffer (`,`):** `t` TODO state · `s` schedule · `d` deadline · `r` refile ·
  `a` archive · `i`/`o` clock in/out · `l` link · `x` checkbox · `e` export · `b` run block ·
  `B` tangle · `v` preview LaTeX · `'` edit block. `TAB` cycles headings; `<leader>uc` shows or
  hides the emphasis markers.
- **Literate Clojure:** `#+begin_src clojure` blocks run through CIDER; jack in first
  (`M-x cider-jack-in` from the `.org` file inside a project). Code evaluation always asks.
- **Linked notes (org-roam):** `<leader>nf` find or create · `ni` insert link · `nb` backlinks ·
  `nc` capture · `nt` today's daily note · `nd` capture into it · `nj` daily note for a date ·
  `na` turn a heading into a node. Notes live in `~/org/notes/`.
- **Slides / PDF:** `,e` opens the export menu (LaTeX/PDF via MacTeX, Beamer with
  `#+latex_class: beamer`).

### Clojure

Needs (Brewfile): `clojure`, `leiningen`, `clojure-lsp`, `clj-kondo`. CIDER handles the REPL and
completion; **clojure-lsp** (via eglot) handles diagnostics, rename, references, code actions
and formatting (on save; `<leader>uf` toggles). Parentheses stay balanced (smartparens strict
mode + evil-smartparens).

In a Clojure buffer, `,` is the CIDER menu: `j` jack-in · `J` cljs jack-in · `c` connect ·
`q` quit · `e e/f/b/r/n` eval sexp/defun/buffer/region/ns · `l` load buffer · `s s` REPL ·
`t t/n/p` test at point/ns/project · `d d` doc · `m` macroexpand · `i` inspect · `R` refresh ns.
Structural: `,>` `,<` slurp/barf forward · `,(` `,)` backward · `,w` wrap · `,u` unwrap · `,^` raise.
Debugger: `<leader>Dd` debug defun · `Dt` trace var · `Di` inspect last result.

### Editor extras

- **Formatting:** LSP buffers (Clojure) format through clojure-lsp; everything else (Markdown, JSON,
  YAML, shell, Lua, JS/TS) goes through apheleia (prettier, shfmt, stylua from the Brewfile).
  `<leader>uf` turns both off; `<leader>lf` formats on demand.
- **embark + wgrep:** `<leader>.` (or `C-.`) acts on the candidate at point; from a `<leader>fg`
  grep, `embark-export` opens the results in a buffer you can edit with wgrep (`C-c C-p`, then
  `C-c C-c` applies the changes to the files).
- **Terminal → Emacs:** `e file` (alias added by `install.sh`) opens the file in the running Emacs.
  If `emacsclient` is not on your PATH, add the `bin` folder inside `Emacs.app/Contents/MacOS`.

### Notes

- A module that fails shows `Module ... failed` in `*Warnings*` and the rest still loads. If a
  key does nothing, `<leader>fk` lists what is bound. Updating, rollback and reset are in
  [Maintenance](#maintenance).
- Native compilation is off on purpose: the macOS clang here rejects its compile flags.
- Spell check needs `aspell` (Brewfile); the dictionary is English (`M-x ispell-change-dictionary`
  switches to `pt_BR`).
- If you ever launched Emacs before this setup, move `~/.emacs.d` away: Emacs prefers it over
  `~/.config/emacs`.

---

## Starship

Two-line prompt, with icons (Nerd Font) and contextual information:

```text
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

### What is pinned and what is not

Everything tracks the latest version. The only thing written down is the state that last
worked, so you can go back to it:

| Part | Updates to | Recorded in | Rollback |
|---|---|---|---|
| Neovim plugins | latest commit (`version = false`) | `config/nvim/lazy-lock.json` (in git) | `git restore` the lock, then `:Lazy restore` |
| Treesitter parsers | revisions chosen by the nvim-treesitter commit | indirectly, by that commit in the lock | same as plugins, then `:TSUpdate` |
| Mason tools (LSP servers, formatters) | latest release | nothing | `:MasonInstall <tool>@<version>` |
| Emacs packages | latest from GNU ELPA / MELPA / NonGNU | nothing (package.el has no lockfile) | restore a backup of `~/.local/share/emacs/elpa` (see below) |
| Programs (Brewfile) | latest Homebrew version | nothing | `brew` cannot downgrade easily; reinstall an older bottle if needed |

Two plugins follow a major version on purpose: `blink.cmp` (`1.*`, releases ship a prebuilt
binary, so no Rust toolchain is needed) and `LuaSnip` (`v2.*`).

### Updating

A routine that keeps a way back (once a month, or whenever you feel like it):

```sh
cd ~/dotfiles && git pull && ./install.sh        # 1. dotfiles (install.sh only matters if links changed)
brew update && brew upgrade                      # 2. programs and casks
rm -rf ~/.local/share/emacs/elpa.bak && cp -a ~/.local/share/emacs/elpa{,.bak}  # 3. Emacs backup, then M-x aa/update-packages
nvim +"Lazy update"                              # 4. Neovim plugins (rewrites lazy-lock.json)
git diff --stat config/nvim/lazy-lock.json       # 5. see which plugins moved
```

Then use both editors for a bit. If everything works, commit the new lock
(`git commit -m "Update Neovim plugins" config/nvim/lazy-lock.json`) and delete
`~/.local/share/emacs/elpa.bak`.

| What | How |
|---|---|
| **These dotfiles** | `git pull`, then `./install.sh` (idempotent) |
| **Programs and CLI tools** | `brew update && brew upgrade` (`--greedy` also upgrades casks that update themselves) |
| **MacTeX** | large; update it on its own with `brew upgrade --cask mactex` |
| **Brewfile changes** | `brew bundle` installs what is new · `brew bundle check` reports what is missing · `brew bundle cleanup` lists what is installed but no longer in the Brewfile (`--force` removes it) |
| **Neovim plugins** | `:Lazy update` (or `U` inside `:Lazy`). lazy.nvim checks for updates in the background without notifying; `:Lazy` shows them |
| **Treesitter parsers** | `:TSUpdate` (also runs after nvim-treesitter updates) |
| **Mason tools** | `:Mason`, then `U`; `:MasonToolsUpdate` for the tools listed in `lsp.lua` |
| **Emacs packages** | `M-x aa/update-packages` (refreshes the index, then `package-upgrade-all`); `<leader>lM` opens the package list (`U` marks upgrades, `x` applies) |
| **Emacs itself** (with built-in Org, eglot, flymake) | `brew upgrade --cask emacs-app`, then restart Emacs |
| **Nerd Font icons in Emacs** | `M-x nerd-icons-install-fonts` (only if symbols look broken) |
| **Starship / iTerm2** | binaries come with `brew upgrade`; their configs are live (`starship.toml`, `dracula.json`), nothing to reload |

### When an update breaks something

**Neovim plugin.** `:Lazy update` has already rewritten the lock, so first bring the old one
back from git, then reinstall those commits:

```sh
git -C ~/dotfiles restore config/nvim/lazy-lock.json   # the last committed (working) lock
nvim +"Lazy restore"                                   # every plugin back to those commits
```

To hold back a single plugin, add `commit = "<sha>"` (or `pin = true`) to its spec until
upstream fixes it, and remove it afterwards.

**Emacs package.** Put the backup back:

```sh
rm -rf ~/.local/share/emacs/elpa && mv ~/.local/share/emacs/elpa{.bak,}
```

Without a backup, reinstalling from scratch (below) gets the current versions, which helps when
the breakage was a half-finished install but not when upstream itself is broken.

### Adding and removing things

- **Neovim plugin:** add a spec in `lua/plugins/` (languages in `lua/plugins/lang/`), open
  `nvim`, and commit the spec together with the updated `lazy-lock.json`. To remove one, delete
  its spec, run `:Lazy clean`, and commit the lock.
- **LSP server or tool:** add it to `mason_servers` / `mason_tools` at the top of
  `lua/plugins/lsp.lua`; overrides go in `after/lsp/<server>.lua`. Tools Mason does not manage
  (like `clojure-lsp`) go in the Brewfile and in `system_servers`.
- **Emacs package:** a `use-package` block in the matching `lisp/init-*.el`; it installs on the
  next start. To remove one, delete the block and run `M-x package-autoremove`.
- **Program:** add it to the `Brewfile` and run `brew bundle`. Keymaps are shared, so a new
  binding in one editor should get its twin in the other (`keymaps.lua` ↔ `init-keys.el`) and
  a line in this README.

### Reset and diagnostics

| | |
|---|---|
| **Neovim from scratch** | `rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim`, then `nvim` (plugins come back at the versions in the lock) |
| **Emacs from scratch** | `rm -rf ~/.local/share/emacs/elpa`, then start Emacs (it reinstalls everything) |
| **Neovim health** | `:checkhealth` · `:Lazy` (failed plugins in red) · `:Mason` · `:ConformInfo` · `:checkhealth vim.lsp` |
| **Emacs health** | `*Warnings*` (a failed module shows `Module ... failed`, the rest still loads) · `C-h e` (messages) · `M-x eglot-events-buffer` |
| **Prompt** | `starship explain` · `starship timings` |
| **Config check** | `bash -n install.sh` · `nvim --headless +qa` (no output means no errors) |

After a big Neovim or Emacs upgrade, run `:checkhealth` and look at `*Warnings*` once.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
