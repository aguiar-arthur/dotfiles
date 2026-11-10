# AGENTS.md

Personal dotfiles for macOS: Neovim, Starship, tmux and an iTerm2 profile, plus one standalone
Windows script to debug a PC's health. Keep them small: this is one person's setup, not a
product.

## Context map

Each context has one doc in `docs/` with how it works and why, pitfalls that already cost time,
its tests, and recipes for common changes. Read the doc of the context a task touches before the
code; most tasks need one or two. The README is the user's guide, not needed to change code.

| Context | Doc | Owns |
|---|---|---|
| Core | [docs/core.md](docs/core.md) | startup, `settings.lua` / `local.lua` / `.nvim.lua`, options, global keys, autocmds, `<leader>u` toggles, treesitter, look, spell |
| Workspace | [docs/workspace.md](docs/workspace.md) | Snacks pickers, file tree, terminals, sessions, flash, mini.*, grug-far, completion, `<leader>cs`, Claude Code |
| Code | [docs/code.md](docs/code.md) | language servers, formatting and style markers, `,r` / `,t` / `,d`, Python, Clojure |
| Git | [docs/git.md](docs/git.md) | gitsigns, codediff review, lazygit, git pickers, jumps from a review |
| LaTeX | [docs/latex.md](docs/latex.md) | vimtex, texlab, latexmkrc, Skim |
| Markdown | [docs/markdown.md](docs/markdown.md) | render-markdown, `,p` preview, rumdl rules, notes (obsidian.nvim), marksman |
| Install | [docs/install.md](docs/install.md) | `macos/`, Mason / parser / spell installs, lockfile, zsh, Starship, tmux, iTerm2 |
| Tests | [docs/tests.md](docs/tests.md) | `tests/`, where a new check goes, checking by hand |
| Windows | [docs/windows.md](docs/windows.md) | `windows/collect-diagnostics.ps1` |

How the contexts depend on each other is in [docs/map.md](docs/map.md): a change to something in
its table also needs the downstream docs.

## Working on a task

1. Read the context's doc; its "Changing it" section has the steps for the usual changes.
2. Change the code and its check in `tests/` together; the doc only when a reason, a pitfall or a
   step of "Changing it" changes.
3. Run `tests/nvim.sh` (quick); run `full` when the doc's checks name a `full:` test you
   touched. Say plainly what you could not check (GUI, real language servers, LaTeX).

## Layout

```text
config/nvim/   Neovim >= 0.12: one spec per concern in lua/plugins/, our helpers in
               lua/dotfiles/, per-server settings in after/lsp/
config/        zsh, starship, tmux, rumdl, iterm2, lazygit, git, latex: one folder per program
macos/         install.sh runs the parts (nvim, terminal, tmux, apps); each has a Brewfile,
               install.sh and link.sh; lib.sh is what they share
tests/         nvim.sh (quick, full, fresh) and its checks
windows/       standalone, never installed or tested by the rest
```

## Rules

- **Simple first.** No health checks, no doctor, no flags, no tests beyond `tests/nvim.sh`, no
  CI beyond the security workflows and the quick tests. A part of `macos/` runs on its own on a
  machine where the rest must stay untouched, so no script takes an argument. Scripts are
  idempotent, and every network step has a timeout or a failure path.
- **No comments that say what**, in any file. Names and `desc` / `:wk` labels say what; a reason
  worth keeping goes in its context's doc. A line that would look wrong without its reason may
  get one whole-line `-- why: …` (`# why: …`) comment above it, never trailing, never longer
  than a line. Exceptions: `#!` lines and text the code writes or matches.
- **macOS only**, no branches for other systems, except `windows/`.
- **English** in code, docs and commit messages; reply to the user in their language.
- **Dracula** everywhere (editor, prompt, terminal), including diff colors.
- **Every program goes in a Brewfile**, the one of the part that needs it.
- **Keys.** `<leader>` is for what works everywhere, `,` (the local leader) for what depends on
  the file type. A `,` key goes in its plugin's `keys` with `ft`, in `LspAttach` when it depends
  on the server, or in `after/ftplugin/`; never in an autocmd of our own. Every mapping has a
  `desc`.
- **Only proven plugins.** Prefer a built-in feature or a plugin already here. A new plugin
  (and what it pulls in) must be well tested: not archived, a commit in the last two years, at
  least 500 GitHub stars or part of a project that has them (neovim, nvim-treesitter,
  nvim-neotest, mason-org, mini.nvim), not a fork of a living project, and no replacement for
  Neovim's own `:` line or messages. The reference plugin of a language (vimtex, Conjure,
  nvim-paredit) is the one exception. Check with
  `curl -s https://api.github.com/repos/<owner>/<repo>` (`stargazers_count`, `pushed_at`,
  `archived`, `fork`), and drop a plugin that stops meeting the rule. Code of our own is only for
  what no plugin does, and it gets a check in `tests/` in the same change (a bug fixed gets a
  check that fails without the fix); plugin defaults and plain settings need none.
- **Modules.** `lua/plugins/` only declares (repository, trigger, options, keys that call
  functions) and has no subfolders. Logic of our own goes in `lua/dotfiles/`: one file, or a
  folder of one file per subject once it needs two, whose `init.lua` only wires. Loading a
  module runs nothing. Downstream may require upstream along [docs/map.md](docs/map.md), never
  the reverse. Paths Neovim looks for (`after/lsp/`, `after/ftplugin/`) stay where they are.
- **Settings** a user may change live in `lua/config/settings.lua`; never run `:Lazy update` or
  `:Lazy sync` just to check something, they rewrite the committed `lazy-lock.json`.
- **Docs.** The README is the user's guide: header, install, "First day" (its only key table),
  one short section per module, troubleshooting. A `docs/<context>.md` holds only what the code
  and tests cannot say: how it works, why, pitfalls, which tests check it, how to change it. No
  lists of files, keys or checks, and no history (git has it): state the rule and its reason. A
  fact two contexts share is a row in `docs/map.md`, nowhere else. A new context gets a doc and a
  row in the map only when it fits no existing one.

## Git

- Commit only when asked; messages in English, imperative, about the why.
- Do not stage or commit changes the user made by hand.
- For read-only inspection use `git --no-optional-locks status` / `diff`.
