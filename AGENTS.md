# AGENTS.md

Personal dotfiles for macOS: Neovim, Starship and an iTerm2 profile. Keep them small: this
is one person's setup, not a product.

## Layout

```text
config/nvim/        Neovim >= 0.12: lazy.nvim, one spec per concern in lua/plugins/, native
                    LSP with per-server settings in after/lsp/, lazy-lock.json committed
config/zsh/         dotfiles.zsh, sourced by the one ~/.zshrc block
config/starship/    starship.toml
config/rumdl/       rumdl.toml (Markdown lint rules; the root .rumdl.toml links to it)
config/iterm2/      dracula.json (Dynamic Profile)
config/latex/       latexmkrc (linked to ~/.latexmkrc)
docs/               neovim.md (everything about the editor)
Brewfile            every program (includes Brewfile.nvim)
Brewfile.nvim       what Neovim needs, alone
install.sh          installs everything, running link.sh before Neovim
tests/nvim.sh       the Neovim checks, run by hand: quick (default), full, fresh
tests/lib.sh        their helpers (pass/fail, the isolated home, tmux, probe)
tests/<area>.sh     the full checks by area: look, markdown, code, tex
tests/modules.lua   loads every Lua module of the config, for tests/nvim.sh
link.sh             links, the ~/.zshrc block, iTerm2 and Skim preferences
CHANGELOG.md        notable changes, newest first
```

## Rules

- **Simple first.** No CI, no health checks, no doctor, no flags, and no tests beyond
  `tests/nvim.sh` (below). `./install.sh` installs everything and runs `link.sh` before the
  Neovim step (Neovim then uses the linked `~/.config/nvim`, as every day). The one exception
  to "no flags": both scripts take an optional `nvim` argument that limits them to Neovim
  (`Brewfile.nvim`, `~/.config/nvim` and the rumdl rules) for machines whose shell and
  terminal must stay untouched. Both stay idempotent in both modes and only do what is
  missing. Every network step in `install.sh` has a timeout or a failure path.
- **No comments in code**, in any file. Names and `desc` / `:wk` labels say what; a reason
  worth keeping goes in one sentence in `docs/`. Exceptions: `#!` lines and text the code
  writes or matches (the `# >>> dotfiles >>>` markers).
- **macOS only**, no branches for other systems.
- **English** in code, docs and commit messages; reply to the user in their language.
- **Every program goes in the Brewfile**; what Neovim needs goes in `Brewfile.nvim`, which
  the Brewfile includes.
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
- **Own code stays small.** A helper of our own (`lua/dotfiles/`) grows by a line, not a
  feature; when it would need one, replace it with a proven plugin instead, as Neotest
  replaced our test runner.
- **Docs.** The README is the user's guide: install, then one section per module with what
  it is for and a table of its keys. `docs/neovim.md` says how the editor works and why. A
  key added, moved or removed changes its README table in the same change; a change the user
  would notice also gets a line in `CHANGELOG.md`. Take the keys from the code, not from
  memory (the `desc` of each mapping, or `nvim_get_keymap` after loading the plugins).

## Pitfalls that already cost time

- Neovim's own ftplugins for Lua, Markdown, help and query call `vim.treesitter.start()`
  after the `FileType` autocmds; anything that turns treesitter off must stop it again later.
- Snacks pickers: a custom `confirm` must call `require("snacks.picker.actions").jump`
  directly; actions such as `tab` route back through `confirm` and recurse.
- `mason-lspconfig` gets `automatic_enable = mason_servers`, never `true`: `true` enables any
  server left installed in Mason (a stale stylua server once ran in Lua files).
- blink.cmp registers its LSP capabilities when it loads, so it stays a dependency of
  nvim-lspconfig; otherwise servers started before the first insert lack them.
- Conjure is limited to Clojure (`conjure#filetypes`); its other clients would map keys in
  Lua and Python. `K` and `gd` stay with the language server.
- `:checkhealth snacks` reports errors under `Snacks.image` (kitty graphics, `magick`, `mmdc`)
  although the module is off (`setup {disabled}`) and iTerm2 has no kitty protocol: not real.
- Snacks installs `vim.ui.input` / `vim.ui.select` and the dashboard on `UIEnter`, which a
  headless Neovim never fires: `:checkhealth snacks` errors there are not real.
- Formatters run on save only under a project style file (`style_markers` in
  `lua/plugins/formatting.lua`): their defaults (stylua's tabs,
  prettier's, ruff's and rumdl's rewrites) would restyle someone else's code on a `:w`. A
  formatter added to conform gets an entry there. The repository's `.rumdl.toml` is a link
  to `config/rumdl/rumdl.toml` so its own Markdown still formats on save, and its
  `.editorconfig` has a `[*.{sh,bash}]` section so its scripts do.
- `LspAttach` keys must not replace a `,` key the file type already has: clojure-lsp offers
  organize imports and once took `,o` from nvim-paredit's raise, so `,o` is mapped only where
  it is free.
- Neovim sets `formatexpr` to the language server's when it can format a range, and `gq`
  then stops wrapping prose and comments; the `LspAttach` callback clears it again.
- Two servers on one filetype must agree on the position encoding (`:checkhealth vim.lsp`
  warns); the extra one is pinned in its `after/lsp/` file, as ruff is to UTF-16.
- blink.cmp on the `:` line inserts the selected item already: mapping `<CR>` to `accept`
  there makes a completed command need a second `<CR>`.

## Checking a change by hand

`tests/nvim.sh` is the one test command, run by hand and never from `install.sh`. `quick` (the
default, seconds) runs the startup, module, lockfile, Skim, `zg`, stylua, shell syntax, shfmt,
rumdl and no-comment checks. `full` also installs Neovim into an isolated home under `~/.cache/dotfiles-nvim-test`
and drives a real Neovim in tmux (servers, toggles, the look, notes, a LaTeX build); `fresh`
does the same in a throwaway directory. It skips what is not installed, never touches the real
home and fails if `lazy-lock.json` changes. A check goes in the `tests/<area>.sh` of what it
tests, a helper in `tests/lib.sh`. Keep it to bugs that already happened and the `.sh` files
together under 520 lines: a new check replaces an old one or earns its lines. If it goes
unused, delete `tests/`.

By hand:

- Neovim: `nvim --headless "+qa"` prints nothing, and opening a file of the language you
  touched shows no error in `:messages`.
- Anything that needs a UI (LSP attach, Snacks, which-key, Conjure, DAP) is checked in a real
  terminal: write a Lua probe that waits with `vim.defer_fn`, writes what it sees to a file
  and quits, then run `sleep 30 | script -q /dev/null nvim -c "luafile probe.lua"` (the
  `sleep` keeps stdin open; without it Neovim gets EOF and quits). Work in a scratch
  project, point `XDG_STATE_HOME` at a scratch directory for anything that writes state
  (`:trust`), and stop only the processes you started, never with a broad `pkill`.
- Typed behaviour (autosnippets, completion, the `:` line) is checked the same way: the probe
  feeds keys with `nvim_feedkeys(keys, "t", false)` one step at a time, waits with
  `vim.defer_fn` and records the line or the mode; text set with the API triggers nothing.
  `E1568` (no answer to a DSR request) in a probe's `:messages` comes from `script`.
- Health: `nvim --headless <file> -c 'checkhealth <names>' -c 'w! out.txt' -c 'qa!'`, then
  look for `ERROR` and `WARNING`; load lazy plugins first (`require("lazy").load`) or their
  checks are skipped.
- Scripts: `bash -n install.sh link.sh` and `shfmt -d` on what you changed; Lua through
  `stylua --check .` run from `config/nvim` (from a subdirectory it misses `stylua.toml` and
  reports false diffs).
- Markdown: `rumdl check <files> --config config/rumdl/rumdl.toml`; it lets some long prose
  lines through, so also look for lines over 100 columns outside tables and code blocks.
- Say plainly what you could not check (GUI, real language servers, LaTeX).

## Git

- Commit only when asked; messages in English, imperative, about the why.
- Do not stage or commit changes the user made by hand.
- For read-only inspection use `git --no-optional-locks status` / `diff`.
