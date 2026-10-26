# Code

Language servers, formatting, and the `,` keys that run, test and debug a file; Python and
Clojure in detail. Its relationships are in [map](map.md).

## Language

- **Mason server**: a server in `settings.mason_servers`, installed by Mason and the only kind
  `mason-lspconfig` enables.
- **system server**: a server in `settings.system_servers` (rumdl, clojure-lsp), enabled only
  when its binary is on `PATH`.
- **style marker**: a project file that declares a formatter's style (`stylua.toml`,
  `[tool.ruff]`, …); without one, nothing formats on save.
- **local leader keys**: `,` keys that exist only in the file types that have them.

## Files

| Path | Holds |
|---|---|
| `config/nvim/lua/plugins/lsp.lua` | Mason, mason-lspconfig, system servers, diagnostics, the `LspAttach` keys (`gd`, `grr` / `gri` / `grt`, `<leader>l`, `,o`) |
| `config/nvim/lua/dotfiles/progress.lua` | servers' `$/progress` as Neovim's own progress messages (statusline, `:` line, the terminal's progress bar) |
| `config/nvim/after/lsp/<server>.lua` | per-server settings (basedpyright, clojure_lsp, jsonls, ltex_plus, lua_ls, marksman, ruff, texlab, yamlls) |
| `config/nvim/lua/plugins/formatting.lua` | conform, `style_markers`, the prettier trust check, `<leader>lf` |
| `config/nvim/lua/plugins/run.lua` | code_runner.nvim, `,r` and its `commands` |
| `config/nvim/lua/plugins/test.lua` | Neotest, neotest-python, `,t` |
| `config/nvim/lua/plugins/debug.lua` | nvim-dap, nvim-dap-view, the debugpy adapter, `,d`, the Python launch |
| `config/nvim/lua/dotfiles/python.lua` | the interpreter: `.venv` upward, else `$VIRTUAL_ENV`, else `python3` |
| `config/nvim/after/ftplugin/lua.lua` | `,s` sources the file |
| `config/nvim/lua/plugins/clojure.lua` | Conjure (Clojure only), nvim-paredit, `,cj` |
| `config/nvim/lua/dotfiles/clojure.lua` | jack-in: the nREPL command (`clojure`, `lein` or `bb`), waiting for `.nrepl-port`, the dead-REPL check |
| `config/nvim/after/ftplugin/clojure.lua` | which-key names of Conjure's groups |

## How it works

### Servers

- Mason installs the servers in `settings.mason_servers` and the tools in
  `settings.mason_tools` (shellcheck, debugpy). Only those servers are enabled
  (`automatic_enable = mason_servers`): a server left over in Mason stays off.
- Mason installs nothing when Neovim starts: after adding a server or tool, run
  `macos/nvim/install.sh` again (`dotfiles/install.lua` installs what is missing).
- rumdl and clojure-lsp (both `macos/nvim/Brewfile`) are enabled when the binary
  exists. stylua, shfmt and prettier come from `macos/nvim/Brewfile`; Mason does not install copies.
- blink.cmp adds its completion capabilities to every server by itself; it is a dependency of
  nvim-lspconfig so it loads, and registers them, before the first server starts.
- JavaScript and TypeScript have no server, formatter, runner, tests or debugger: they were
  removed as unused. Adding them back is a server in `settings.mason_servers` and a line in
  conform. The `javascript` parser stays for `<script>` blocks in HTML.
- `LspAttach` maps `gd`, `grr` / `gri` / `grt` (Neovim's names for references, implementation
  and type definition) and `<leader>lc` / `lC` (the call hierarchy, `lsp_incoming_calls` /
  `lsp_outgoing_calls`) to Snacks pickers; rename, code action and code lens stay Neovim's own
  `grn` / `gra` / `grx`, with no `<leader>l` copy. It also clears `formatexpr` so `gq`
  keeps wrapping prose and comments, and maps `,o` (organize imports) only when the server
  offers it and the file type has no `,o` of its own (in Clojure it stays paredit's raise).
- Code lenses show for every server that sends them (`vim.lsp.codelens.enable`), mostly
  clojure-lsp's reference counts; `grx` runs the one on the cursor line.
- Neovim 0.12 keeps servers' `$/progress` to itself (`LspProgress`); `dotfiles/progress.lua`
  turns each task into a native progress message (`nvim_echo` with `kind = "progress"`, one id
  per client and token), so the statusline shows `vim.ui.progress_status()`, the `:` line names
  the task, and iTerm2 draws its progress bar (OSC 9;4, Neovim's own `Progress` autocmd). A
  task without a percentage counts as 0% until it ends.
- `vim.lsp.linked_editing_range` is on for every server that offers it (html): renaming an
  opening tag renames its closing tag.
- Diagnostics show in full as virtual lines on the cursor line (`virtual_lines.current_line`)
  and as virtual text on the others (`virtual_text.current_line = false`), so `]d` / `]e` only
  jump: a float on top would repeat the same text.
- In Python, ruff is asked for UTF-16 positions like basedpyright, and its hover is off so `K`
  shows basedpyright's. basedpyright's organize imports is off; ruff's is the one.
- Files named `*.json.*` (`config.json.example`) are JSON, so jsonls lints them; prettier gets
  `--parser json` for them, since it picks its parser from the last extension.

### Formatting

conform formats on save (Lua with stylua, Python with ruff, shell with shfmt, web/JSON/YAML
with prettier, Markdown with rumdl; TOML and Clojure through taplo and clojure-lsp as the LSP
fallback), but only in projects that declare that tool's style:

| Language | Style marker |
|---|---|
| Lua | `stylua.toml` or `.stylua.toml` |
| Shell | an `.editorconfig` section for `.sh` or `.bash` files |
| Python | `ruff.toml`, `.ruff.toml` or `[tool.ruff]` in `pyproject.toml` |
| CSS, HTML, JSON, YAML | a prettier config with a trusted `.nvim.lua` beside it |
| Markdown | `.rumdl.toml`, `rumdl.toml` or `.markdownlint.*` |
| TOML | `taplo.toml` or `.taplo.toml` |
| Clojure | `cljfmt.edn` (or `.clj`) or `:cljfmt` in `.lsp/config.edn` |

A filetype with no row here (SCSS, Less, LaTeX) never formats on save, even when its server
could. Without one each formatter falls back to its own defaults and a `:w` would restyle someone
else's code; a bare `.editorconfig` or `pyproject.toml` is too common to count. `<leader>lf`
formats anywhere. LaTeX formats only with `<leader>lf`. `<leader>uf` turns saving off
everywhere, `<leader>uF` in this buffer only (both in `dotfiles/toggles.lua`). prettier runs a
project's JavaScript (`.prettierrc.js`, plugins), so it runs, on save or with `<leader>lf`,
only where a `.nvim.lua` approved with `:trust` sits next to the prettier config and has not
changed since; elsewhere `<leader>lf` falls back to the language server. It is always the
prettier on `PATH` (Homebrew's), never a repository's `node_modules/.bin/prettier`. Neovim has
no call that asks whether a file is trusted without prompting, so `trusted()` in
`formatting.lua` reads Neovim's own `trust` file (`stdpath("state")`, lines of `<sha256> <path>`,
the format `vim.secure` writes in 0.12); if a Neovim update changes that format, prettier stops
running and the `tests/files.lua` trust cases fail.

### Run, test, debug

| Keys | Python | Lua | Shell |
|---|---|---|---|
| `,r` run the file | yes | `nvim -l` | `bash` |
| `,t…` tests (Neotest) | pytest | | |
| `,d…` debugger | debugpy | | |
| `,o` organize imports | ruff | | |
| `,s` source the file | | yes | |

Each `,` key sits in its plugin's spec with lazy.nvim's `ft`, so it exists only in those
buffers and loads the plugin on first use. Where a tool is missing the key says so.

`,r` (code_runner.nvim) saves the file and runs it in a bottom terminal from the file's folder;
running the same file again replaces its terminal. It also runs JavaScript, Java, C, C++, Ruby
and Rust with the plugin's own commands.

`,t` runs Neotest: `,tt` nearest, `,tf` file, `,tp` project, `,tl` last, `,tS` stop, `,ts`
summary, `,to` output, `,tO` output panel, `,td` debug the nearest test; `]T` / `[T` jump to the
next / previous failed test (they replace Vim's tag jumps in Python only). Results show as signs
and diagnostics. neotest-python runs pytest from the project's virtualenv.

`,d` drives nvim-dap with nvim-dap-view in Python buffers: one panel below with views switched
from its winbar (scopes first) and the program's terminal beside it. It opens on launch
(`auto_toggle = "open"`) and stays open after the program ends so its output can be read (`,du`
hides both). It replaced nvim-dap-ui, which needed a six-window layout and nvim-nio. `,de` opens
dap-view's hover, `,dw` adds a watch (`:DapViewWatch`, which takes a range, unlike its hover),
`,dC` runs to the cursor and `,dp` sets a log point from a prompt; in visual mode the selection
comes from `getregion`, because `:DapViewHover` is not declared with a range and so never sees
one. Breakpoints show as `●` (`◆` with a condition) and the stopped line is tinted green.
debugpy runs the file with the interpreter from `python.lua`; its adapter is Mason's
`debugpy-adapter`, set in one line (mason-nvim-dap did only that and was dropped).

### Clojure

clojure-lsp gives navigation, rename, diagnostics and formatting. Conjure evaluates code in a
REPL, nvim-paredit edits s-expressions (`>)` / `<)` slurp and barf, `,o` raises a form).
`,cj` starts an nREPL with cider-nrepl in a terminal below (`clojure` for `deps.edn`, `lein` for
`project.clj`, else `bb nrepl-server 0` for `bb.edn`, on a free port that Babashka writes to
`.nrepl-port`; a `bb.edn` beside `deps.edn` is only for tasks, so `deps.edn` wins) and connects
as soon as `.nrepl-port` appears; when a REPL already answers it only connects; a `.nrepl-port`
left by a dead REPL is removed and a new one starts, replacing the dead REPL's terminal. Conjure
keeps its own keys (`,e` evaluate, `,l` log, `,t` tests, `,r` refresh, `,s` sessions). blink.cmp
adds the `omni` source in Clojure, which calls Conjure's omnifunc, so completion offers what the
running REPL knows beside clojure-lsp's static items. Neovim keeps Conjure's omnifunc: it sets
`v:lua.vim.lsp.omnifunc` only when `omnifunc` is empty, and blink's `omni` turns itself off on
the LSP one. The nREPL and cider-nrepl versions are at the top of `dotfiles/clojure.lua`.

## Contract

Offers:

- To [latex](latex.md) and [markdown](markdown.md): the server lists in `settings.lua` they add
  to (texlab, ltex_plus; rumdl, marksman), the `after/lsp/` files, `style_markers` and the
  formatting rules.

Consumes:

- [core](core.md): `settings` (which servers and tools).
- [workspace](workspace.md): blink.cmp registers its LSP capabilities when it loads, so it stays
  a dependency of nvim-lspconfig; otherwise servers started before the first insert lack them.
- [install](install.md): the Mason packages.

## Pitfalls

- taplo 0.10.0 (the newest in Mason) cannot read SchemaStore's current catalog (`failed to
  fetch catalog` in `lsp.log`), so TOML files get no schema completion or validation; formatting
  and syntax checks still work. Nothing to change here until taplo updates.
- `mason-lspconfig` gets `automatic_enable = mason_servers`, never `true`: `true` enables any
  server left installed in Mason (a stale stylua server once ran in Lua files).
- Formatters run on save only under a style marker. A formatter added to conform gets an
  entry in `style_markers`. The repository's `.rumdl.toml` links to `config/rumdl/rumdl.toml`
  so its own Markdown formats on save, and its `.editorconfig` has a `[*.{sh,bash}]` section so
  its scripts do.
- `LspAttach` keys must not replace a `,` key the file type already has: clojure-lsp offers
  organize imports and once took `,o` from nvim-paredit's raise.
- Neovim sets `formatexpr` to the server's when it can format a range, and `gq` then stops
  wrapping prose and comments; the `LspAttach` callback clears it again.
- Two servers on one filetype must agree on the position encoding (`:checkhealth vim.lsp`
  warns); the extra one is pinned in its `after/lsp/` file, as ruff is to UTF-16.
- Conjure is limited to Clojure (`conjure#filetypes`); its other clients would map keys in Lua
  and Python. `K` and `gd` stay with the language server.
- Conjure's log buffer (`conjure-log-<pid or state>.cljc`) is a Clojure file until Conjure marks it
  `nofile`, so clojure-lsp started a second server for it, rooted wherever Neovim was opened;
  `after/lsp/clojure_lsp.lua` skips it by name and keeps lspconfig's root markers otherwise.

## Checks

| What | Where |
|---|---|
| Format on save per style marker (none without one), prettier trust, `*.json.*` parser | `tests/files.lua` |
| `gq` keeps wrapping (`formatexpr` cleared) | `tests/keys.lua` |
| Python interpreter, Mason lists, clojure-lsp skips Conjure's log, the jack-in command per project file | `tests/helpers.lua` |
| Every `<Cmd>` key names a command that exists (`Space l R` once ran a removed `:LspRestart`) | `tests/keys.lua` |
| Servers attach (Lua, Python, …), `Space l R` restarts one, `,o`, `,s` | full: `test_lua`, `test_language_actions` |
| `,r` per language | full: `test_run` in `tests/code.sh` |
| `,dp` log point, `]T` / `[T` | `tests/keys.lua` |
| `,t` keys, `,d` debugger (the panel and terminal, `,de` on a word and a selection, `,dw`, `,dC`, `,du`) | full: `test_test_keys`, `test_debug` |
| `grr` / `gri` / `grt` open Snacks pickers on attach, Neovim's `grn` / `gra` / `grx` stay | `tests/keys.lua`, full: `test_lua` |
| `<leader>lc` / `lC` mapped on attach | full: `test_lua` |
| A server's progress becomes one native progress message (title, status, percent) | `tests/helpers.lua` |
| `,cj` jack-in (deps.edn, bb.edn), REPL completion through blink's `omni` | full: `test_clojure` |

## Changing it

- **A language server**: its lspconfig name in `settings.mason_servers` (or
  `system_servers` with its binary), settings in `after/lsp/<name>.lua` if any, run
  `macos/nvim/install.sh`, list the language in the README's "Code" section, and a
  `clients("<name>")` check in a full test.
- **A formatter**: a line in `formatters_by_ft`, a `style_markers` entry, its program in
  `macos/nvim/Brewfile` (or Mason tools), a case in `tests/files.lua`, the table above.
- **A language for `,r`**: one line in `commands` in `run.lua` (or its name in the key's `ft`
  when the plugin knows it), a row in the README table, a `run_case` in `tests/code.sh`.
- **A test adapter or debugger**: its plugin in `test.lua` / `debug.lua` with the new `ft`;
  check the plugin rule first.
