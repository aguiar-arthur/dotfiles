# Install

Getting a Mac from nothing to this setup, and keeping it there: Homebrew and the parts in
`macos/` (their Brewfiles, `install.sh` and `link.sh`), the Mason packages, parsers and spell
files Neovim needs, the plugin lockfile, and the shell, prompt and terminal. Its relationships
are in [map](map.md).

## Language

- **part**: one folder in `macos/` (`nvim`, `terminal`, `tmux`, `apps`) with its own `Brewfile`,
  `install.sh` and (all but apps) `link.sh`; it installs alone, so a machine whose shell and
  terminal must stay as they are runs only `macos/nvim/install.sh` (and `macos/tmux/install.sh`
  for tmux, which is a part of its own for that reason).
- **step**: one of `brew`, `link`, `whichkey`, `nvim` in a part's `install.sh`; a failed step
  does not stop the others, and a failed part does not stop `macos/install.sh`.
- **lockfile**: `config/nvim/lazy-lock.json`, the plugin commits; the way back after a bad
  update.

## Files

| Path | Holds |
|---|---|
| `macos/install.sh` | runs every part: terminal, tmux, apps, nvim |
| `macos/lib.sh` | what the parts share: `step_brew` (trusting third-party taps first), `step_link`, `run_steps`, `link` with backups, `pref` |
| `macos/nvim/` | `Brewfile` (what Neovim needs), `install.sh` (brew, link, nvim), `link.sh` (`~/.config/nvim`, rumdl, `~/.latexmkrc`, Skim) |
| `macos/terminal/` | `Brewfile` (Starship, eza, iTerm2, the font), `install.sh` (brew, link), `link.sh` (Starship, the iTerm2 profile and default, `~/.zshrc`) |
| `macos/tmux/` | `Brewfile` (tmux, lazygit for `prefix G`), `install.sh` (brew, link, whichkey), `link.sh` (`~/.config/tmux/tmux.conf`), `whichkey.sh` (the whichkey-tmux clone in `~/.config/tmux/plugins/`) |
| `macos/apps/` | `Brewfile` (programs that are neither), `install.sh` (brew) |
| `config/nvim/lua/dotfiles/install.lua` | headless install of Mason packages, parsers and spell files, with time limits |
| `config/nvim/lua/dotfiles/mason.lua` | which Mason packages the settings want and which are missing or broken |
| `config/nvim/lua/config/lazy.lua` | lazy.nvim cloned at the lockfile's commit |
| `config/nvim/lazy-lock.json` | plugin versions (committed) |
| `config/zsh/dotfiles.zsh` | Homebrew on `PATH` (Apple Silicon or Intel), a valid `LANG`, `JAVA_HOME`, `EDITOR` / `VISUAL`, history, emacs keys, the eza aliases (`ls`, `ll`, `lt`), `path_report`, `command_origin`, Starship, `prompt_gap` and `clear` (the blank line between prompts) |
| `config/starship/starship.toml` | the prompt: rounded pills on rows with a left bracket and fading lines, Dracula colors |
| `config/tmux/tmux.conf` | tmux: Dracula status bar with pills for the session, the current window and the clock, true color and focus events for Neovim, `C-h/j/k/l` across panes (not into Neovim), splits in the pane's folder, lazygit and scratch popups, vi copy mode to `pbcopy`, no `GIT_EDITOR`, menus in the terminal's colors, whichkey-tmux in auto mode (when it is there) |
| `config/iterm2/dracula.json` | the "Dotfiles (Dracula)" Dynamic Profile, with iTerm2's own Powerline glyphs and opaque cell backgrounds for the pills |

## How it works

`macos/install.sh` runs the parts' `install.sh` (terminal, tmux, apps, nvim) and ends with `Done.`
or `Failed: <parts>`; each part runs its steps in order (`brew`, `link`, then `nvim` for
Neovim) and ends with `Done: <part>.` or `Failed: <steps>`. The nvim step needs
`~/.config/nvim` to link to this repository, so Neovim uses the same config as every day:
`Lazy! restore` puts plugins at the lockfile's commits (and runs their `build` steps, such as
codediff's library), then `dotfiles.install` installs the Mason packages, the parsers (with
the `tree-sitter` CLI) and the non-English spell files. Everything is idempotent and only does
what is missing; already installed programs are not upgraded (`brew bundle --no-upgrade`).

The tmux part's `whichkey` step runs `whichkey.sh`: it clones whichkey-tmux into
`~/.config/tmux/plugins/whichkey-tmux` when that folder is missing, says `ok` when it already
holds a clone of it, and stops with an error, touching nothing, when it holds anything else.
It never pulls: an update is on purpose (see [Updating](#updating)).

Each `link.sh` links its files, moving whatever was there to `<name>.bak.<timestamp>` (the three
newest are kept; each older one is named with `prune` as it is deleted), and writes its app's
preferences with `defaults` (Skim, iTerm2); the terminal one also
adds one marked block (`# >>> dotfiles >>>`) to `~/.zshrc` that sources `dotfiles.zsh`. Every
line they print starts with `ok` when nothing had to change.

## Contract

Offers: every program, link, Mason package, parser and spell file the other contexts assume is
there ([code](code.md) servers, [git](git.md) codediff library, [latex](latex.md) Skim and
`~/.latexmkrc`).

Consumes: [core](core.md) `settings` (which servers, tools, parsers and spell languages).

## Pitfalls

- The scripts live in `macos/` but link from the repository root (`DOT` in `lib.sh` is its
  parent folder), so `config/` stays where it is and they run from any working directory; a
  part finds its own `Brewfile` and `link.sh` through `HERE`, set before it sources `lib.sh`.
- Homebrew loads a formula or cask from a third-party tap (`owner/tap/name` in a Brewfile) only
  once it is trusted; `step_brew` runs `brew trust` for each before `brew bundle`.
- `:Lazy update` and `:Lazy sync` rewrite `lazy-lock.json`; never run them just to check
  something. The tests fail if the lockfile changes.
- Mason installs nothing when Neovim starts: a new server needs `macos/nvim/install.sh` again
  (`dotfiles/install.lua`; mason-tool-installer was dropped, it only duplicated that).
- Mason's Python tools (basedpyright, debugpy) run from a venv tied to Homebrew's Python minor
  version; a `brew upgrade` to a new one leaves them unable to start while Mason still calls
  them installed. `dotfiles.mason` counts such a package as missing, so `macos/nvim/install.sh`
  reinstalls it, and the quick tests say when one is broken.
- Every network step needs a timeout or a failure path: the Mason registry waits a minute, its
  installs 15 minutes, a spell file two, the Homebrew installer's download two (checked before it
  runs: `bash -c` of an empty download would succeed), the lazy.nvim clone two, the whichkey-tmux
  clone two (without asking for a password, and removed when it fails half-way) and
  `Lazy! restore` 15; a failed Homebrew or plugin step fails its step.
- zsh picks vi keys when `EDITOR` or `VISUAL` already holds `vi` at its start, so with
  `EDITOR=nvim` the first shell had emacs keys and a shell that inherited it (nested, or a tmux
  pane) had vi keys, with `Ctrl-r` and `Ctrl-a` doing nothing useful; `bindkey -e` keeps them all
  the same. The block runs last in `~/.zshrc`, so a `bindkey -v` above it loses: change that line.
- eza is not a drop-in `ls`: its `-t` takes a field, so `ls -lt` and `ls -ltr` fail with an error.
  `lt` is the same listing and `command ls` the system's. The aliases exist only in an interactive
  shell, so a script that sources `~/.zshrc` keeps the real `ls`.
- Starship's `add_newline` also puts a blank line above the first prompt of a window, so it is
  off and the `prompt_gap` precmd hook prints the line from the second prompt on; `clear` is a
  function so that the prompt after it stays at the top. The hook is added after Starship's,
  which reads `$?` and would otherwise see the hook's status instead of the command's.
- A prompt pill is a cell background between two font glyphs (U+E0B6, U+E0B4), so the iTerm2
  profile keeps two settings: `Draw Powerline Glyphs`, or the caps stop short of a cell made
  taller by `Vertical Spacing`, and `Only The Default BG Color Uses Transparency`, or the middle
  is tinted and the caps are not. The glyphs, in `starship.toml` and `tmux.conf`, are private-use
  characters that are easy to lose in an editor: check them with `python3` and `unicode_escape`.
- tmux 3.8 underlines the current window by default (`window-status-current-style`), which runs
  under the pill's round caps, so `tmux.conf` sets that style to `default`.
- Pills fill their row's whole height at any `Vertical Spacing`, so two stacked rows of pills
  touch. The prompt keeps a `│` row between its two pill rows and shows a failed status on the
  first row, so the row you type on never holds a pill.
- iTerm2 paints what is left of a window below its last whole row in the bar's color, so a tall
  rest makes the tmux bar look twice its height, and tmux cannot change it. `Vertical Spacing`
  1.05 gives rows of 19 pt, which fill a full-screen window of 900 pt to 5 pt (1.1 gave 20 pt
  rows and a rest of 18 pt); `tmux display -p '#{client_height} #{client_cell_height}'` shows the
  result, and another screen size may need another value.
- A tmux server keeps the environment of the shell that started it, and Claude Code's shells
  set `GIT_EDITOR=true`; one tmux started from there made `git commit` and `git merge` skip
  the editor in every pane, so `tmux.conf` unsets it.
- tmux stays independent of the Neovim config: `C-h/j/k/l` move between panes except in a
  pane running Neovim (found with `ps` on the pane's tty), where the key goes to Neovim and
  `prefix` with an arrow leaves it. Making Neovim hand the key back needs a plugin on its side
  (vim-tmux-navigator), which was left out on purpose.
- tmux 3.8 uses `prefix g` for its floating panes, so lazygit is on `prefix G`. The scratch
  popup is a session named `scratch` attached inside `display-popup`.
- `detach-on-destroy` is `on`: with `off`, closing a session's last pane moved you into any other
  session, even a forgotten one with an old shell, and exiting the scratch popup's shell switched
  the popup to another session. Other sessions keep running after you leave (`tmux ls`).
- whichkey-tmux lives in `~/.config/tmux/plugins/`, where TPM would put it, outside this
  repository: it is a project of its own with its own git history. `tmux.conf` loads it through
  `if-shell`, so on a machine without it tmux still starts, with the prefix on `Ctrl-b`.
- In auto mode whichkey-tmux takes over the prefix (`tmux show -g prefix` prints `None` and the
  key is bound in the root table); reloading `tmux.conf` keeps that right, and its own README
  says how to undo it. `set -g theme terminal` (tmux 3.6 and later) gives tmux's menus and
  popups the terminal's palette instead of tmux's own greys.
- Only plugins and parsers are pinned. Mason packages take whatever the registry offers when
  they are installed, Homebrew programs stay at their version (`--no-upgrade`), and the nREPL and
  CIDER versions are in the `versions` table of `dotfiles/clojure.lua`: none of them moves until
  [Updating](#updating) says so.

## Checks

| What | Where |
|---|---|
| Mason wanted, missing and broken lists, spell files to fetch, the parsers still missing | `tests/install.lua` |
| Mason's Python tools on this machine can start | quick: `Mason's Python tools still have their Python` |
| Starting Neovim leaves the lockfile alone | quick: `starting nvim leaves lazy-lock.json alone` |
| Shell syntax and format of the scripts | quick: `shell syntax`, `shfmt` |
| `tmux.conf` loads and keeps `GIT_EDITOR` out of the panes | quick: `tmux: the config loads and git commit opens Neovim` (`tests/tmux.sh`) |
| `C-h/j/k/l` across a shell and a Neovim pane, the scratch popup | quick: `tmux: C-h/j/k/l cross panes but not Neovim, prefix t toggles the scratch popup`, through a client attached with `script` |
| `tmux.conf` loads, with the prefix on `Ctrl-b`, where whichkey-tmux is not installed | quick: `tmux: the config loads without whichkey-tmux` |
| `whichkey.sh` keeps a clone of whichkey-tmux and refuses any other folder, without network | quick: `tmux: the whichkey step keeps its clone and refuses anything else` |
| `dotfiles.zsh` makes Neovim the editor, without comments | quick: `zsh: Neovim is the editor`, `no comments in Lua, shell and PowerShell` |
| Emacs keys with `EDITOR` inherited; `ls`, `ll`, `lt` run eza, and a script keeps `ls` | quick: `zsh: emacs keys, even with EDITOR=nvim inherited from a parent shell`, `zsh: ls, ll and lt run eza in a shell, a script keeps ls` |
| A blank line between prompts, none above the first or after `clear`, and the hook after Starship's | quick: `zsh: a blank line between prompts, none above the first or after clear` |
| `macos/nvim/install.sh` in an empty home | full: `install` in `tests/lib.sh`; `fresh` in a throwaway folder |

## Updating

Nothing updates itself, so do it on purpose, on a branch, and run the tests before you keep it:

1. Plugins: `nvim --headless "+Lazy! update" +qa` (the one time `:Lazy update` is right), then read
   `git diff config/nvim/lazy-lock.json`. `:Lazy restore` or `git checkout` of the lockfile is
   the way back.
2. Parsers: `:TSUpdate`. Mason packages: `:Mason`, then `U`.
3. Programs: `brew upgrade` (the install scripts never do), then `macos/nvim/install.sh` so
   Mason's Python tools get a venv for the new Python.
4. Clojure: the newest `nrepl/nrepl` and `cider/cider-nrepl` on Clojars go in the `versions`
   table of `dotfiles/clojure.lua`.
5. whichkey-tmux: `git -C ~/.config/tmux/plugins/whichkey-tmux pull`, then `prefix r`.
6. `tests/nvim.sh full`. After a Neovim update also check `ui2` in a real terminal (see
   [core](core.md)); if it breaks, deleting its line in `options.lua` is the way out.
7. Commit the lockfile and the version table together.

## Changing it

- **A program**: one line in the `Brewfile` of the part that needs it (`macos/apps/Brewfile`
  when it belongs to no other part); a third-party tap needs nothing more, `step_brew`
  trusts it. Then the README's part table.
- **A Mason tool, parser or spell language**: the list in `settings.lua` (see [core](core.md));
  `install.lua` picks it up.
- **A new link**: one `link <src> <dst>` line in the part's `link.sh`; then the README's "What
  the `link.sh` files do".
- **A new part**: a folder in `macos/` with a `Brewfile` and an `install.sh` that sets `HERE`,
  sources `../lib.sh` and calls `run_steps`; add it to the loop in `macos/install.sh` and to
  the README's part table.
