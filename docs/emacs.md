# Emacs

Emacs for **Org mode** and **Clojure**, with **evil** so the keys match Neovim
([keymaps.md](keymaps.md)). Needs Emacs ≥ 29.1 (the Brewfile installs the `emacs-app` cask;
tested on 31.1).

## Structure

```text
config/emacs/
  early-init.el        data directory, package directory, native compilation off, clean frame
  init.el              package archives, use-package, no-littering, module loader
  lisp/
    init-core.el       defaults, macOS, PATH, fonts, sessions, window resizing
    init-ui.el         theme, icons, modeline, which-key, minibuffer, completion, file tree, dashboard
    init-evil.el       evil and its companions
    init-dev.el        projects, search, LSP, diagnostics, formatting, git, diffs, terminal, marks
    init-org.el        ~/org layout, TODO flow, capture, agenda, babel, export
    init-notes.el      org-roam
    init-clojure.el    clojure-mode, CIDER, clojure-lsp, structural editing
    init-keys.el       every SPC and `,` binding
```

Each `.el` file starts with `;;; -*- lexical-binding: t -*-`. That line is required (it turns
on lexical scoping, and Emacs 31 warns without it) and is the only comment allowed in the
code.

## Startup

**early-init.el** runs before packages and the first frame:

- garbage collection is suspended during startup (`init.el` sets 64 MB afterwards);
- `aa/data-dir` = `$XDG_DATA_HOME/emacs/` (normally `~/.local/share/emacs/`) holds everything
  Emacs generates; `package-user-dir` points to its `elpa/`, and the native-compilation cache
  to `eln-cache/`;
- native compilation is off: with the macOS toolchain of this setup clang rejects
  `-mmacosx-version-min=…`, so Emacs stays on byte-code. JIT compilation and subr trampolines
  are both disabled; evil advises the primitive `select-window`, which would trigger a
  trampoline;
- no tool bar or scroll bars, no implied frame resizing, no startup screen.

**init.el**:

- refuses to start on Emacs older than 29.1;
- keeps the configuration directory in `aa/config-dir` and then points
  `user-emacs-directory` at the data directory, so anything that still writes "next to the
  config" writes outside the repository;
- package archives GNU, NonGNU and MELPA with priorities GNU 10, MELPA 5, NonGNU 1. NonGNU's
  index sometimes lists tarballs its server no longer has, so it ranks last;
  built-in packages are not upgraded from the archives;
- **no index refresh at startup.** Refreshing downloads the three indexes synchronously, and a
  slow or silent server froze Emacs at "Contacting host". use-package refreshes the index by
  itself when a package is missing (first launch, new package); `M-x aa/update-packages`
  refreshes it when you upgrade;
- `use-package-always-ensure`: every package installs on first use;
- **no-littering** sends history, caches and databases to `aa/data-dir` (`etc/`, `var/`) and
  backups there too; `custom.el` lives in `etc/`;
- modules load through `aa/load-module`: a module that fails shows
  `Module … failed` in `*Warnings*` and the rest still load. Order: core, ui, evil, dev, org,
  notes, clojure, keys. A module may use the ones before it, never the ones after.

## Modules

### init-core

- Short answers, no bell, no lock files, trash instead of delete, final newline, single space
  after sentences, 8-line scroll margin, smooth pixel scrolling, `…` for truncation.
- Indent with spaces (width 2), fill column 90, relative line numbers in code, text and
  config modes. Text modes wrap (`visual-line-mode`); code does not.
- Global modes: auto-revert, delete-selection, show-paren, column number, current-line
  highlight, recent files, minibuffer history, saved places.
- Spell check with aspell (English; `M-x ispell-change-dictionary` for `pt_BR`) in text modes,
  only when aspell is installed.
- macOS: left Option is Meta (for `M-j` / `M-k`), right Option still types accents, Command
  is Super; dark, transparent title bar.
- A GUI Emacs does not inherit the shell's `PATH`: exec-path-from-shell copies `PATH`,
  `MANPATH` and `LANG`, and `/Library/TeX/texbin` (MacTeX) is added when present.
- Fonts: JetBrainsMono Nerd Font Mono (fixed) and JetBrainsMono Nerd Font (variable) at
  height `aa/font-height` (130), applied again to frames created by the daemon.
- Sessions (`SPC S`) use desktop files in the data directory; `aa/kill-buffer-force`
  (`SPC b k`) closes a buffer discarding changes; window resizing (`SPC w H/J/K/L`) moves
  `aa/window-resize-step` (2) columns or lines, multiplied by a prefix argument.

### init-ui

- Dracula theme; nerd-icons (run `M-x nerd-icons-install-fonts` once if symbols look broken);
  doom-modeline; which-key (0.3 s delay).
- Minibuffer: vertico (`C-j` / `C-k` move, like Neovim's picker), orderless, marginalia,
  consult (`C-s` searches the buffer), embark (`C-.`, `C-;`, `SPC .`), vertico-repeat for
  `SPC f R`.
- In-buffer completion: corfu with cape (files and dabbrev), 0.2 s delay after 2 characters.
  Nothing is preselected and `RET` accepts only a selected candidate, otherwise it inserts a
  newline, the same behaviour as blink.cmp in Neovim. `Tab` / `S-Tab` / `C-j` / `C-k` move.
  corfu-popupinfo shows documentation.
- treemacs file tree (32 columns) with nerd icons.
- Dashboard with recent files, projects and today's agenda. A plain `emacs` shows it only when
  no file was given. In the daemon (`e`), `initial-buffer-choice` makes new frames without a
  file start on it. It is not set outside the daemon, because `emacs file.org` would then split
  the frame to show both.

### init-evil

evil with evil-collection (`evil-want-keybinding` off so evil-collection owns the mode keys),
`C-u` scrolls, `C-i` does not jump (Tab stays free for Org and buffer switching), fine-grained
undo with `undo-redo`, splits open right and below. Also evil-surround (`ys` / `ds` / `cs`
plus the `gs…` keys from `init-keys.el`), evil-commentary (`gc`), avy (`s` / `S`, 0.3 s
timeout, current window), move-text (`M-j` / `M-k`) and evil-org (with agenda keys).

### init-dev

- **Projects:** `project.el`; `deps.edn`, `project.clj` and `bb.edn` also mark a project root.
  `SPC f f` finds files in the project, or with fd in the current directory outside one.
  xref searches with ripgrep.
- **LSP:** eglot shuts servers down with the last buffer, sends changes after 0.3 s and
  extends xref. clojure-lsp is eglot's default server for Clojure.
- **Diagnostics:** flymake in every programming mode (0.5 s after a change).
  `aa/line-diagnostics` (`SPC c d`) prints the diagnostics of the current line;
  `aa/todos-project` (`SPC d t`) searches TODO/FIXME/HACK/NOTE/BUG with ripgrep.
- **Formatting:** buffers managed by eglot format through the server on save; every other
  buffer goes through apheleia (prettier, shfmt, stylua from the Brewfile). `SPC u f` turns
  both off; `SPC l f` formats on demand, falling back to re-indenting.
- **Editing aids:** indent-bars outside Lisp modes (they add noise in Lisp); electric-pair
  everywhere except Clojure, where smartparens pairs; wgrep to edit grep / embark-export
  results in place (`C-c C-p`, then `C-c C-c`); vundo; hl-todo (`]t` `[t`).
- **Server:** Emacs starts a server, so `e file` (`emacsclient`, alias from `install.sh`)
  reuses the running instance.
- **Git:** magit (status in the same window, word-level refinement of every hunk), diff-hl
  in the fringe (updated live and after magit refreshes), browse-at-remote.
- **Terminal:** eat in the current window, below (15 lines) or on the right (70 columns);
  `C-\` opens one or leaves it.
- **Marks:** a harpoon-like list of files per project, saved in `harpoon.eld` in the data
  directory: add, remove, menu, next/previous, jump to 1–5.

### init-org

Files live in `~/org`, created on first start (nothing is overwritten):

```text
~/org/
  inbox.org       everything that arrives; empty it by refiling
  tasks.org       projects and next actions (Personal, Work, Study)
  calendar.org    appointments
  journal.org     journal by week
  notes/          org-roam notes (notes/daily/ for dailies)
  slides/         Beamer presentations
  archive/        archived subtrees
```

- **Look:** indented, folded to content, inline images (500 px), `…` ellipsis, pretty
  entities, hidden emphasis markers (org-appear reveals them under the cursor), org-modern
  bullets and agenda, larger headings (kept when the theme changes).
- **TODO flow:** `TODO → NEXT → WAIT → DONE / CANCELLED`; WAIT and CANCELLED ask for a note,
  DONE records the time, notes go in a drawer, dependencies are enforced.
- **Tags:** contexts `@home` `@work` `@study` `@out` (exclusive) and `PROJECT` `meeting`
  `slides` `idea`. `PROJECT` is not inherited; a project without a `NEXT` is stuck.
- **Refile** to `tasks.org` (3 levels) or `calendar.org`; archive to `archive/<file>_archive`.
- **Clock** history persists; zero-time clocks are dropped; habits show today's graph.
- **Babel:** Emacs Lisp, shell, Python, LaTeX and Clojure (through CIDER: jack in first).
  Evaluation always asks.
- **LaTeX preview** with dvisvgm at scale 1.4. **Export** to PDF with latexmk (pdflatex);
  Beamer with `#+latex_class: beamer`; smart quotes, UTF-8.
- Org buffers are saved on auto-save and after refile or archive, so the agenda reads
  current files.
- **Capture** (`SPC i`): task, note, idea and meeting (clocked) go to the inbox; events go to
  `calendar.org`; journal entries go to `journal.org` by week.
- **Agenda** reads inbox, tasks and calendar (journal and archive stay out). Views: day (with
  next actions and waiting), week, next, waiting, inbox, projects, stuck, weekly review
  (inbox → stuck → waiting → the week).

Org keys under `,`: `t` TODO state · `s` schedule · `d` deadline · `p` priority · `T` tags ·
`r` refile · `a` archive · `i` / `o` clock in / out · `l` / `L` insert / store link ·
`x` checkbox · `n` / `N` narrow / widen · `e` export · `v` LaTeX preview · `b` run block ·
`B` tangle · `'` edit block. `TAB` cycles headings; `SPC u c` toggles emphasis markers.

### init-notes

org-roam in `~/org/notes/` (dailies in `notes/daily/`), database in the data directory,
completion of note titles everywhere, two templates: plain note and reading/reference (summary,
quotes, ideas). Needs Emacs 29+ (built-in SQLite).

### init-clojure

CIDER owns the REPL, evaluation, completion, documentation and tests; eglot with clojure-lsp
(and clj-kondo) owns diagnostics, rename, references and formatting. LSP completion is off so
it does not compete with CIDER's REPL-aware completion. Needs `clojure`, `leiningen`,
`clojure-lsp` and `clj-kondo` (Brewfile).

- rainbow-delimiters in Clojure and Emacs Lisp; smartparens strict mode keeps parentheses
  balanced, and evil-smartparens makes `d`, `c`, `y`, `x` respect the structure.
- `clojure-align-forms-automatically`.
- `aa/clojure-lsp` does not start the server in revision buffers (`file.~REV~`, such as the
  left side of a diff): they have no file on disk and make the server fail.
- CIDER: no help banner, REPL shown without focus, history in the data directory, saves
  before loading, errors only in the REPL, eldoc for the symbol at point.
- In Lisp buffers, `TAB` on a bracket jumps to its match.

Clojure keys under `,`: `j` / `J` jack-in clj / cljs · `c` connect · `q` quit · `R` refresh
namespaces · `e e/f/b/r/n/p` eval sexp / defun / buffer / region / ns / pretty-print ·
`l` / `L` load buffer / all namespaces · `s s` / `s n` REPL / set namespace ·
`t t/n/p/l/r/s` tests at point / namespace / project / loaded / rerun failed / report ·
`d d/c/j/a` doc / ClojureDocs / Javadoc / apropos · `m` macroexpand · `i` inspect ·
`>` `<` `(` `)` slurp and barf · `w` wrap · `u` unwrap · `^` raise.

## Git diffs

Same model and colors as Neovim, built on magit and ediff:

| Key | What |
|---|---|
| `SPC g v` | pick a changed file (the current one first) and open it side by side |
| `SPC g d` | the current file side by side: index on the left, working tree on the right |
| `SPC g V` | pick a file the branch changed against `origin/HEAD` and open it side by side |
| `SPC g c` | every change in one magit buffer; `e` on a file opens it side by side |
| `SPC g h` / `SPC g H` | history of the file / of the repository |
| `SPC g t` | open a changed, staged or untracked file |

An unstaged file compares the index with the working tree; a staged-only file compares
`HEAD` with the index. `SPC g V` compares the point where the branch left `origin/HEAD`
(falling back to `origin/main` or `origin/master`) with the working tree, so uncommitted
changes count too, as in diffview. Added and deleted files show an empty buffer on the
missing side. ediff runs with the control panel inside the frame (no separate
window), panes side by side (also for merges) and revision buffers dropped on quit. In ediff,
`n` / `p` move between changes and `q` restores the previous layout. A conflicted file opened
with `e` in magit shows three columns.

**Colors** match Neovim: tinted backgrounds for magit's added / removed lines and their
word-level refinements, ediff's current and fine differences, and a neutral `#313546` for the
non-current ones. ediff's default faces force black text on grey; the foreground is cleared so
the theme's colors stay. The faces are applied when magit or ediff load and again whenever a
theme is enabled.

**LSP inside a diff.** Revision buffers never start clojure-lsp (see init-clojure). `gd`,
`gr`, `gi` and `SPC l d/r/i/t` go through `aa/call-keeping-diff`: inside an ediff session, a
buffer they open goes to a new tab (`gt` / `gT` switch back), while jumps within the same
file stay in place. Two details make this work: xref jumps with `switch-to-buffer`, which only
honours display actions when `switch-to-buffer-obey-display-actions` is on, and xref decides
whether to prompt for the identifier by looking at `this-command`, so the wrapper sets it to
the real command.

**Merge conflicts.** Files with conflict markers turn on smerge (vc does this for git):
`]x` / `[x` move between conflicts and `SPC c o` / `c t` / `c b` / `c a` take ours / theirs /
base / both.

## Other notes

- `e file` opens the file in the running Emacs and starts the daemon when needed. If
  `emacsclient` is not on the `PATH`, add the `bin` folder inside `Emacs.app/Contents/MacOS`.
- If a key does nothing, `SPC f k` lists what is bound.
- After changing the configuration, restart Emacs; with the daemon, also run
  `emacsclient -e '(kill-emacs)'`.
