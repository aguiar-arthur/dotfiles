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

## How it works

### Servers

- Mason installs the servers in `settings.mason_servers` and the tools in
  `settings.mason_tools` (shellcheck, debugpy). Only those servers are enabled
  (`automatic_enable = mason_servers`): a server left over in Mason stays off.
- Mason installs nothing when Neovim starts: after adding a server or tool, run
  `macos/nvim/install.sh` again (`dotfiles/install/` installs what is missing).
- rumdl and clojure-lsp (both `macos/nvim/Brewfile`) are enabled when the binary
  exists. stylua, shfmt and prettier come from `macos/nvim/Brewfile`; Mason does not install copies.
- blink.cmp adds its completion capabilities to every server by itself; it is a dependency of
  nvim-lspconfig so it loads, and registers them, before the first server starts.
- JavaScript and TypeScript have no server, formatter, runner, tests or debugger. The
  `javascript` parser stays for `<script>` blocks in HTML, and the `ruby` one for the Ruby files
  `,r` runs.
- `LspAttach` maps `gd`, `grr` / `gri` / `grt` to Snacks pickers and `<leader>l` as the whole
  menu (which-key lists it; Neovim's own `grn` / `gra` / `grx` stay beside it). A picker key
  first asks whether a server on the buffer offers the method and warns when none does (lua_ls
  has no call hierarchy), since a Snacks picker would only say "No results". It also clears
  `formatexpr` so `gq` keeps wrapping prose and comments, and maps `,o` (organize imports)
  only when the server offers it and the file type has no `,o` of its own (in Clojure it stays
  paredit's raise); `tests/keys.lua` checks both ways, since the order of ftplugin and `LspAttach`
  is what decides it.
- One Python: `dotfiles.lang.python` is what `,r`, the debugger and basedpyright
  (`python.pythonPath`, set in `before_init` from the root, unless the project or machine set one)
  run, so a project with a `.venv` that is not activated behaves the same in each. `before_init`
  changes `config.settings` in place: the client keeps the table it was given before `before_init`
  runs, so a new table (as in Neovim's own example) never reaches the server. Its `root_dir` is the
  project's (lspconfig's markers) or the file's own folder, so `before_init` never guesses from
  whichever buffer is current. neotest-python keeps its own lookup, which also finds `venv/`,
  Poetry, Pipenv and uv environments; a `python` option would replace all of that. An activated
  `$VIRTUAL_ENV` comes first in both, so `,t` agrees with the others when one is active, even one
  left active from another project.
- clojure-lsp's call hierarchy replies break the spec: `fromRanges` is empty, the call site is
  in `selectionRange` and the definition in `range`. Snacks then placed the call site in the
  callee's file ("index out of range" when that line is shorter) and listed no incoming calls.
  `after/lsp/clojure_lsp.lua` wraps the client's `request` (`on_init`) and moves the call site
  into `fromRanges` and `range` into `selectionRange` when `fromRanges` is empty, so a fixed
  clojure-lsp passes through untouched. Remove the patch (and its case in `tests/code.lua`) once
  `vim.lsp.buf.incoming_calls()` lists call sites without it.
- `zipPlugin` stays enabled (lazy.nvim's `disabled_plugins`): clojure-lsp points into library
  sources as `zipfile://<jar>::<path>`, and without it a jump there fails ("Invalid cursor line").
- Code lenses show for every server that sends them (`vim.lsp.codelens.enable`), mostly
  clojure-lsp's reference counts; `grx` runs the one on the cursor line and `<leader>uC` hides
  them all. A review keeps them off (see [git](git.md)), and the diagnostics' virtual lines too.
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

conform formats on save (Lua with stylua, Python with ruff, shell and zsh with shfmt, web/JSON/YAML
with prettier, Markdown with rumdl; TOML and Clojure through taplo and clojure-lsp as the LSP
fallback), but only in projects that declare that tool's style (`style_markers` in
`dotfiles/format.lua`: `stylua.toml`, `[tool.ruff]`, an `.editorconfig` section for the shell,
`.rumdl.toml`, `cljfmt.edn`, …). A filetype with no marker (SCSS, Less, LaTeX) never formats on
save, even when its server could: each formatter falls back to its own defaults and a `:w` would
restyle someone else's code. A bare `.editorconfig` or `pyproject.toml` is too common to count.
`<leader>lf` formats anywhere. LaTeX formats only with `<leader>lf`. `<leader>uf` turns saving off
everywhere, `<leader>uF` in this buffer only (both in `dotfiles/toggles.lua`). prettier runs a
project's JavaScript (`.prettierrc.js`, plugins), so it runs, on save or with `<leader>lf`, only
where a `.nvim.lua` approved with `:trust` sits next to the prettier config and has not changed
since; elsewhere `<leader>lf` falls back to the language server. It is always the prettier on
`PATH` (Homebrew's), never a repository's `node_modules/.bin/prettier`. Neovim has no call that
asks whether a file is trusted without prompting, so `trusted()` in `dotfiles/format.lua` reads
Neovim's own `trust` file (`stdpath("state")`, lines of `<sha256> <path>`, the format `vim.secure`
writes in 0.12); if a Neovim update changes that format, prettier stops running and the
`tests/files.lua` trust cases fail.

### Run, test, debug

Each `,` key sits in its plugin's spec with lazy.nvim's `ft`, so it exists only in those
buffers and loads the plugin on first use. Where a tool is missing the key says so.

`,r` (code_runner.nvim) saves the file and runs it in a bottom terminal from the file's folder;
running the same file again replaces its terminal. It runs any file type the plugin knows.
`,t` (Neotest, pytest here) shows results as signs and diagnostics, and `]T` / `[T` jump between
failed tests (replacing Vim's tag jumps in Python only). They are separate plugins because they
do different jobs; neither is code of our own.

`,d` drives nvim-dap with nvim-dap-view in Python buffers: one panel below with views switched from
its winbar (scopes first) and the program's terminal beside it. It opens on launch (`auto_toggle =
"open"`) and stays open after the program ends so its output can be read (`,du` hides both). `,de`
opens dap-view's hover, `,dw` adds a watch (`:DapViewWatch`, which takes a range, unlike its
hover), `,dC` runs to the cursor and `,dp` sets a log point from a prompt; in visual mode the
selection comes from `getregion`, because `:DapViewHover` is not declared with a range and so never
sees one. Breakpoints show as `●` (`◆` with a condition) and the stopped line is tinted green.
debugpy runs the file with the interpreter from `python.lua`; its adapter is Mason's
`debugpy-adapter`, looked up when a session starts rather than when nvim-dap loads, so a debugpy
installed later is found and a missing one says how to install it.

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

clojure-lsp starts only in a project folder Neovim trusts. To find the classpath it runs the
project's own tool (`lein classpath`, which evaluates `project.clj`; `clojure -Spath`;
`npx shadow-cljs classpath`; `bb print-deps`) and any `:classpath-cmd` in the project's
`.lsp/config.edn`, so opening a file of a repository you did not write would run its code, the
reason prettier waits for a trusted `.nvim.lua`. `after/lsp/clojure_lsp.lua` asks
`vim.secure.read` about the project root: the first Clojure file of a project shows Neovim's own
question, `a` allows clojure-lsp there for good, `d` keeps it off, `i` asks again next time. A file
outside any project (no root) starts it without asking, since there is no tool to run.

## Pitfalls

- Neovim's trust question for a folder reads `exrc: Found untrusted code. DIRECTORY trust is
  decided only by name, not contents`: it is the same database as `.nvim.lua`, not an exrc file.
  `:lua vim.secure.trust({ action = "remove", path = "<root>" })` forgets an answer, as does
  deleting its line in `stdpath("state")/trust`.
- Zsh has `,r` and shfmt (which reads its dialect from the `.zsh` extension or the shebang), but no
  server and no tree-sitter: bash-language-server and shellcheck do not read zsh, and Neovim's own
  syntax file highlights it better than the bash parser would.
- `after/lsp/marksman.lua` compares real paths: `~/notes` may be a link, and Neovim's buffer names
  resolve some links but not all, so a plain comparison let marksman into notes.
- taplo 0.10.0 (the newest in Mason) cannot read SchemaStore's current catalog (`failed to
  fetch catalog` in `lsp.log`), so TOML files get no schema completion or validation; formatting
  and syntax checks still work. Nothing to change here until taplo updates.
- `mason-lspconfig` gets `automatic_enable = mason_servers`, never `true`: `true` enables any
  server left installed in Mason (a stale stylua server runs in Lua files).
- Formatters run on save only under a style marker. A formatter added to conform gets an
  entry in `style_markers`. The repository's `.rumdl.toml` links to `config/rumdl/rumdl.toml`
  so its own Markdown formats on save, and its `.editorconfig` has a `[*.{sh,bash}]` section so
  its scripts do.
- `LspAttach` keys must not replace a `,` key the file type already has: clojure-lsp offers
  organize imports and would take `,o` from nvim-paredit's raise.
- Neovim sets `formatexpr` to the server's when it can format a range, and `gq` then stops
  wrapping prose and comments; the `LspAttach` callback clears it again.
- Two servers on one filetype must agree on the position encoding (`:checkhealth vim.lsp`
  warns); the extra one is pinned in its `after/lsp/` file, as ruff is to UTF-16.
- Conjure is limited to Clojure (`conjure#filetypes`); its other clients would map keys in Lua
  and Python. `K` and `gd` stay with the language server.
- Conjure's log buffer (`conjure-log-<pid or state>.cljc`) is a Clojure file until Conjure marks it
  `nofile`, so clojure-lsp started a second server for it, rooted wherever Neovim was opened;
  `after/lsp/clojure_lsp.lua` skips it by name and keeps lspconfig's root markers otherwise.
- Neovim starts tracking server progress on the first `vim.ui.progress_status()` call, so
  `progress.setup()` calls it once; without it the statusline missed what began before its first
  redraw.

## Checks

`tests/code.lua`, `files.lua`, `keys.lua`, `install.lua`; full: `tests/code.sh` (servers per
language, `,r`, `,t`, `,d`, `,cj`). `tests/nvim.sh` prints what each check covers.

## Changing it

- **A language server**: its lspconfig name in `settings.mason_servers` (or
  `system_servers` with its binary), settings in `after/lsp/<name>.lua` if any, run
  `macos/nvim/install.sh`, list the language in the README's "What you get" and "What is in
  it" lists, and an entry in `test_servers_per_language`.
- **A formatter**: a line in `formatters_by_ft`, a `style_markers` entry (`dotfiles/format.lua`),
  its program in `macos/nvim/Brewfile` (or Mason tools), a case in `tests/files.lua`.
- **A language for `,r`**: one line in `commands` in `run.lua` (or its name in the key's `ft`
  when the plugin knows it), a `run_case` in `tests/code.sh`.
- **Logic of one language**: a file in `dotfiles/lang/`; there is no registry of languages, since
  each tool already keeps its own list (`formatters_by_ft`, `commands`, `settings`).
- **A test adapter or debugger**: its plugin in `test.lua` / `debug.lua` with the new `ft`;
  check the plugin rule first.
