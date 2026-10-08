# Keymaps

`<Space>` is the leader and `,` the local leader in both editors (in Emacs insert state the
leader is `C-SPC`). Press `<Space>` and wait: which-key shows every group and key. `<Space>?`
opens the full panel; `<Space>fk` searches all bindings.

Rules that keep the two editors aligned:

- One leader key per action. Short keys outside the leader (`gd`, `K`, `]d`) may repeat a
  leader action; two leader keys never do the same thing.
- A key present in both editors does the same job. When the tools differ, the job stays the
  same and the table names each implementation.
- Neovim lives in `config/nvim/lua/config/keymaps.lua` (core keys) and in the `keys` of each
  plugin spec; buffer-local LSP keys are in `lua/plugins/lsp.lua`. Emacs keeps every binding
  in `config/emacs/lisp/init-keys.el`.

## Leader groups

### Top level

| Key | Neovim | Emacs |
|---|---|---|
| `<Space>s` | save | save |
| `<Space>q` | quit window (`:q`) | quit window |
| `<Space>Q` | — | quit Emacs |
| `<Space>?` | which-key panel | which-key top level |
| `<Space>.` | — | embark: actions on the thing at point (also `C-.`) |

### `b` buffer

| Key | Neovim | Emacs |
|---|---|---|
| `bb` | list buffers (picker) | list buffers (consult) |
| `bd` | close buffer, keep the window layout | close buffer |
| `bk` | close buffer, discarding changes | close buffer, discarding changes |
| `bn` / `bp` | next / previous buffer (also `Tab` / `S-Tab`) | same |

### `c` code

| Key | Neovim | Emacs |
|---|---|---|
| `cc` | comment line or selection | same |
| `cd` | diagnostics of the current line | same |
| `co` `ct` `cb` `ca` | merge conflict: take ours / theirs / base / all (diffview merge view) | same, in any file with conflict markers (smerge) |

### `d` diagnostics

| Key | Neovim | Emacs |
|---|---|---|
| `dx` | all diagnostics (Trouble) | project diagnostics (flymake) |
| `dd` | buffer diagnostics (Trouble) | buffer diagnostics (flymake) |
| `ds` | symbols outline (Trouble) | — |
| `dl` | location list (Trouble) | — |
| `dq` | quickfix list (Trouble) | compilation errors |
| `dt` | TODO/FIXME/HACK/NOTE in the project (Trouble) | same (ripgrep) |

### `D` debug

The group is the same, the debugger is not: Neovim uses DAP (Python via debugpy), Emacs uses
the CIDER debugger and tracer for Clojure.

| Key | Neovim (DAP) | Emacs (CIDER) |
|---|---|---|
| `Db` / `DB` | toggle / conditional breakpoint | — |
| `Dc` | continue or start | — |
| `Di` `Do` `DO` | step into / over / out | `Di`: inspect last result |
| `Dd` | — | debug the defun at point |
| `Dt` | terminate | trace var |
| `DT` | — | trace namespace |
| `Dr` | toggle REPL | switch to the REPL |
| `De` | evaluate expression (normal and visual) | read and evaluate |
| `Dl` | run last | — |
| `Du` | toggle the DAP UI | — |

### `f` file / find

| Key | Neovim (snacks picker) | Emacs (consult/vertico) |
|---|---|---|
| `ff` | files, smart ranking | files of the project, else of the directory (fd) |
| `fF` | all files | find-file |
| `fg` | live grep | live grep (ripgrep) |
| `fw` | grep word or selection | same |
| `fr` | recent files | same |
| `fc` | files of this config | same |
| `f/` | search in the buffer | same |
| `fs` / `fS` | LSP symbols / workspace symbols | imenu / xref apropos |
| `fd` | diagnostics picker | flymake picker |
| `fh` | help pages | describe symbol |
| `fk` | keymaps | bindings |
| `fu` | undo history | vundo |
| `fC` | colorschemes | themes |
| `fR` | resume the last picker | same |
| `fp` | projects | same |

### `g` git

| Key | Neovim | Emacs |
|---|---|---|
| `gg` | lazygit | magit status |
| `gv` | review every change: file panel + side-by-side diff (toggle) | same (review panel + ediff) |
| `gV` | review everything the branch changed against `origin/HEAD` | same |
| `gd` | this file against the index, side by side | same (ediff) |
| `gc` | every changed hunk (picker with preview) | every change in one magit buffer |
| `gh` | history of this file (visual: of the selected lines) | history of this file |
| `gH` | history of the repository | same |
| `gl` | git log | same |
| `gt` | open a changed file | same |
| `gs` / `gr` | stage / reset hunk | same |
| `gS` / `gR` | stage / reset the whole file | same |
| `gp` | preview hunk | same |
| `gb` / `gB` | blame line / toggle line blame | blame / toggle blame |
| `gO` | open in the browser (GitHub, GitLab…) | same |

Inside a review (`gv`, `gV`) both editors use the same keys: `Tab` / `S-Tab` next / previous
file, `RET` on the panel opens a file, `-` on the panel stages or unstages it, `q` closes the
review.

### `l` LSP

| Key | Neovim | Emacs (eglot) |
|---|---|---|
| `ld` `lr` `li` `lt` | definition / references / implementation / type definition | same |
| `lD` | declaration | same |
| `ln` | rename | same |
| `la` | code action (normal and visual) | same |
| `lh` | hover documentation (also `K`) | documentation buffer (also `K`) |
| `ls` | signature help | same (eldoc) |
| `lf` | format buffer or selection | same |
| `lR` | restart the servers | reconnect |
| `lM` | Mason | package list |

Inside a diff, `ld` `lr` `li` `lt` (and `gd` `gr` `gi`) open a result in another file in a
new tab, so the diff layout survives.

### `m` marks (harpoon)

| Key | Neovim | Emacs |
|---|---|---|
| `ma` | mark the current file | same |
| `mm` | menu of marked files | same |
| `mn` / `mp` | next / previous mark | same |
| `m1` … `m5` | jump to mark 1–5 | same |
| `md` | — (remove from the menu) | remove a mark |

### `o` open

| Key | Neovim | Emacs |
|---|---|---|
| `op` | file tree | file tree (treemacs) |
| `of` | reveal the current file in the tree | same |
| `on` | notification history | messages |
| `od` | dashboard | same |

### `S` session

| Key | Neovim (persistence.nvim, saved automatically) | Emacs (desktop, saved on demand) |
|---|---|---|
| `Sr` | restore the session of this directory | restore the session |
| `Sl` | restore the last session | — |
| `Ss` | pick a session | save the session |
| `Sd` | stop saving this session | delete the saved session |

### `t` terminal

| Key | Neovim | Emacs (eat) |
|---|---|---|
| `tf` | floating terminal | terminal in this window |
| `th` | terminal below | same |
| `tv` | terminal on the right | same |
| `C-\` | toggle the terminal | same |

### `u` UI toggles

| Key | Neovim | Emacs |
|---|---|---|
| `us` | spelling | same (flyspell) |
| `uw` | wrap long lines on screen: on by default, toggles every window and the ones opened later | same, for every buffer |
| `uL` | relative line numbers | same |
| `uc` | conceal | Org emphasis markers |
| `ud` | diagnostics | same |
| `uh` | inlay hints | same (Emacs 30+) |
| `uf` | format on save | same |
| `ug` | indent guides | same |
| `uT` | treesitter highlight | — |
| `un` | dismiss notifications | — |

### `w` window

| Key | Both editors |
|---|---|
| `wh` `wj` `wk` `wl` | move to the window left / below / above / right (also `C-h/j/k/l`) |
| `ww` | next window |
| `wv` / `ws` | split vertically / horizontally |
| `wo` / `wc` | close the other windows / close this one |
| `w=` | balance |
| `wH` `wL` `wJ` `wK` | narrower / wider / shorter / taller |

### Emacs only

| Key | Group |
|---|---|
| `a` | agenda: `aa` menu · `ad` day · `aw` week · `an` next actions · `aW` waiting · `ai` inbox · `ap` projects · `as` stuck · `ar` weekly review · `af` open an Org file · `a/` grep `~/org` |
| `i` | capture: `ic` menu · `it` task · `ie` event · `in` note · `ii` idea · `im` meeting · `ij` journal |
| `n` | notes (org-roam): `nf` find/create · `ni` insert link · `nc` capture · `nb` backlinks · `nt` today · `nd` capture today · `nj` a date · `na` heading → node |
| `h` | help: `hf` function · `hv` variable · `hk` key · `hm` mode · `hb` bindings · `hp` package · `hi` manuals |

## Keys outside the leader

| Key | Action (both editors) |
|---|---|
| `s` / `S` | jump to a location / to a treesitter node (Neovim) or a line (Emacs) |
| `gd` `gr` `gi` `K` | definition / references / implementation / hover |
| `]d` `[d` · `]e` `[e` | next / previous diagnostic · error |
| `]c` `[c` | next / previous git hunk |
| `]t` `[t` | next / previous TODO comment |
| `]x` `[x` | next / previous merge conflict |
| `gsa` `gsd` `gsr` | surround: add / delete / replace |
| `gc` `gcc` | comment |
| `Alt-j` / `Alt-k` | move line or selection |
| `C-h/j/k/l` | move between windows |
| `Tab` / `S-Tab` | next / previous buffer (in Org, `Tab` cycles headings) |
| `]]` `[[` | next / previous reference of the word under the cursor (Neovim) |

Neovim 0.11+ ships `grn`, `grr`, `gra`, `gri`, `grt` and `grx`. They are removed at startup:
`gr` would otherwise wait `timeoutlen` for a longer key, and `<leader>l` already covers them.

## Local leader `,`

| Where | Keys |
|---|---|
| Neovim, `.tex` | `,ll` compile · `,lv` view · `,le` errors · … ([neovim.md](neovim.md#latex)) |
| Neovim, `.md` | `,p` preview in the browser ([neovim.md](neovim.md#markdown)) |
| Emacs, Org | `,t` TODO · `,s` schedule · `,r` refile · … ([emacs.md](emacs.md#init-org)) |
| Emacs, Clojure | `,j` jack-in · `,e…` eval · `,t…` tests · … ([emacs.md](emacs.md#init-clojure)) |
