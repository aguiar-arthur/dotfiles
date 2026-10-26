# Dotfiles

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/aguiar-arthur/dotfiles/badge)](https://scorecard.dev/viewer/?uri=github.com/aguiar-arthur/dotfiles)

Personal macOS setup:

- **Neovim**: the editor, for everything (code, LaTeX, Markdown and notes, git).
- **Starship** prompt and an **iTerm2** profile, both in Dracula colors.

This page is the hands-on guide: [install](#install), then how to use each part of
[Neovim](#using-neovim) with its keys (finding, editing, code, run / test / debug, git,
toggles, Clojure), [LaTeX](#latex), [Markdown and notes](#markdown-and-notes), the
[shell and terminal](#shell-prompt-and-terminal), [update](#update), [check](#check) and
[test](#test). How each part works inside, and why, is in [docs/](docs), one file per
context (listed in [AGENTS.md](AGENTS.md#context-map)), which is also what an AI assistant
reads before changing it.

## Install

On a Mac with macOS and an internet connection; nothing else is needed beforehand.

1. **Clone the repository.** On a new Mac, `git` asks to install the Command Line Tools
   first: accept, wait for it to finish, then run the command again.

   ```sh
   git clone https://github.com/aguiar-arthur/dotfiles.git ~/dotfiles
   ```

2. **Run the installer.** It takes a while the first time (MacTeX alone is several GB) and
   asks for your password when Homebrew and MacTeX install.

   ```sh
   cd ~/dotfiles && macos/install.sh
   ```

   It runs the three parts below one after the other, and a failed part does not stop the
   others. Each part goes through its steps (a failed step does not stop the next):

   - **brew**: Homebrew, if missing, then every program in the part's `Brewfile` that is not
     installed yet (already installed ones are not upgraded; formulae from other taps are
     trusted first, as Homebrew requires);
   - **link**: the part's `link.sh`, described below;
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

Each part installs on its own, so a machine gets only what you want on it:

| Part | Command | Installs and links |
|---|---|---|
| Neovim | `macos/nvim/install.sh` | Neovim, git, ripgrep, ast-grep, fd, tree-sitter, node, python, the formatters, pandoc, lazygit, Clojure and its tools, LaTeX, Skim, Claude Code; `~/.config/nvim`, `~/.config/rumdl/rumdl.toml`, `~/.latexmkrc`, Skim's preferences; then the plugins, servers and parsers |
| Terminal | `macos/terminal/install.sh` | Starship, tmux, iTerm2, JetBrains Mono Nerd Font; `~/.config/starship.toml`, the iTerm2 profile, the `~/.zshrc` block |
| Apps | `macos/apps/install.sh` | uv, ruby, mole, GrandPerspective |

On a machine whose shell and terminal are already set up and must stay as they are, run only
`macos/nvim/install.sh`. MacTeX is a large download and asks for your password. Two things then
stay up to that machine: Homebrew on `PATH` (if Homebrew was just installed, it prints the line
to add) and a Nerd Font in the terminal for the icons. Running another part later adds it.

### What the `link.sh` files do

Each part's `link.sh` (`macos/nvim/link.sh`, `macos/terminal/link.sh`) also runs on its own
after a `git pull`. Together they:

- link `~/.config/nvim`, `~/.config/rumdl/rumdl.toml` and `~/.latexmkrc` (nvim),
  `~/.config/starship.toml` and the iTerm2 Dynamic Profile (terminal) to this repository,
  moving whatever was there to `<name>.bak.<timestamp>` (three backups kept);
- add one marked block to `~/.zshrc` that sources `config/zsh/dotfiles.zsh` (terminal):
  Homebrew on `PATH`, a valid `LANG`, Java, Neovim as `EDITOR`, a long shared history and the
  Starship prompt;
- set Skim's inverse search to Neovim and make Skim reload a PDF when it changes (nvim);
- make "Dotfiles (Dracula)" iTerm2's default profile (terminal).

## Using Neovim

`Space` is the leader key and `,` the local leader. `Space …` keys work in every file;
`, …` keys depend on the file type (run, test, debug, LaTeX, Clojure). Press either one and
wait: which-key lists every key that follows, so nothing below has to be memorised.
`Space ?` lists the keys of the current buffer.

Each part below is one module of the configuration: what it is for, how to use it and its
keys. How it works inside, and why: [core](docs/core.md) (settings, toggles, look),
[workspace](docs/workspace.md) (finding, editing, completion, Claude), [code](docs/code.md)
(servers, formatting, run / test / debug, Clojure), [git](docs/git.md), [LaTeX](docs/latex.md)
and [Markdown](docs/markdown.md).

### First day

| Key | Does |
|---|---|
| `Space f f` / `Space f g` | find a file / search text in the project |
| `Space f r` / `Space b b` | recent files / open buffers |
| `Space o p` | file tree |
| `Space s` / `Space q` | save / quit |
| `gd` / `gr` / `K` | go to definition / references / documentation |
| `Space l a` / `Space l n` | code action / rename |
| `Space g g` | lazygit |
| `,r` | run the file (Python, Lua, shell, JavaScript, C, C++, Java, Ruby, Rust) |

### Completion and snippets (blink.cmp, LuaSnip)

The menu opens by itself in insert mode, with suggestions from the language server, the
buffer, file paths and snippets. On the `:` line the menu also opens: `Tab` completes (a single
match at once) and `Enter` runs the line as typed.

| Key (insert mode) | Does |
|---|---|
| `Tab` / `S-Tab` | next / previous field of a snippet; otherwise next / previous item |
| `Enter` | accept the item |
| `C-e` | close the menu |
| `C-Space` | open the menu, or show / hide the item's documentation |
| `C-b` / `C-f` | scroll the documentation |
| `C-s` | show / hide the function signature |

### Finding things (Snacks picker, file tree, grug-far)

Every list (files, text, buffers, symbols, git) opens in the same picker: type to filter,
`C-n` / `C-p` move, `Enter` opens, `C-v` / `C-s` open in a vertical / horizontal split, `Esc`
leaves insert mode and a second `Esc` closes. `Space f R` reopens the last picker where you left it.

| Key | Does |
|---|---|
| `Space f f` | files of the project (smart: recent and nearby first) |
| `Space f F` | all files, including ignored ones |
| `Space f g` / `Space f w` | search text / the word or selection under the cursor |
| `Space f /` | search in this buffer |
| `Space f r` / `Space f p` | recent files / projects |
| `Space f s` / `Space f S` | symbols of this file / of the workspace |
| `Space f m` | marks (`mA` sets mark A, `'A` jumps back to that file) |
| `Space f u` | undo history |
| `Space f h` / `Space f k` | help pages / keymaps |
| `Space f c` / `Space f C` | the Neovim config files / colorschemes |
| `Space o p` / `Space o f` | file tree / the current file in the tree |
| `Space r` | search and replace in the whole project (grug-far), prefilled with the word or selection |

In the file tree `a` creates, `d` deletes, `r` renames, `c` copies, `m` moves and `?` lists
the rest.

### Moving and editing (flash, mini.ai, mini.surround, mini.pairs)

| Key | Does |
|---|---|
| `s` + characters | jump anywhere on screen: type what you see, then the label (flash) |
| `C-s` while searching with `/` | show flash labels on the matches, or hide them |
| `S` | select a treesitter node (function, block, argument) with labels |
| `r` after an operator | act at a distance: `yr`, a label, then `iw` copies a far-away word and the cursor stays |
| `af` / `if`, `ac` / `ic` | around / inside a function, a class (`daf` deletes a function) |
| `au` / `iu`, `aa` / `ia` | around / inside a function call, an argument (`ciu` rewrites a call's arguments) |
| `gsa` / `gsd` / `gsr` | add / delete / replace a surrounding (`gsaiw"` quotes a word, `gsd(` removes parentheses) |
| `gcc` / `gc` | comment a line / a motion or selection |
| `Space c s` | copy the line (the selection in visual mode) to paste anywhere: `path:line:col-line:col`, then a code block |
| `Alt-j` / `Alt-k` | move the line or selection down / up |
| `<` / `>` in visual mode | indent, keeping the selection |
| `]r` / `[r` | next / previous reference of the word under the cursor |
| `]t` / `[t` | next / previous `TODO`, `FIXME`, `NOTE` comment |
| `Esc` | clear the search highlight |

Brackets and quotes close themselves as you type (mini.pairs).

### Windows, buffers, terminals and sessions

| Key | Does |
|---|---|
| `C-h` / `C-j` / `C-k` / `C-l` | go to the window on the left / below / above / right |
| `C-w v` / `C-w s` | split vertically / horizontally (Neovim's own `C-w` keys; which-key lists them all) |
| `C-w c` / `C-w o` | close this window / the others |
| `C-w =` | make the windows the same size |
| `C-w <` / `>` / `-` / `+` | narrower / wider / shorter / taller (a count first, as in `5 C-w >`, for more) |
| `]b` / `[b` | next / previous buffer (Neovim's own) |
| `Space b d` | close the buffer (keeps the window, asks about unsaved changes); in a review, close it; on a file a review shows, only warn |
| `Space t f` / `t h` / `t v` | show or hide a floating / bottom / right terminal, each its own shell |
| `Space S r` / `Space S l` | restore the session of this folder / the last session |
| `Space S s` / `Space S d` | pick a session / do not save this one |

Inside a terminal (a shell, lazygit, a REPL, Claude) every key goes to the program except these:

| Key (in a terminal) | Does |
|---|---|
| `C-\ C-n` | back to Neovim; the program never sees it |
| `Esc Esc` (quick) | back to Neovim too, but the first `Esc` reaches the program (it stops Claude while it works) |
| `C-h` / `C-j` / `C-k` / `C-l` | once back in Neovim, go to the window on the left / below / above / right |
| `q` | once back in Neovim, hide the terminal (it keeps running) |
| `i` | type into the program again |
| `Shift-Enter` | a new line in Claude's prompt instead of sending it |

Sessions are saved on quit, one per folder.

### Code: language servers, diagnostics and formatting

Servers start by themselves for Lua, Python, HTML, CSS, JSON, YAML, TOML, Bash, Markdown,
LaTeX and Clojure.

| Key | Does |
|---|---|
| `gd` / `gr` | go to the definition / list references (the list opens even for one) |
| `K` | documentation of the word under the cursor |
| `Space l i` / `Space l t` / `Space l D` | implementation / type definition / declaration |
| `Space l n` | rename everywhere |
| `Space l a` | code action (fix, import, refactor), also on a selection |
| `Space l s` | signature help |
| `Space l f` | format the buffer or the selection |
| `Space l R` / `Space l M` | restart the servers / open Mason |
| `]d` / `[d`, `]e` / `[e` | next / previous diagnostic, error |
| `C-w d` | the diagnostics of this line in a float (Neovim's own) |
| `Space d x` / `Space d d` | all diagnostics / those of this file, in a picker |
| `Space d t` | every `TODO` / `FIXME` of the project |
| `Space d q` / `Space d l` | quickfix / location list, in a picker |

The line under the cursor shows its diagnostics in full on lines below it; other lines show
them at the end. Renaming an HTML tag renames its closing tag too.

Saving formats the file only in projects that declare that formatter's style (a
`stylua.toml`, a prettier config, `[tool.ruff]`, …), so other people's code is never
restyled. Prettier runs a project's JavaScript, so it also needs a `.nvim.lua` approved with
`:trust` next to the prettier config (an empty one is enough). `Space l f` formats anywhere
(prettier still only there); `Space u f` turns format-on-save off, `Space u F` only for this
file.

### Run, test and debug (`,` keys)

These keys exist only in the languages listed; in other files they are not mapped.

| Key | Python | Lua | Shell |
|---|---|---|---|
| `,r` run the file in a bottom terminal | yes | `nvim -l` | `bash` |
| `,t…` tests (Neotest) | pytest | | |
| `,d…` debugger (nvim-dap) | debugpy | | |
| `,o` organize imports | ruff | | |
| `,s` source the file into Neovim | | yes | |

`,r` saves the file and runs it from its folder; running the same file again replaces its
terminal. It also runs JavaScript, C, C++, Java, Ruby and Rust files. Python runs with
the project's `.venv`, else `$VIRTUAL_ENV`, else `python3`.

| Tests | Does |
|---|---|
| `,t t` / `,t f` / `,t p` | the nearest test / this file / the whole project |
| `,t l` / `,t S` | run the last tests again / stop them |
| `,t s` | summary tree of every test (`r` runs the one under the cursor, `i` jumps to it, `o` its output) |
| `,t o` / `,t O` | output of the test under the cursor / the output panel |
| `,t d` | debug the nearest test (Python) |

Results appear as signs next to each test and as diagnostics on the failing line.

| Debugger | Does |
|---|---|
| `,d b` / `,d B` | breakpoint / breakpoint with a condition |
| `,d c` | start, or continue to the next breakpoint |
| `,d i` / `,d o` / `,d O` | step into / over / out |
| `,d e` | evaluate the expression under the cursor or the selection, in a float (`q` closes) |
| `,d r` / `,d l` | debug REPL / run the last session again |
| `,d t` / `,d u` | stop / show or hide the panels (nvim-dap-view: `]v` / `[v` switch view, `g?` its keys) |

A session opens panels with variables, the call stack, breakpoints and the program's output;
they stay open after the program ends so its output can be read.

### Git (gitsigns, Snacks, codediff, lazygit)

Changed lines are marked in the left column and the line's last commit shows at its end.

| Key | Does |
|---|---|
| `Space g g` | lazygit: stage, commit, push, branches, merge conflicts |
| `]c` / `[c` | next / previous changed block (hunk) |
| `Space g p` | preview the hunk |
| `Space g s` / `Space g r` | stage (or unstage, if staged) / reset the hunk or the selected lines |
| `Space g S` / `Space g R` | stage / reset the whole file |
| `Space g b` / `Space g B` | blame the line / turn the end-of-line blame off |
| `Space g c` / `Space g t` | jump to a changed hunk / a changed file of the working tree (`Tab` stages) |
| `Space g l` | search the log; `Enter` reviews that commit against its parent (it never checks it out) |
| `Space g O` | open the file in the browser (GitHub, GitLab, …) |
| `ih` | the hunk as a text object (`dih` deletes it) |

Reviews show the old and new versions side by side in their own tab, with the changed files on
the left when there are several:

| Key | Reviews |
|---|---|
| `Space g D` | the working tree: what is not staged, as the marks show (opens on the current file); again inside a review closes it |
| `Space g C` | what is staged, before you commit |
| `Space g d` | this file against the last commit (HEAD), staged changes too |
| `Space g V` | everything this branch changes against origin's default branch |
| `Space g P` | a pull request: type its number (fetched, nothing is checked out) |
| `Space g h` / `Space g L` | the history of the file / of the line or selected lines, commit by commit |

The right side is the real file, so `gd`, `K` and edits work there. A file you open from the
review (`gf`, or a picker: `gd`, `gr`, `Space f f`, …) opens in the tab just before it, so
the review stays as it was; `gt` / `gT` switch between the two. `Space g q` closes the review from
either tab, even when the review is the last tab. The two sides never wrap lines: codediff keeps
them aligned that way.

| Key (in the review) | Does |
|---|---|
| `Enter` | show the file under the cursor (in the file list) |
| `]f` / `[f` | next / previous file |
| `]c` / `[c` | next / previous change |
| `Space g a` | stage / unstage the file |
| `Space g s` / `Space g r` | stage or unstage / reset the change under the cursor (on the real file) |
| `Space g u` | unstage the change under the cursor (in a review of staged changes) |
| `gf` / `Space g f` | open the file in the tab before the review |
| `Space g i` / `Space g z` | inline or side by side / fold the unchanged lines |
| `Space g E` / `Space o p` | go to / show or hide the file list (`Space g e` does the same as `Space o p`) |
| `Space b d` | close the review |
| `g?` / `q` / `Space g q` | every key / close the review |

In a merge conflict, `Space g D` lists the conflicted files and shows theirs, ours and the result:

| Key (in a conflict) | Does |
|---|---|
| `]x` / `[x` | next / previous conflict |
| `Space g m t` / `o` / `b` / `x` | take theirs / ours / both / neither for this conflict |
| `Space g m T` / `O` / `B` / `X` | the same for the whole file |

lazygit (`Space g g`) does the rest of a merge: continue, abort, or pick a whole side per file.

### Claude Code (claudecode.nvim)

Claude Code runs in a bordered window over the editor, with a margin on each side, and talks to
this Neovim: it sees the open files, the selection and the diagnostics, and shows its edits as a
diff to accept or reject. Sending a selection or a file moves you into Claude, ready to type
(`Esc Esc` or `C-\ C-n` comes back). When Claude is hidden and it sends a terminal notification
or exits, a notification tells you; whether Claude Code sends one depends on its own
notification setting. A diff Claude proposes opens in its own tab, where `Space a a` / `Space a d`
accept or reject it. Log in once in the terminal first (`claude`, then `/login`). Nothing
starts with Neovim: the connection opens with the first of these keys.

| Key | Does |
|---|---|
| `Space a c` / `Space a f` | open or close Claude / go to its window |
| `Space a r` / `Space a C` | pick an earlier session to resume / continue the last one |
| `Space a m` | choose the model |
| `Space a b` | add this file to the conversation; in the file tree, the item under the cursor |
| `Space a B` | the same, to the last session: opens it (continue) when Claude is not running |
| `Space a s` | send the selection (visual mode) |
| `Space a S` | send the selection to the last session: opens it (continue) when Claude is not running |
| `Space a a` / `Space a d` | accept / reject the diff Claude proposes |
| `Space a q` | stop the connection |

### Toggles (`Space u`)

Each toggle changes every window and buffer, including the ones opened later, and shows its new
state.

| Key | Toggles |
|---|---|
| `Space u s` | spelling (prose files) |
| `Space u w` | line wrap (not in a review: it only warns) |
| `Space u L` | relative line numbers |
| `Space u c` | conceal (hidden Markdown and LaTeX markup) |
| `Space u d` | diagnostics |
| `Space u h` | inlay hints (types and parameter names inside the code) |
| `Space u g` | indent guides |
| `Space u S` | smooth scrolling (animated `C-d`, `C-u`, `zz`) |
| `Space u x` | code context (the current function pinned on top) |
| `Space u m` | Markdown rendering |
| `Space u G` | grammar checking (LaTeX) |
| `Space u T` | treesitter highlight |
| `Space u f` | format on save |
| `Space u F` | format on save, this file only |
| `Space u n` | dismiss the notifications (`Space o n` shows their history) |

### Clojure (Conjure, nvim-paredit, clojure-lsp)

Open a file of a `deps.edn`, `project.clj` or `bb.edn` (Babashka) project and press `,cj`: it
starts an nREPL in a terminal below and connects as soon as it is up (or only connects when a
REPL already runs). Results show next to the code and in the log. Once connected, completion
also offers what the running REPL knows (Conjure's omnifunc, beside clojure-lsp's).

| Key | Does |
|---|---|
| `,cj` | start the REPL and connect (jack-in) |
| `,ee` / `,er` / `,ew` | evaluate the form under the cursor / the outermost form / the word |
| `,eb` / `,ef` | evaluate the buffer / the file |
| `,E` + motion or selection | evaluate that text |
| `,tn` / `,tc` / `,ta` | run the namespace's tests / the test under the cursor / all tests |
| `,rr` / `,ra` | reload the changed namespaces / all of them |
| `,ls` / `,lv` / `,lq` | log in a split / a vertical split / close it |
| `>)` / `<)` | slurp / barf forward (pull the next element in, push the last one out) |
| `<(` / `>(` | slurp / barf backward |
| `>e` / `<e`, `>f` / `<f` | drag an element, a form, right / left |
| `,o` / `,O` | raise the form / the element (replace the parent with it) |
| `af` / `if`, `ae` / `ie` | around / inside a form, an element |

`gd`, `K` and rename come from clojure-lsp, as in any language.

### Look

Dracula everywhere. The status line shows the mode, git branch and changes, diagnostics, the
file, the language servers and a running LaTeX build. The left column shows marks,
diagnostics, git changes and folds. `Space o d` opens the start screen (`q` closes it, or quits
when it is the start screen itself), `Space o n` the notification history.

## LaTeX

### Write and build

1. Open the main file: `nvim main.tex`.
2. The build starts by itself when the file opens (latexmk, continuous) and the file is saved
   when you stop typing, so the PDF follows your edits. `,ll` stops and starts it again.
3. `,lv` opens the PDF in Skim at the line under the cursor; after that, every rebuild moves
   Skim to the cursor. Skim stays in the background.
4. In Skim, **Cmd+Shift+click** jumps back to that line in Neovim.
5. `,le` lists errors and warnings; `Enter` on one goes to the line.

The PDF, the bibliography and the auxiliary files go to `build/` next to the main file, so
the project folder keeps only sources. A `.bib` next to it is picked up (BibTeX). For another
engine, put `% !TEX program = lualatex` on the first line. To build and save by hand only, set
`latex_live = false` in `lua/config/local.lua`. A `latexmkrc` inside a project wins
over the linked `~/.latexmkrc`.

| Key | Does |
|---|---|
| `,ll` | stop or start the continuous build |
| `,lv` | show the PDF at the cursor (forward search) |
| `,le` | errors and warnings |
| `,lt` | table of contents (jump to a section) |
| `,lw` | count words |
| `,lc` / `,lC` | clean auxiliary files / also the PDF |
| `,lk` | stop the build |
| `,lx` | reload vimtex after editing the preamble |
| `za` / `zR` / `zM` | fold or unfold a section / open all / close all |

### Snippets

Snippets marked **auto** expand as you type. The others appear in the completion menu when
you type their name: pick one with `Tab` and accept with `Enter`. Inside a snippet, `Tab` and
`S-Tab` jump between its fields. Nothing expands right after a `\`, so `\sum` or `\begin`
typed by hand stays as typed.

#### Documents

| Type | Inserts |
|---|---|
| `doc` | an article skeleton (fonts, babel, amsmath) |
| `bdoc` | a beamer presentation skeleton |
| `abnt` | a complete abnTeX2 thesis: cover, abstract in two languages, contents, bibliography |
| `capa`, `resumo`, `abstract` | the abnTeX2 pieces, one by one |

#### Text (outside math)

| Type | Inserts |
|---|---|
| `mk` (auto) | inline math `$…$` |
| `dm` (auto) | display math `\[ … \]` |
| `beg` (auto, at the start of a line) | `\begin{…} … \end{…}`, the name typed once |
| `sec`, `ssec`, `sssec` | section, subsection, subsubsection, each with a `\label` |
| `fig` / `tab` | a figure / a table, centered, with caption and label |
| `ite`, `enu`, `desc` | itemize, enumerate, description |
| `eqn`, `ali`, `gat` | `equation*`, `align*`, `gather*` (`eqnn`, `alin`: numbered) |
| `thm`, `lem`, `prf`, `def` | theorem, lemma, proof, definition |
| `cit`, `citp`, `citt` | `\cite`, `\citep`, `\citet` |
| `citeonline`, `apud`, `citacao` | the abnTeX2 citations |
| `ref`, `eqr`, `lab` | `\ref`, `\eqref`, `\label` |
| `tbf`, `tit`, `emp`, `foot` | bold, italic, emphasis, footnote |
| `frm`, `col`, `blk` | a beamer frame, two columns, a block |

#### Math (all auto, only inside math)

| Type | Gives |
|---|---|
| `//` | `\frac{}{}`; `a//` and `(a+b)//` use what is before as the numerator |
| `x12` | `x_{12}` |
| `__` / `td` | subscript `_{}` / superscript `^{}` |
| `sr` / `cb` | `^2` / `^3` |
| `;a`, `;b`, `;l`, `;S`, … | Greek letters: `\alpha`, `\beta`, `\lambda`, `\Sigma` |
| `<=`, `>=`, `!=`, `->`, `=>`, `~~` | `\leq`, `\geq`, `\neq`, `\to`, `\implies`, `\approx` |
| `<=>`, `<->` | `\iff`, `\leftrightarrow` |
| `RR`, `NN`, `ZZ`, `QQ`, `CC` | `\mathbb{R}`, `\mathbb{N}`, … |
| `inn`, `sub`, `cap`, `cup`, `EE`, `AA` | `\in`, `\subset`, `\cap`, `\cup`, `\exists`, `\forall` |
| `**`, `xx`, `...`, `ooo` | `\cdot`, `\times`, `\dots`, `\infty` |
| `sum`, `prod`, `lim`, `int`, `dint` | with their limits filled in to edit |
| `sq`, `bar`, `hat`, `vec`, `txt` | `\sqrt{}`, `\overline{}`, `\hat{}`, `\vec{}`, `\text{}` |
| `part` | `\frac{\partial }{\partial }` |
| `mbb`, `mcal`, `mbf` | `\mathbb{}`, `\mathcal{}`, `\mathbf{}` |

### Spelling and grammar

| Key | Does |
|---|---|
| `]s` / `[s` | next / previous misspelled word |
| `z=` | suggestions for the word under the cursor |
| `zg` | accept the word everywhere (saved in `config/nvim/spell/en.utf-8.add`) |
| `Space u s` | spelling on or off |
| `Space u G` | grammar (ltex-ls-plus) on or off |

Grammar is checked in Portuguese (`pt-BR`). A comment `% LTeX: language=en-US` switches it
from that line on.

## Markdown and notes

### Any Markdown file

| Key | Does |
|---|---|
| `,p` | build an HTML preview with pandoc and open it in the browser; every save rebuilds it |
| `Space u m` | rendered view (headings, tables, checkboxes) on or off |
| `gd` | follow a link to another file |

rumdl underlines problems as you type (rules in `config/rumdl/rumdl.toml`). It reformats on
save only in projects with a `.rumdl.toml` or `.markdownlint.*`, so nobody else's files are
restyled.

### Notes

Notes are plain `.md` files in `~/notes` (change it with `notes.dir` in
[`local.lua`](#per-machine-settings)), handled by obsidian.nvim. No Obsidian app or account is
needed. The folder is created the first time a note is opened.

| Key | Does |
|---|---|
| `Space n n` | new note: asks for a title and creates `the-title.md` starting with `# The title` |
| `Space n d` | today's note in `daily/` (`2026-10-13.md`) |
| `Space n f` / `Space n g` | find a note by name / search the text of all notes |
| `Space n b` | notes that link to this one (with the cursor off the title; on a `#` heading it lists links to that heading) |
| `[[` | link to another note: completes their names as you type |
| `Enter` or `gd` on a link | open the linked note |
| `]o` / `[o` | next / previous link |
| `Enter` on a checkbox | tick or untick it |

## Shell, prompt and terminal

- **zsh**: `~/.zshrc` gets one marked block (`# >>> dotfiles >>>`) that sources
  `config/zsh/dotfiles.zsh`: Homebrew on `PATH`, a valid `LANG`, Homebrew's Java as
  `JAVA_HOME` (Clojure needs it), Neovim as `EDITOR` and `VISUAL`, a 50,000-line history shared
  by every open shell, the Starship prompt, and two helpers: `path_report` lists `PATH` in order
  and `command_origin <name>…` says which program runs and whether Homebrew installed it.
  Everything else in `~/.zshrc` stays yours.
- **Starship** (`config/starship/starship.toml`): folder, git branch and status, the
  language versions of the project, how long the last command took and the time, in Dracula
  colors.
- **iTerm2** (`config/iterm2/dracula.json`): the "Dotfiles (Dracula)" profile with JetBrains
  Mono Nerd Font, which the icons in Neovim and the prompt need.
- **latexmk** (`config/latex/latexmkrc`, linked to `~/.latexmkrc`): PDF output, BibTeX when a
  `.bib` exists, and what `,lc` cleans.
- **rumdl** (`config/rumdl/rumdl.toml`): the Markdown lint rules, used by Neovim and by
  `rumdl check` in a shell.

## On a machine that is not yours

Install the Neovim part only (`macos/nvim/install.sh`): it leaves the shell, the prompt and the terminal
untouched. Then:

- Do not put personal tokens or SSH keys there; log in with a short-lived, narrow token, or
  none, and run `gh auth logout` or delete it when you leave.
- Do not trust a `.nvim.lua` from a repository you did not write; `exrc` asks before running
  one, so answer no.
- Before running anything on a fresh clone, read `git log` for commits you do not recognise.
- When you leave, remove `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim` and
  `~/.cache/nvim`.

GitHub checks this repository on every push and every Monday: ShellCheck on the scripts,
gitleaks on the history, zizmor and CodeQL on the workflows, and OSSF Scorecard on the
repository settings. To see the score, open
`https://scorecard.dev/viewer/?uri=github.com/aguiar-arthur/dotfiles`.

## Update

| What | How |
|---|---|
| Programs | `brew update && brew upgrade` |
| Neovim plugins | `:Lazy update`, then commit `config/nvim/lazy-lock.json` if all is well |
| Neovim plugins, roll back | `git restore config/nvim/lazy-lock.json`, then `:Lazy restore` |
| Mason servers and tools | `:Mason`, then `U` |

## Check

Nothing here changes anything; each command says what is missing or wrong.

| What | How | All good when |
|---|---|---|
| Programs | `brew bundle check --verbose --file ~/dotfiles/macos/<part>/Brewfile` (`nvim`, `terminal`, `apps`) | `The Brewfile's dependencies are satisfied.` |
| Links, `~/.zshrc`, app preferences | `~/dotfiles/macos/nvim/link.sh` and `~/dotfiles/macos/terminal/link.sh` (fix what differs) | every line starts with `ok` |
| Neovim starts cleanly | `nvim --headless "+qa"` | it prints nothing |
| Everything inside Neovim | `:checkhealth` | no `ERROR` |
| Language servers in this buffer | `:checkhealth vim.lsp` | the server is under "Active Clients" |
| Plugins | `:Lazy` | nothing in red |
| Servers and tools from Mason | `:Mason` | all installed |
| Treesitter parsers | `:checkhealth nvim-treesitter` | the `tree-sitter` CLI is found, parsers listed |
| Formatters for this buffer | `:ConformInfo` | the formatter shows as ready |
| Secrets in the history | `gitleaks detect` | `no leaks found` (GitHub runs it, ShellCheck and zizmor weekly and on every push) |

Run `:checkhealth` in a real Neovim window: in `nvim --headless` the Snacks checks report
errors that are not real. When a check fails, `macos/install.sh` (or the part's) is the fix for anything
missing (a program, a server, a parser): it installs only what is not there.

## Test

`tests/nvim.sh` checks the Neovim setup after a change. It is run by hand, never touches the
real home (not even your sessions) and fails if `lazy-lock.json` changes. Checks whose program
is missing are skipped.

| Mode | Command | Takes | Checks |
|---|---|---|---|
| quick (default) | `~/dotfiles/tests/nvim.sh` | seconds | startup, every Lua module, the lockfile, Skim preferences, Mason's Python tools (broken by a Homebrew Python upgrade), `zg` writing to the versioned word list, stylua, shell syntax, `EDITOR` in zsh, shfmt, rumdl, no comments, and our own code headless: `Space c s`, filetypes, format on save, the `Space u` toggles, `]e`, the preview, the helpers |
| full | `~/dotfiles/tests/nvim.sh full` | minutes | quick, plus a real Neovim driven in tmux: language servers, toggles, the look, Markdown and notes, the `,` keys, `,r`, the debugger, tests, a LaTeX build and its snippets, a `Space g V` review, `,cj` |
| fresh | `~/dotfiles/tests/nvim.sh fresh` | longer | full, in a throwaway directory deleted at the end, as on a new machine |

`full` installs Neovim with `macos/nvim/install.sh` into an isolated home under
`~/.cache/dotfiles-nvim-test`; later runs reuse it. It drives Neovim through `tmux`, which the
terminal part installs (`macos/terminal/install.sh`); without it those checks are skipped.

When to run which:

1. After any change: `quick`.
2. After changing plugins, keys, language servers, Markdown or LaTeX: `full`.
3. Before trusting the setup on a new machine, or after changing `macos/`: `fresh`.

Each check prints one line: `pass`, `skip` with the reason, or `FAIL` with what was wanted and
what came back. The last line is the count, for example `65 passed, 0 failed, 0 skipped`.

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

It only reads, zips a report into `Documents\diagnostics`, and asks before any repair. Its
options and what it collects are in [docs/windows.md](docs/windows.md).

## Layout

```text
config/nvim/      Neovim (lazy.nvim, native LSP)
config/zsh/       dotfiles.zsh, sourced from ~/.zshrc
config/starship/  starship.toml
config/iterm2/    dracula.json (Dynamic Profile)
config/rumdl/     Markdown lint rules
config/latex/     latexmkrc (linked to ~/.latexmkrc)
macos/            the macOS install:
  install.sh      runs every part
  lib.sh          what the parts share
  nvim/           Brewfile, install.sh, link.sh: Neovim and what it needs
  terminal/       Brewfile, install.sh, link.sh: Starship, tmux, iTerm2, ~/.zshrc
  apps/           Brewfile, install.sh: the other programs
SECURITY.md       how to report a problem
.github/          the security workflows and Dependabot
tests/            the Neovim checks: nvim.sh runs them (quick, full, fresh), one file per area
windows/          collect-diagnostics.ps1: debug a Windows PC's health (docs/windows.md)
docs/             how each context works and why, for you and for AI assistants
AGENTS.md         rules and the context map for AI assistants (CLAUDE.md points to it)
```

MIT, see [LICENSE](LICENSE).
