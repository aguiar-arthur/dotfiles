<h1 align="center">dotfiles</h1>

<p align="center">
  <b>One command turns a fresh Mac into a Neovim IDE for code, LaTeX, notes and code review,
  tested like a product.</b>
</p>

<p align="center">
  <a href="https://github.com/aguiar-arthur/dotfiles/actions/workflows/tests.yml"><img alt="Tests" src="https://github.com/aguiar-arthur/dotfiles/actions/workflows/tests.yml/badge.svg"></a>
  <img alt="Neovim 0.12+" src="https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-only-000000?logo=apple&logoColor=white">
  <img alt="Dracula" src="https://img.shields.io/badge/theme-Dracula-BD93F9">
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-50FA7B"></a>
</p>

<p align="center">
  <img src="docs/img/screenshot.png" width="900" alt="Neovim with the file tree and the start screen's clock, in Dracula">
</p>

```sh
git clone https://github.com/aguiar-arthur/dotfiles.git ~/dotfiles && ~/dotfiles/macos/install.sh
```

## Why this one

| | |
|---|---|
| **Review changes in the editor** | your branch, any other, a pull request: side by side, nothing checked out, and on your own files `gd` and `K` work |
| **Claude Code, wired in** | it sees your files, selection and diagnostics, and proposes diffs you accept with a key |
| **Tested like software** | the checks drive a real Neovim in tmux: servers, debugger, a LaTeX build, a run on a fresh machine; every key is documented or a test fails |
| **Secure by default** | gitleaks, zizmor and ShellCheck on every push, actions pinned to a commit |
| **Never restyles other people's code** | format on save only where the project declares a style |
| **LaTeX, live** | the PDF follows your typing in Skim, Cmd+Shift+click jumps back, math snippets expand as you type |
| **Notes without an app** | plain Markdown, `[[links]]`, backlinks and daily notes, no Obsidian account |
| **Clojure in one key** | `,cj` starts the REPL and connects; results appear next to the code |
| **Built for AI assistants** | `AGENTS.md` and one doc per context, so an agent changes it without breaking it |
| **Idempotent, part by part** | run it again and it only does what is missing; install only Neovim on a borrowed Mac |
| **Small on purpose** | about 40 plugins, each well tested and maintained, pinned in a lockfile you can roll back; BasicTeX with the few packages it uses, not MacTeX's 10 GB |

## What you get

- **Neovim**: the editor for everything: code in 11 languages with their servers, run, test and
  debug, git and reviews, LaTeX, Markdown and notes, Claude Code.
- **Starship** prompt, **zsh**, **tmux** and an **iTerm2** profile, all in Dracula with
  JetBrains Mono Nerd Font.

Below: [install](#install), then each part of [Neovim](#using-neovim), [LaTeX](#latex),
[Markdown and notes](#markdown-and-notes) and the [shell and terminal](#shell-prompt-and-terminal),
then [troubleshooting](#troubleshooting), [update](#update), [check](#check) and [test](#test).
How each part works inside, and why, is in
[docs/](docs), one file per context (listed in [AGENTS.md](AGENTS.md#context-map)), which is
also what an AI assistant reads before changing it.

## Install

On a Mac with macOS and an internet connection; nothing else is needed beforehand.

1. **Clone the repository.** On a new Mac, `git` asks to install the Command Line Tools
   first: accept, wait for it to finish, then run the command again.

   ```sh
   git clone https://github.com/aguiar-arthur/dotfiles.git ~/dotfiles
   ```

2. **Run the installer.** It takes a while the first time and asks for your password when
   Homebrew, BasicTeX and its package manager (`tlmgr`) install.

   ```sh
   cd ~/dotfiles && macos/install.sh
   ```

   It runs the four parts below one after the other, and a failed part does not stop the
   others. Each part goes through its steps (a failed step does not stop the next):

   - **brew**: Homebrew, if missing, then every program in the part's `Brewfile` that is not
     installed yet (already installed ones are not upgraded; formulae from other taps are
     trusted first, as Homebrew requires);
   - **link**: the part's `link.sh`, described below;
   - **whichkey** (tmux part only): clones
     [whichkey-tmux](https://github.com/aguiar-arthur/whichkey-tmux) into
     `~/.config/tmux/plugins/whichkey-tmux` when it is missing; a clone already there is kept,
     and anything else in its place is left alone and reported;
   - **tex** (Neovim part only): the TeX packages BasicTeX lacks and this setup uses (latexmk,
     chktex, texcount, abnTeX2 and a few more), installed with `tlmgr` only when missing;
   - **nvim** (Neovim part only): the plugins at the versions in `lazy-lock.json`, the Mason
     servers and tools, the treesitter parsers and the Portuguese spell file, through the
     linked `~/.config/nvim`.

   It ends with `Done.` or with `Failed: <parts>`; fix the errors printed above and run it (or
   just that part) again. Running it again only does what is missing.

3. **Quit iTerm2 (Cmd+Q) and open it again.** The new window uses the "Dotfiles (Dracula)"
   profile with JetBrains Mono Nerd Font, Homebrew on `PATH` and the Starship prompt. If the
   profile did not become the default, run `macos/terminal/link.sh` with iTerm2 closed.

4. **Open Neovim** (`nvim`) and run `:checkhealth` (see [Check](#check)).

### One part at a time

Neovim, terminal, tmux and apps install on their own, so a machine gets only what you want on it.

<details><summary>Details</summary>

| Part | Command | Installs and links |
|---|---|---|
| Neovim | `macos/nvim/install.sh` | Neovim, git, ripgrep, ast-grep, fd, tree-sitter, node, python, the formatters, pandoc, lazygit, gh, Clojure and its tools, BasicTeX with the TeX packages we use, latexindent, Skim, Claude Code; `~/.config/nvim`, `~/.config/rumdl/rumdl.toml`, `~/.latexmkrc`, Skim's preferences; then the plugins, servers and parsers |
| Terminal | `macos/terminal/install.sh` | Starship, eza, fzf, iTerm2, JetBrains Mono Nerd Font; `~/.config/starship.toml`, the iTerm2 profile, `~/.config/git/`, the `~/.zshrc` block |
| tmux | `macos/tmux/install.sh` | tmux, lazygit; `~/.config/tmux/tmux.conf`, lazygit's Dracula `config.yml`; the whichkey-tmux plugin in `~/.config/tmux/plugins/` |
| Apps | `macos/apps/install.sh` | uv, ruby, mole, GrandPerspective |

On a machine whose shell and terminal are already set up and must stay as they are, run only
`macos/nvim/install.sh`, and `macos/tmux/install.sh` if you want tmux there too. Two things then
stay up to that machine: Homebrew on `PATH` (if Homebrew was just installed, it prints the line
to add) and a Nerd Font in the terminal for the icons. Running another part later adds it.

</details>

### What the `link.sh` files do

Each part's `link.sh` links its files into this repository, keeps what was there as
`<name>.bak.<timestamp>`, and adds one marked block to `~/.zshrc`; the rest of `~/.zshrc` stays
yours. It runs on its own after a `git pull`. Details: [docs/install.md](docs/install.md).

## Using Neovim

`Space` is the leader key and `,` the local leader. `Space …` keys work in every file;
`, …` keys depend on the file type (run, test, debug, LaTeX, Clojure). Press either one and
wait: which-key lists every key that follows, so nothing has to be memorised.
`Space ?` lists the keys of the current buffer, and `Space f k` searches every key.

### First day

The keys to start with.

| Key | Does |
|---|---|
| `Space f f` / `Space f g` | find a file / search text in the project |
| `Space f r` / `Space b b` | recent files / open buffers |
| `Space o p` | file tree |
| `Space s` / `Space q` | save / quit |
| `gd` / `grr` / `K` | go to definition / references / documentation |
| `gra` / `grn` | code action / rename |
| `Space g g` | lazygit |
| `,r` | run the file (Python, Lua, shell, zsh, JavaScript, C, C++, Java, Ruby, Rust) |

### Completion and snippets (blink.cmp, LuaSnip)

Suggestions from the server, the buffer, paths and snippets, as you type.

<details><summary>Details</summary>

The menu opens by itself in insert mode; `Tab` walks the fields of a snippet, `Enter` accepts.
On the `:` line the menu also opens: `Tab` completes and `Enter` runs the line as typed.

</details>

### Finding things (Snacks picker, file tree, grug-far)

One fuzzy picker for files, text, symbols, git and more, plus project-wide search and replace.

<details><summary>Details</summary>

Every list (files, text, buffers, symbols, diagnostics, todos, git) opens in the same picker:
type to filter, `Enter` opens, `C-v` / `C-s` split, `Esc` twice closes; `Space f R` reopens the
last one where you left it. grug-far replaces across the project, also by syntax with ast-grep.

</details>

### Moving and editing (flash, mini.ai, mini.surround, mini.pairs)

Jump anywhere in two keystrokes, edit functions and arguments as objects, copy a line as a GitHub
link.

<details><summary>Details</summary>

`s` jumps with flash; `af` / `if`, `au` / `iu`, `aa` / `ia` select a function, a call, an
argument in any language with a treesitter parser; `gs…` surrounds; brackets and quotes close
themselves in a file, not on the `:` line. `Space c` copies the selection with its path, or as a
GitHub link.

</details>

### Windows, buffers, terminals and sessions

Floating terminals, one session per folder, restored where you left it.

<details><summary>Details</summary>

Terminals open floating, below or beside, and come back with their history; inside one every
key goes to the program (a shell, lazygit, a REPL, Claude) but a few to leave it. Sessions are
saved on quit, one per folder.

</details>

### Code: language servers, diagnostics and formatting

Definitions, references, call hierarchy, rename and code actions in Lua, Python, web, shell,
Markdown, LaTeX and Clojure.

<details><summary>Details</summary>

Servers start by themselves for Lua, Python, HTML, CSS, JSON, YAML, TOML, Bash, Markdown,
LaTeX and Clojure. The line under the cursor shows its diagnostics in full on lines below it;
other lines show them at the end.

Saving formats the file only in projects that declare that formatter's style (a
`stylua.toml`, a prettier config, `[tool.ruff]`, …), so other people's code is never
restyled. Prettier runs a project's JavaScript, so it also needs a `.nvim.lua` approved with
`:trust` next to the prettier config (an empty one is enough). `Space l f` formats anywhere;
`Space u f` turns format-on-save off.

</details>

### Run, test and debug (`,` keys)

`,r` runs the file, `,t` runs the tests under the cursor, `,d` debugs with breakpoints and a watch
panel.

<details><summary>Details</summary>

`,r` saves the file and runs it from its folder; running it again replaces its terminal. Python
runs with the activated `$VIRTUAL_ENV`, else the project's `.venv`, else `python3`. Test results
appear as signs next to each test and as diagnostics on the failing line (Neotest). A debug
session shows variables, the call stack, breakpoints and the program's output, and stays open
after the program ends.

</details>

### Git (gitsigns, Snacks, codediff, lazygit)

Stage hunks inline, compare with any branch or pull request side by side, and resolve conflicts.

<details><summary>Details</summary>

Changed lines are marked in the left column. Reviews show the old and new versions side by side
in their own tab, with the changed files on the left: your changes, a branch, the base branch, a
pull request, a commit, a file's or a line's history, nothing checked out. When the right side
is your working file, `gd`, `K` and edits work there; a file opened from the review opens in the
tab before it, so the review stays as it was. In a merge conflict the review shows theirs, ours
and the result, and lazygit does the rest.

</details>

### Claude Code (claudecode.nvim)

Claude in a floating window that sees your editor and proposes edits as diffs.

<details><summary>Details</summary>

Claude Code runs in a bordered window over the editor and talks to this Neovim: it sees the
open files, the selection and the diagnostics, and shows its edits as a diff to accept or
reject. A review's changes go to it in one key. When Claude is hidden and it notifies or exits,
a notification tells you. Log in once in the terminal first (`claude`, then `/login`).

</details>

### Toggles (`Space u`)

Spelling, wrap, diagnostics, inlay hints, format on save and more, one key each.

<details><summary>Details</summary>

Each toggle changes every window and buffer, including the ones opened later, and shows its new
state.

</details>

### Clojure (Conjure, nvim-paredit, clojure-lsp)

Jack-in with one key, evaluate forms inline, edit structure with slurp and barf.

<details><summary>Details</summary>

Open a file of a `deps.edn`, `project.clj` or `bb.edn` (Babashka) project and press `,cj`: it
starts an nREPL in a terminal below and connects as soon as it is up (or only connects when a
REPL already runs). Results show next to the code and in the log; completion also offers what
the running REPL knows.

</details>

### Look

Dracula, a status line that tells you what the servers are doing, no "Press ENTER" prompts.

<details><summary>Details</summary>

The status line shows the mode, git branch and changes, diagnostics, the file, the language
servers, their progress while they load or index and a running LaTeX build. Messages and the
`:` line use Neovim's new message UI: no "Press ENTER" prompts, the `:` line is highlighted as
you type, and long output folds behind a `[+N]` mark (`g<` shows it in full). `Space o d` opens
the start screen, `Space o n` the notification history.

</details>

## LaTeX

### Write and build

Continuous build, the PDF in Skim at the cursor, and a click in the PDF back to the source.

<details><summary>Details</summary>

1. Open the main file: `nvim main.tex`.
2. The build starts by itself when the file opens (latexmk, continuous) and the file is saved
   when you stop typing, so the PDF follows your edits. `,ll` stops and starts it again.
3. `,lv` opens the PDF in Skim at the line under the cursor; after that, every rebuild moves
   Skim to the cursor. Skim stays in the background.
4. In Skim, **Cmd+Shift+click** jumps back to that line in Neovim.
5. `,le` lists errors and warnings; `Enter` on one goes to the line.

The PDF, the bibliography and the auxiliary files go to `build/` next to the main file, so the
project folder keeps only sources. A `.bib` next to it is picked up (BibTeX). For another
engine, put `% !TEX program = lualatex` on the first line. To build and save by hand only, set
`latex_live = false` in `lua/config/local.lua`. A `latexmkrc` inside a project wins over the
linked `~/.latexmkrc`. TeX is BasicTeX: a package it lacks is one `sudo tlmgr install <name>`
away (see [Troubleshooting](#troubleshooting)).

</details>

### Snippets

An article, a beamer deck or a complete abnTeX2 thesis in one word; fractions and Greek letters
as you type math.

<details><summary>Details</summary>

`doc`, `bdoc` and `abnt` start a document; `fig`, `tab`, `ali`, `thm` and friends insert the
common environments. Inside math, `//` makes a fraction, `;a` an alpha, `RR` a `\mathbb{R}`,
without a key. [Every snippet](config/nvim/snippets/tex.lua).

</details>

### Spelling and grammar

Spelling in English and Portuguese, grammar with ltex-ls-plus.

<details><summary>Details</summary>

`]s` / `[s` move between misspelled words, `z=` suggests, `zg` accepts a word everywhere (kept in
`config/nvim/spell/en.utf-8.add`). Grammar is checked in Portuguese (`pt-BR`); a comment
`% LTeX: language=en-US` switches it from that line on. `Space u s` and `Space u G` turn each off.

</details>

## Markdown and notes

### Any Markdown file

A rendered view in the editor, a browser preview that follows your saves, lint as you type.

<details><summary>Details</summary>

`,p` builds an HTML preview with pandoc and opens it in the browser; every save rebuilds it.
`Space u m` turns the rendered view (headings, tables, checkboxes) on or off. rumdl underlines
problems as you type (rules in `config/rumdl/rumdl.toml`) and reformats on save only in
projects with a `.rumdl.toml` or `.markdownlint.*`.

</details>

### Notes

A plain folder of Markdown notes with links, backlinks and daily notes.

<details><summary>Details</summary>

Notes are plain `.md` files in `~/notes` (change it with `notes.dir` in
[`local.lua`](#per-machine-settings)), handled by obsidian.nvim. No Obsidian app or account is
needed. `Space n n` creates a note, `Space n d` opens today's, `[[` links to another as you type
and `Space n b` lists the notes that link here.

</details>

## Shell, prompt and terminal

- **zsh**: `~/.zshrc` gets one marked block (`# >>> dotfiles >>>`) that sources
  `config/zsh/dotfiles.zsh`: Homebrew on `PATH`, a valid `LANG`, Homebrew's Java as
  `JAVA_HOME` (Clojure needs it), Neovim as `EDITOR` and `VISUAL`, a 50,000-line history shared
  by every open shell, Tab completion with a menu (case-insensitive, for git, brew, gh and the
  rest), the Starship prompt, and two helpers: `path_report` lists `PATH` in order and
  `command_origin <name>…` says which program runs and whether Homebrew installed it. The
  line keeps emacs keys (`Ctrl-a`, `Ctrl-e`) in every shell. Everything else in
  `~/.zshrc` stays yours.
- **fzf** searches as you type: `Ctrl-r` the history, `Ctrl-t` a file to put on the line,
  `Alt-c` a folder to go to.
- **eza** lists files with icons, folders first: `ls`, `ll` (everything, with each file's git
  status), `lt` (by date, newest last: what `ls -ltr` did); `command ls` is the system's.
- **Starship** (`config/starship/starship.toml`): folder, git branch and status, lines added
  and removed, the language versions of the project, how long the last command took, the time
  and a failed command's status, as rounded pills in Dracula colors on rows held by a bracket.
  A blank line separates prompts, but none sits above the first one or after `clear`.
- **tmux** (`config/tmux/tmux.conf`, its own part): a Dracula status bar with pills like the
  prompt's, true color and focus events for Neovim, `Ctrl-h/j/k/l` across panes and Neovim's
  windows alike, splits in the pane's folder, lazygit and a scratch shell in popups, and
  [whichkey-tmux](https://github.com/aguiar-arthur/whichkey-tmux) showing the keys when you
  pause after the prefix. It works without the Neovim config; only leaving a Neovim pane with
  `Ctrl-h/j/k/l` needs it.
- **iTerm2** (`config/iterm2/dracula.json`): the "Dotfiles (Dracula)" profile with JetBrains
  Mono Nerd Font, which the icons in Neovim and the prompt need.
- **latexmk** (`config/latex/latexmkrc`, linked to `~/.latexmkrc`): PDF output, BibTeX when a
  `.bib` exists, and what `,lc` cleans.
- **rumdl** (`config/rumdl/rumdl.toml`): the Markdown lint rules, used by Neovim and by
  `rumdl check` in a shell.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `git clone` asks for the Command Line Tools | accept, wait for them, run the command again |
| A LaTeX build stops at ``File `x.sty' not found`` | `sudo tlmgr install x`, or add `x` to `PACKAGES` in `macos/nvim/tex.sh` |
| The brew step says `basictex` conflicts with `mactex-no-gui` | `brew uninstall --cask mactex-no-gui`, then run `macos/nvim/install.sh` again |
| tlmgr says the repository is newer than this TeX Live (a new year) | `brew upgrade --cask basictex`, then run `macos/nvim/install.sh` again |
| basedpyright or debugpy stop starting after `brew upgrade` | `macos/nvim/install.sh` reinstalls them for the new Python (the quick tests name them) |
| A plugin update broke something | `git restore config/nvim/lazy-lock.json`, then `:Lazy restore` |
| A Neovim update warns `ui2 is off` | delete the `ui2` lines in `config/nvim/lua/config/options.lua` |
| Icons show as boxes | the terminal needs a Nerd Font (the terminal part installs one) |
| iTerm2 did not switch to the Dracula profile | quit iTerm2, run `macos/terminal/link.sh`, open it again |
| `:checkhealth snacks` errors in `nvim --headless` | not real; check in a real Neovim window |

## On a machine that is not yours

Install only Neovim and leave nothing personal behind.

<details><summary>Details</summary>

Install the Neovim part only (`macos/nvim/install.sh`): it leaves the shell, the prompt and the
terminal untouched. Then:

- Do not put personal tokens or SSH keys there; log in with a short-lived, narrow token, or
  none, and run `gh auth logout` or delete it when you leave.
- Do not trust a `.nvim.lua` from a repository you did not write; `exrc` asks before running
  one, so answer no.
- Before running anything on a fresh clone, read `git log` for commits you do not recognise.
- When you leave, remove `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim` and
  `~/.cache/nvim`.

GitHub checks this repository on every push and every Monday: ShellCheck on the scripts,
gitleaks on the history and zizmor on the workflows.

</details>

## Update

Nothing updates itself: about once a month, on a branch (details in
[docs/install.md](docs/install.md#updating)).

| What | How |
|---|---|
| Programs (BasicTeX's new year included) | `brew update && brew upgrade`, then `macos/nvim/install.sh` |
| TeX packages within the year | `sudo tlmgr update --self --all` |
| Neovim plugins | `nvim --headless "+Lazy! update" +qa`, `tests/nvim.sh full`, then commit `config/nvim/lazy-lock.json` |
| Mason servers and tools | `:Mason`, then `U` |

## Check

Read-only commands that say what is missing or wrong.

<details><summary>Details</summary>

| What | How | All good when |
|---|---|---|
| Programs | `brew bundle check --verbose --file ~/dotfiles/macos/<part>/Brewfile` (`nvim`, `terminal`, `tmux`, `apps`) | `The Brewfile's dependencies are satisfied.` |
| TeX packages | `macos/nvim/tex.sh` (installs only what is missing) | every line starts with `ok` |
| Links, `~/.zshrc`, app preferences | each part's `link.sh` (fix what differs) | every line starts with `ok` |
| Neovim starts cleanly | `nvim --headless "+qa"` | it prints nothing |
| Everything inside Neovim | `:checkhealth` | no `ERROR` |
| Language servers in this buffer | `:checkhealth vim.lsp` | the server is under "Active Clients" |
| Plugins / Mason | `:Lazy` / `:Mason` | nothing in red / all installed |
| Formatters for this buffer | `:ConformInfo` | the formatter shows as ready |
| Secrets in the history | `gitleaks detect` | `no leaks found` |

Run `:checkhealth` in a real Neovim window: in `nvim --headless` the Snacks checks report
errors that are not real. When a check fails, `macos/install.sh` (or the part's) is the fix for
anything missing: it installs only what is not there.

</details>

## Test

`~/dotfiles/tests/nvim.sh` checks the setup in seconds; `tests/nvim.sh full` drives a real
Neovim in tmux (minutes), and `tests/nvim.sh fresh` does it as on a new machine. Run quick after
any change, full after changing plugins, keys or servers, fresh after changing `macos/`. How it
works: [docs/tests.md](docs/tests.md).

## Per-machine settings

`config/nvim/lua/config/local.lua` (untracked, read when present) returns a table merged
over `lua/config/settings.lua`, for example:

```lua
return { wrap = false, spelllang = { "en_us" }, notes = { dir = "~/Documents/notes" } }
```

For a single project, a `.nvim.lua` at its root ([docs/core.md](docs/core.md#per-project-settings)).

## Windows health report

Not part of the macOS setup: to find why a Windows 11 PC shuts down or crashes, run in
PowerShell as Administrator

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\collect-diagnostics.ps1
```

It only reads, zips a report into `Documents\diagnostics`, and asks before any repair. The ZIP
holds computer and user names, serial numbers and crash dumps: read it before sharing. Its
options and what it collects are in [docs/windows.md](docs/windows.md).

## Layout

Where each file lives: [AGENTS.md](AGENTS.md#layout).

MIT, see [LICENSE](LICENSE).
