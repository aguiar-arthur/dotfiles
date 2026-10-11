# Testing

`test/run.sh` checks the health of the whole configuration with the tools each editor already
ships. There is no unit-test framework for individual functions: a configuration is
declarative, and what breaks it is integration (an updated plugin, a key that disappeared, a
module that fails to load). The checks therefore start the real editors and inspect the real
result.

```sh
test/run.sh              # everything
test/run.sh static       # one level: static | scripts | smoke | keys | behavior
test/run.sh all --clean  # forget the cached plugins and packages first
```

The exit status is non-zero when anything fails, and every line says what passed, failed or
was skipped. A missing tool is a skip locally and a failure when `DOTFILES_TEST_STRICT=1`
(which CI sets).

`dotfiles test …` is the same command from anywhere. The pre-commit hook runs `static` on
every commit.

## The five levels

| Level | Takes | Needs | Catches |
|---|---|---|---|
| `static` | seconds | `emacs`, `nvim`, `python3`, `shfmt`, `stylua`, `rumdl`, `gitleaks`, `zsh` | syntax, formatting, lint, broken links, secrets, comments in code |
| `scripts` | 15 s | `git`, `zsh` | `install.sh`, `link.sh`, `bin/dotfiles` and the hook misbehaving |
| `smoke` | 1 min, plus the first install | `nvim`, `emacs`, `git`, network on first run | a config that no longer starts |
| `keys` | 1 min | `nvim`, `emacs`, `python3`, `git` | a key that drifted from `docs/keymaps.md` |
| `behavior` | 45 s | `nvim`, `emacs`, `git` | a regression of an invariant from `AGENTS.md` |

### static

- `bash -n` and `shfmt -d` on every shell script, `stylua --check` on every Lua file (rules in
  `config/nvim/stylua.toml`: two spaces, 100 columns; shell follows `.editorconfig`),
  `rumdl check` on the Markdown, and a JSON parse of the lock file and the iTerm2 profile.
- Every `.el` file passes `check-parens` and starts with the `lexical-binding` header.
- No comments anywhere, found by parsing rather than by regex: treesitter for Lua,
  `comment-search-forward` for Emacs Lisp, `shfmt --to-json` for shell, `tokenize` for Python
  and quote-aware scanning for TOML, YAML, the Brewfile and the dotfiles. The `#!` line and
  the `lexical-binding` header are the only exceptions. Shell files are found by extension or
  by a `bash` shebang (`bin/dotfiles`, `.githooks/pre-commit`).
- `zsh -n` on `config/zsh/*.zsh`, and `gitleaks dir` on a copy of the tracked files (so the
  plugin cache never produces false alarms). rumdl also checks that relative links between
  pages resolve.

### scripts

A copy of the repository (its tracked files, committed into a fresh git repository) and a
throwaway `HOME` whose `~/.zshrc` has the old two-block layout. For `link.sh`, checks that:

- `--check` reports pending changes, then nothing after a run;
- the links point into the copy and a replaced directory is backed up, keeping only three;
- `~/.zshrc` keeps the user's lines, ends with exactly one block and loses the old ones; a
  second run changes nothing;
- sourcing `dotfiles.zsh` sets `DOTFILES` and puts `dotfiles` on `PATH`;
- `dotfiles` rejects unknown commands, lists backups and `rollback emacs` restores one;
- the pre-commit hook passes on a clean tree and blocks a comment in code;
- `--uninstall` removes the links, the block and the hook and keeps the user's lines.

For `install.sh`, `brew`, `nvim` and `emacs` are stubs that record how they were called, so
nothing is downloaded. Checks that:

- unknown groups and steps are rejected;
- `brew bundle` runs on the Brewfile and only on the groups asked for (`--all`: every group);
- Neovim restores the lock and runs the headless installer, Emacs loads the configuration,
  and both read it from the repository (`XDG_CONFIG_HOME`), never from `~/.config`;
- `install.sh` links nothing;
- `--skip` leaves steps out; a failing step makes the script exit 1, names the step, and the
  following steps still run.

### smoke

Neovim starts with empty `XDG_*` directories, restores the plugins to the versions in
`lazy-lock.json`, then checks that:

- startup printed no error;
- every plugin is installed at its locked commit;
- the Dracula colorscheme is active and long lines wrap;
- every server in `after/lsp/` resolves to a command;
- `:checkhealth` reports no `ERROR` for `vim.lsp`, `vim.treesitter` and `lazy`.

Emacs installs the packages once (the only moment the network is allowed), then starts again
with network and prompts forbidden and checks that:

- all nine modules load and `*Warnings*` has no `Module … failed`;
- startup attempted no network call and asked no question (the freeze that came from a
  synchronous download cannot come back unnoticed);
- generated data stays under `XDG_DATA_HOME`, never in the repository;
- the files byte-compile without warnings about obsolete macros and variables, interactive-only
  functions, lexical-binding mistakes and similar. Warnings about free variables and functions
  of packages loaded later are ignored on purpose: with `:defer` they are expected.

Obsolete-API warnings are the early signal that a new Emacs release will break the config.

### keys

The real leader maps are dumped from the running editors, not read from the source: Neovim
after `VeryLazy` and an `LspAttach` in a git repository (so buffer-local LSP and gitsigns keys
exist), Emacs from the general.el override map under `SPC`. `test/keys/compare.py` then reports:

- a key documented in `docs/keymaps.md` that the editor lacks;
- a key documented as absent (`—`) that exists;
- a key in the editor that the document does not mention;
- two leader keys that run the same action in one editor.

`co ct cb ca` (merge conflicts) exist only inside a conflict, so they are skipped.

### behavior

One test per invariant that already broke once:

| Editor | Tests |
|---|---|
| Neovim | `<leader>uw` wraps every window and the ones opened later; the `gr*` defaults stay removed; Markdown formats with rumdl; a diff view opens and closes; `diffview://` buffers have no `buftype=""` and no language server; the file panel has `Tab`, `S-Tab`, `-`, `q`, `RET`; `local.lua` overrides settings (checked in a child Neovim) and a broken one keeps the defaults and is reported; `:checkhealth dotfiles` runs every section |
| Emacs | wrap toggle reaches every buffer and later ones; no LSP in `.~REV~` buffers; the file tree shows only the current project, uses evil-treemacs keys (`j k RET Tab h l`, leader still reachable), paints modified, added and untracked files with distinct Dracula colors and drops missing projects without asking; ediff starts on its first change; no dashboard when a file is given; evil follows screen lines; the review lists only changed files and closes cleanly; `local.el` overrides settings and a broken one is reported, not fatal; the health report covers the basics; a failed module is announced at startup; package backup, pruning and rollback |

## Cache

Plugins and packages are kept between runs in `.test-cache/` (ignored by git;
`DOTFILES_TEST_CACHE` moves it). Everything else (config copy, `HOME`, state, caches) is a
fresh temporary directory per run, and the repository is never written to: the tests work on a
copy of `config/nvim` and `config/emacs`. The Neovim copy gets a `local.lua` with
`spelllang = { "en_us" }`, so the Portuguese spell-file prompt never blocks a headless run.

## CI

Nothing runs on a schedule and nothing updates itself: updates happen when you run
`dotfiles update` ([maintenance.md](maintenance.md#updating)).

| File | Does |
|---|---|
| `.github/workflows/check.yml` | `test/run.sh all` on macOS (the only system this setup targets) for every push and pull request, and on demand (*Run workflow* in the Actions tab) |

## Adding a test

1. Pick the level: a new invariant goes in `behavior`; a new module or plugin needs nothing
   unless it can fail silently.
2. Neovim: add a `h.run("name", function() … end)` to `test/nvim/behavior.lua`; an `assert`
   with a message is the failure. `test/lib/harness.lua` provides `h.run`, `h.ready` and
   `h.finish`.
3. Emacs: add an `ert-deftest` to `test/emacs/behavior-tests.el`. `test/with-sample-repo`
   builds a throwaway git repository; `test/settle` waits for async work.
4. Check that the test fails without the fix (revert the fix in a copy, or break it on
   purpose) and passes with it.
5. Tests follow the rest of the repository: no comments, English, formatted by `stylua` /
   `shfmt`.

## What is not covered

- What the screen looks like: colors as drawn, fonts and icons, layout, mouse, the macOS GUI.
  The tests check the faces, keys and buffers behind it; a look in `emacs -nw`, Emacs.app and
  iTerm2 is still manual. A tmux-based screen test existed and was removed: it cost more to
  keep stable than it caught.
- Language servers and Mason downloads: servers are checked for a resolvable command, not run.
- The `gd` / `gr` / `gi` navigation inside a diff (it needs a live server); the guard that
  keeps servers out of diff buffers is covered instead.
- LaTeX compilation and Skim inverse search, Org agenda content, CIDER and clojure-lsp.
- Real downloads by `install.sh` (Homebrew, Mason, parsers): the tests use stubs.
