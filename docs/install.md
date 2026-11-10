# Install

Getting a Mac from nothing to this setup, and keeping it there: Homebrew and the parts in
`macos/` (their Brewfiles, `install.sh` and `link.sh`), the Mason packages, parsers and spell
files Neovim needs, the plugin lockfile, and the shell, prompt and terminal. Its relationships
are in [map](map.md).

## Language

- **part**: one folder in `macos/` (`nvim`, `terminal`, `tmux`, `apps`) with its own
  `Brewfile`, `install.sh` and (all but apps) `link.sh`; it installs alone, so a machine whose
  shell and terminal must stay as they are runs only `macos/nvim/install.sh` (and
  `macos/tmux/install.sh` for tmux, which is a part of its own for that reason).
- **step**: one of `brew`, `link`, `whichkey`, `nvim` in a part's `install.sh`; a failed step does
  not stop the others, and a failed part does not stop `macos/install.sh`.
- **lockfile**: `config/nvim/lazy-lock.json`, the plugin commits; the way back after a bad
  update.

## How it works

`macos/install.sh` runs the parts' `install.sh` (terminal, tmux, apps, nvim) and ends with
`Done.` or `Failed: <parts>`; each part runs its steps in order (`brew`, `link`, then `nvim` for
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

TeX is MacTeX without its GUI apps (`mactex-no-gui`, several GB), because LaTeX is only used from
Neovim: every package and program a document or the config asks for (latexmk, chktex, texcount,
abnTeX2) is there, so there is no list to keep. latexindent comes from Homebrew, with its Perl
modules: TeX Live's stops at `YAML::Tiny`, which macOS's Perl lacks, and Homebrew's comes first on
`PATH`.

Each `link.sh` links its files, moving whatever was there to `<name>.bak.<timestamp>` beside it
(the iTerm2 profile's goes to the `iTerm2` folder above `DynamicProfiles`; the three
newest are kept; each older one is named with `prune` as it is deleted), and writes its app's
preferences with `defaults` (Skim, iTerm2); the terminal one also
adds one marked block (`# >>> dotfiles >>>`) to `~/.zshrc` that sources `dotfiles.zsh`. Every
line they print starts with `ok` when nothing had to change.

## Pitfalls

- The scripts live in `macos/` but link from the repository root (`DOT` in `lib.sh` is its
  parent folder), so `config/` stays where it is and they run from any working directory; a
  part finds its own `Brewfile` and `link.sh` through `HERE`, set before it sources `lib.sh`.
- iTerm2 loads every file in `DynamicProfiles` except those starting with `.` or ending in `~`,
  so a backup of the profile there would load as a second profile with the same Guid; `link`
  takes a third argument, where the backup goes, and the terminal part uses it.
- Homebrew loads a formula or cask from a third-party tap (`owner/tap/name` in a Brewfile) only
  once it is trusted; `step_brew` runs `brew trust` for each before `brew bundle`.
- `:Lazy update` and `:Lazy sync` rewrite `lazy-lock.json`; never run them just to check
  something. The tests fail if the lockfile changes.
- Mason installs nothing when Neovim starts: a new server needs `macos/nvim/install.sh` again.
- Mason's Python tools (basedpyright, debugpy) run from a venv tied to Homebrew's Python minor
  version; a `brew upgrade` to a new one leaves them unable to start while Mason still calls
  them installed. `dotfiles.install.mason` counts such a package as missing, so `macos/nvim/install.sh`
  reinstalls it, and the quick tests say when one is broken.
- Every network step needs a timeout or a failure path (the numbers are in the scripts). The
  Homebrew installer's download is checked before it runs: `bash -c` of an empty download would
  succeed. A headless Neovim stays open after a Lua error, so `run()` catches each step's error and
  the command ends with `+cquit 1`: an error there fails the step instead of hanging it.
- The zsh block runs last in `~/.zshrc`, so a `bindkey -v` above it loses. fzf's keys come from
  `fzf --zsh` after `bindkey -e`, since `bindkey -e` would reset them. `Alt-c` reaches zsh because
  the iTerm2 profile sends the left Option as `Esc+` (Neovim's `<A-j>` / `<A-k>` too); the right
  Option stays normal, so it still types the characters a keyboard layout puts on it (accents,
  `[`, `{`). The eza aliases, fzf keys and completion exist only in an interactive shell, so a
  script that sources `~/.zshrc` keeps the real `ls`.
- Starship's `add_newline` also puts a blank line above the first prompt of a window, so it is
  off and the `prompt_gap` precmd hook prints the line from the second prompt on; `clear` is a
  function so that the prompt after it stays at the top. The hook is added after Starship's,
  which reads `$?` and would otherwise see the hook's status instead of the command's.
- A prompt pill is a cell background between two private-use glyphs (U+E0B6, U+E0B4), easy to
  lose in an editor: check them with `python3` and `unicode_escape`. The iTerm2 profile keeps
  `Draw Powerline Glyphs` (or the caps stop short of a cell made taller by `Vertical Spacing`) and
  `Only The Default BG Color Uses Transparency` (or the middle is tinted and the caps are not).
  iTerm2 paints what is left of a window below its last whole row in the bar's color, so a tall
  rest makes the tmux bar look twice its height, and tmux cannot change it: `Vertical Spacing`
  1.05 gives rows of 19 pt, which fill a full-screen window of 900 pt to 5 pt.
  `tmux display -p '#{client_height} #{client_cell_height}'` shows the result, and another screen
  size may need another value.
- `C-h/j/k/l` move between panes, except in a pane running Neovim (found with `ps` on the
  pane's tty), where tmux hands the key to Neovim. vim-tmux-navigator, on Neovim's side, moves
  between its windows and, at the edge, runs `tmux select-pane`, so one key crosses both. Without
  it the key could enter Neovim but never leave, and `prefix` with an arrow was needed.
- Git reads `~/.config/git/config` and `~/.config/git/ignore` on its own, so linking them needs no
  `include` and leaves `~/.gitconfig` alone; that file wins over them, so a machine's name, email,
  credentials and exceptions stay there and out of the repository. They belong to the terminal
  part, so a machine that must stay as it is does not get them from `macos/nvim/install.sh`.
- `config/git/config` holds no `pull.rebase`, signing or pager on purpose: the first changes what
  every `git pull` does, the second needs a chosen key, the third a program.
  `merge.conflictStyle = zdiff3` adds the original text to conflict markers; codediff's conflict
  view works the same with it. `rerere` replays a recorded resolution without asking, but does not
  stage it.
- lazygit's theme is linked to its default path and not pointed at with `LG_CONFIG_FILE`: that
  variable naming a missing file makes lazygit exit, so `prefix G` would break until `link.sh` ran.
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

`tests/install.lua`; quick: the zsh, tmux (`tests/tmux.sh`), shell and lockfile checks in
`tests/nvim.sh`; full: `install` in `tests/lib.sh`, and `fresh` in a throwaway folder.
`tests/nvim.sh` prints what each check covers.

## Updating

Nothing updates itself, so do it on purpose, about once a month (Dependabot only bumps the
workflows' actions), on a branch, and run the tests before you keep it:

1. Plugins: `nvim --headless "+Lazy! update" +qa` (the one time `:Lazy update` is right), then read
   `git diff config/nvim/lazy-lock.json`. `:Lazy restore` or `git checkout` of the lockfile is
   the way back.
2. Parsers: `:TSUpdate`. Mason packages: `:Mason`, then `U`.
3. Programs: `brew upgrade` (the install scripts never do), then `macos/nvim/install.sh` so
   Mason's Python tools get a venv for the new Python. Within a year,
   `sudo tlmgr update --self --all` updates the TeX packages.
4. Clojure: the newest `nrepl/nrepl` and `cider/cider-nrepl` on Clojars go in the `versions`
   table of `dotfiles/clojure.lua`.
5. whichkey-tmux: `git -C ~/.config/tmux/plugins/whichkey-tmux pull`, then `prefix r`. zizmor:
   the newest version on PyPI in the `pipx run zizmor==…` line of `security.yml`.
6. `tests/nvim.sh full`. After a Neovim update also check `ui2` in a real terminal (see
   [core](core.md)); if it breaks, deleting its line in `options.lua` is the way out.
7. Commit the lockfile and the version table together.

## Changing it

- **A program**: one line in the `Brewfile` of the part that needs it (`macos/apps/Brewfile`
  when it belongs to no other part); a third-party tap needs nothing more, `step_brew`
  trusts it. Then the README's part table.
- **A Mason tool, parser or spell language**: the list in `settings.lua` (see [core](core.md));
  `install.lua` picks it up.
- **A new link**: one `link <src> <dst>` line in the part's `link.sh`; then the README's part
  table and "What the `link.sh` files do".
- **A new part**: a folder in `macos/` with a `Brewfile` and an `install.sh` that sets `HERE`,
  sources `../lib.sh` and calls `run_steps`; add it to the loop in `macos/install.sh` and to
  the README's part table.
