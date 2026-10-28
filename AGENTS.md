# AGENTS.md

Personal dotfiles for macOS: Neovim, Starship and an iTerm2 profile, plus one standalone
Windows script to debug a PC's health. Keep them small: this is one person's setup, not a
product.

## Context map

The repository is split into contexts, each with one doc in `docs/` that holds its terms,
files, how it works and why, pitfalls that already cost time, checks, and recipes for common
changes. Read the doc of the context a task touches before the code; most tasks need one or
two. The README is the user's guide (keys); it is not needed to change code.

| Context | Doc | Owns | Depends on |
|---|---|---|---|
| Core | [docs/core.md](docs/core.md) | startup, `settings.lua` / `local.lua` / `.nvim.lua`, options, global keys, autocmds, `<leader>u` toggles, treesitter, look, spell | none |
| Workspace | [docs/workspace.md](docs/workspace.md) | Snacks pickers, file tree, terminals, sessions, flash, mini.*, grug-far, completion, `<leader>cs`, Claude Code | core |
| Code | [docs/code.md](docs/code.md) | language servers, formatting and style markers, `,r` / `,t` / `,d`, Python, Clojure | core, install |
| Git | [docs/git.md](docs/git.md) | gitsigns, codediff review, lazygit, git pickers, jumps from a review | core, workspace |
| LaTeX | [docs/latex.md](docs/latex.md) | vimtex, texlab, ltex-ls-plus, snippets, latexmkrc, Skim | core, code, install |
| Markdown | [docs/markdown.md](docs/markdown.md) | render-markdown, `,p` preview, rumdl rules, notes (obsidian.nvim), marksman | core, code |
| Install | [docs/install.md](docs/install.md) | `macos/` (one part each for nvim, terminal, apps), Mason / parser / spell installs, lockfile, zsh, Starship, iTerm2 | core (settings) |
| Tests | [docs/tests.md](docs/tests.md) | `tests/`, where a new check goes, checking by hand | all |
| Windows | [docs/windows.md](docs/windows.md) | `windows/collect-diagnostics.ps1`: a Windows 11 health report (events, dumps, drivers, disks, temperatures) and an optional DISM / SFC repair | none |

How the contexts relate (upstream / downstream, the contract, the shared words) is in
[docs/map.md](docs/map.md). A change inside one context needs only its doc; a change to
something a doc lists under **Contract** (Offers) also needs the map and the downstream docs.

## Working on a task

1. Find the context above and read its doc; its "Changing it" section has the steps for the
   usual changes (a server, a formatter, a key, a toggle, a snippet, a program, a link).
2. Change the code, its check in `tests/` and its docs (README keys, context doc) together.
3. Run `tests/nvim.sh` (quick); run `full` when the doc's checks name a `full:` test you
   touched. Say plainly what you could not check (GUI, real language servers, LaTeX).

## Layout

```text
config/nvim/        Neovim >= 0.12: lazy.nvim, one spec per concern in lua/plugins/, our own
                    helpers in lua/dotfiles/, per-server settings in after/lsp/
config/zsh/         dotfiles.zsh, sourced by the one ~/.zshrc block
config/starship/    starship.toml
config/rumdl/       rumdl.toml (Markdown lint rules; the root .rumdl.toml links to it)
config/iterm2/      dracula.json (Dynamic Profile)
config/latex/       latexmkrc (linked to ~/.latexmkrc)
docs/               one doc per context (the map above); img/ holds the README screenshot
macos/              the macOS install, see docs/install.md:
  install.sh        runs every part: terminal, apps, nvim
  lib.sh            what the parts share: Homebrew, links with backups, preferences, steps
  nvim/             Brewfile, install.sh (brew, link, plugins and Mason), link.sh (incl. Skim)
  terminal/         Brewfile, install.sh (brew, link), link.sh (Starship, iTerm2, ~/.zshrc)
  apps/             Brewfile, install.sh (brew): programs that are neither of the others
SECURITY.md         how to report a problem
CONTRIBUTING.md     how to change it, for people (a summary of this file)
.github/            security workflows and Dependabot
tests/              nvim.sh (quick, full, fresh) and its checks, see docs/tests.md
windows/            collect-diagnostics.ps1, a standalone Windows health report, see docs/windows.md
```

## Rules

- **Simple first.** No health checks, no doctor, no flags, no tests beyond `tests/nvim.sh`
  ([docs/tests.md](docs/tests.md)), and no CI beyond the security workflows and the quick tests
  (`.github/workflows/`: ShellCheck, gitleaks, zizmor, CodeQL, Scorecard, `tests.yml`).
  `macos/install.sh` runs every part (`macos/<part>/install.sh`: terminal, apps, nvim); a part
  runs on its own on a machine where the rest must stay untouched, so no script takes an
  argument. Each part installs its own `Brewfile`, runs its `link.sh`, and (nvim) sets up
  Neovim through the linked `~/.config/nvim`, as every day. Every script stays idempotent and
  only does what is missing. Every network step has a timeout or a failure path.
- **No comments in code**, in any file. Names and `desc` / `:wk` labels say what; a reason
  worth keeping goes in one sentence in its context's doc in `docs/`. Exceptions: `#!` lines
  and text the code writes or matches (the `# >>> dotfiles >>>` markers).
- **macOS only**, no branches for other systems. The one exception is `windows/`: standalone
  PowerShell for debugging a Windows PC, never installed, linked or tested by the rest.
- **English** in code, docs and commit messages; reply to the user in their language.
- **Every program goes in a Brewfile**: the one of the part that needs it (`macos/nvim/`,
  `macos/terminal/`), or `macos/apps/` when it is neither.
- **Keys.** `<leader>` is for what works everywhere, `,` (the local leader) for what depends on
  the file type. A `,` key goes in its plugin's `keys` with lazy.nvim's `ft`, in `LspAttach`
  when it depends on the server, or in `after/ftplugin/`; never in an autocmd of our own.
- **Settings** a user may change live in `config/nvim/lua/config/settings.lua` (including the
  servers, Mason tools and parsers to install); per-machine overrides go in the untracked
  `lua/config/local.lua`, per-project ones in a trusted `.nvim.lua` (`exrc`).
- **Dracula** everywhere (editor, prompt, terminal), including diff colors.
- **Latest versions.** `config/nvim/lazy-lock.json` is committed as the way back after a bad
  plugin update (`:Lazy restore`); never run `:Lazy update` or `:Lazy sync` just to check
  something, they rewrite it.
- **Only proven plugins.** A plugin (or a dependency it pulls in) is added only when it is
  well tested and reliable: not archived, a commit in the last two years, at least 500 GitHub
  stars or part of a project that has them (neovim, nvim-treesitter, nvim-neotest, mason-org,
  mini.nvim), not a fork of a living project, and no replacement for Neovim's own `:` line or
  messages. The reference plugin of a language (vimtex, Conjure, nvim-paredit) is the one
  exception. Check with
  `curl -s https://api.github.com/repos/<owner>/<repo>` (`stargazers_count`, `pushed_at`,
  `archived`, `fork`) before adding one, and drop a plugin that stops meeting the rule.
  Prefer a built-in feature or one of the plugins already here over a new one.
- **Our code is tested.** Code we write (`lua/dotfiles/`, `after/ftplugin/`, `snippets/`, and
  logic of our own in a plugin spec, keymap or autocmd) gets a check in `tests/` in the same
  change, and a bug fixed in it gets a check that fails without the fix. Plugin defaults and
  plain settings need none.
- **Own code stays small.** A helper of our own (`lua/dotfiles/`) grows by a line, not a
  feature; when it would need one, replace it with a proven plugin instead. Two did:
  Neotest (`,t`: runs tests, one adapter per language, pytest here) replaced our test runner,
  and code_runner.nvim (`,r`: runs the current file, any file type) replaced our own `,r`.
  They do different jobs and both stay.
- **Docs.** The README is the user's guide: a header (tagline, badges, "Why this one"), install,
  then one section per module with a one-line pitch and, folded in `<details>`, what it is for
  and a table of its keys. `docs/<context>.md` says how that context works, why, its
  pitfalls, its checks and how to change it. A key added, moved or removed changes its README
  table in the same change; a file, setting, pitfall or check added changes its context doc.
  Take the keys from the code, not from memory (the `desc` of each mapping, or
  `nvim_get_keymap` after loading the plugins). A new context (a language that grows its own
  files, say) gets its own doc and a row in the map, only when it would not fit an existing one.

## Git

- Commit only when asked; messages in English, imperative, about the why.
- Do not stage or commit changes the user made by hand.
- For read-only inspection use `git --no-optional-locks status` / `diff`.
