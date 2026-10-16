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
| `config/nvim/lua/plugins/lsp.lua` | Mason, mason-lspconfig, system servers, diagnostics, the `LspAttach` keys (`gd`, `gr`, `<leader>l`, `,o`) |
| `config/nvim/after/lsp/<server>.lua` | per-server settings (basedpyright, jsonls, ltex_plus, lua_ls, marksman, ruff, texlab, yamlls) |
| `config/nvim/lua/plugins/formatting.lua` | conform, `style_markers`, the prettier trust check, `:FormatToggle`, `<leader>lf` |
| `config/nvim/lua/plugins/run.lua` | code_runner.nvim, `,r` and its `commands` |
| `config/nvim/lua/plugins/test.lua` | Neotest, neotest-python, `,t` |
| `config/nvim/lua/plugins/debug.lua` | nvim-dap, dap-ui, mason-nvim-dap, `,d`, the Python launch |
| `config/nvim/lua/dotfiles/python.lua` | the interpreter: `.venv` upward, else `$VIRTUAL_ENV`, else `python3` |
| `config/nvim/after/ftplugin/lua.lua` | `,s` sources the file |
| `config/nvim/lua/plugins/clojure.lua` | Conjure (Clojure only), nvim-paredit, `,cj` |
| `config/nvim/lua/dotfiles/clojure.lua` | jack-in: the nREPL command, waiting for `.nrepl-port`, the dead-REPL check |
| `config/nvim/after/ftplugin/clojure.lua` | which-key names of Conjure's groups |

## How it works

### Servers

- Mason installs the servers in `settings.mason_servers` and the tools in
  `settings.mason_tools` (shellcheck, debugpy). Only those servers are enabled
  (`automatic_enable = mason_servers`): a server left over in Mason stays off.
- Mason installs nothing when Neovim starts: after adding a server or tool, run
  `./install.sh` again (or `:MasonToolsInstall`).
- rumdl (`Brewfile.nvim`) and clojure-lsp (the full `Brewfile` only) are enabled when the binary
  exists. stylua, shfmt and prettier come from `Brewfile.nvim`; Mason does not install copies.
- blink.cmp adds its completion capabilities to every server by itself; it is a dependency of
  nvim-lspconfig so it loads, and registers them, before the first server starts.
- JavaScript and TypeScript have no server, formatter, runner, tests or debugger: they were
  removed as unused. Adding them back is a server in `settings.mason_servers` and a line in
  conform. The `javascript` parser stays for `<script>` blocks in HTML.
- `LspAttach` maps `gd` / `gr` and `<leader>l…` to Snacks pickers, clears `formatexpr` so `gq`
  keeps wrapping prose and comments, and maps `,o` (organize imports) only when the server
  offers it and the file type has no `,o` of its own (in Clojure it stays paredit's raise).
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

Without one each formatter falls back to its own defaults and a `:w` would restyle someone
else's code; a bare `.editorconfig` or `pyproject.toml` is too common to count. `<leader>lf`
formats anywhere. LaTeX formats only with `<leader>lf`. `:FormatToggle` (`!` for one buffer) or
`<leader>uf` turns saving off. prettier runs a project's JavaScript (`.prettierrc.js`,
plugins), so it runs, on save or with `<leader>lf`, only where a `.nvim.lua` approved with
`:trust` sits next to the prettier config and has not changed since; elsewhere `<leader>lf`
falls back to the language server. It is always the prettier on `PATH` (Homebrew's), never a
repository's `node_modules/.bin/prettier`.

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
summary, `,to` output, `,tO` output panel, `,td` debug the nearest test. Results show as signs
and diagnostics. neotest-python runs pytest from the project's virtualenv.

`,d` drives nvim-dap with dap-ui in Python buffers. dap-ui opens on launch and stays open after
the program ends so its output can be read (`,du` closes it). Breakpoints show as `●` (`◆` with
a condition) and the stopped line is tinted green. debugpy runs the file with the interpreter
from `python.lua`.

### Clojure

clojure-lsp gives navigation, rename, diagnostics and formatting. Conjure evaluates code in a
REPL, nvim-paredit edits s-expressions (`>)` / `<)` slurp and barf, `,o` raises a form).
`,cj` starts an nREPL with cider-nrepl in a terminal below (`clojure` for `deps.edn`, `lein`
for `project.clj`) and connects as soon as `.nrepl-port` appears; when a REPL already answers
it only connects; a `.nrepl-port` left by a dead REPL is removed and a new one starts,
replacing the dead REPL's terminal. Conjure keeps its own keys (`,e` evaluate, `,l` log, `,t`
tests, `,r` refresh, `,s` sessions). The nREPL and cider-nrepl versions are at the top of
`dotfiles/clojure.lua`.

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

## Checks

| What | Where |
|---|---|
| Format on save per style marker, prettier trust, `*.json.*` parser | `tests/files.lua` |
| `gq` keeps wrapping (`formatexpr` cleared) | `tests/keys.lua` |
| Python interpreter, Mason lists | `tests/helpers.lua` |
| Servers attach (Lua, Python, …), `,o`, `,s` | full: `test_lua`, `test_language_actions` |
| `,r` per language | full: `test_run` in `tests/code.sh` |
| `,t` keys, `,d` debugger (the six panels, `,du`) | full: `test_test_keys`, `test_debug` |
| `,cj` jack-in | full: `test_clojure` |

## Changing it

- **A language server**: its lspconfig name in `settings.mason_servers` (or
  `system_servers` with its binary), settings in `after/lsp/<name>.lua` if any, run
  `./install.sh nvim`, list the language in the README's "Code" section, and a
  `clients("<name>")` check in a full test.
- **A formatter**: a line in `formatters_by_ft`, a `style_markers` entry, its program in
  `Brewfile.nvim` (or Mason tools), a case in `tests/files.lua`, the table above.
- **A language for `,r`**: one line in `commands` in `run.lua` (or its name in the key's `ft`
  when the plugin knows it), a row in the README table, a `run_case` in `tests/code.sh`.
- **A test adapter or debugger**: its plugin in `test.lua` / `debug.lua` with the new `ft`;
  check the plugin rule first.
