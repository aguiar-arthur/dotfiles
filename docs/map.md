# Context map

How the contexts relate. Read it when a change touches something another context relies on (a
row below); a change that stays inside one context needs only that context's doc.

## Relationships

Upstream offers, downstream consumes; a change upstream may break downstream.

| Upstream | Downstream | Contract | Checked by |
|---|---|---|---|
| Core | all | `settings.lua` keys (servers, tools, parsers, notes, spell), `<leader>` / `,` split | `tests/files.lua`, `install.lua` |
| Core | Markdown | the global conceal toggle (`<leader>uc`) is re-applied to render-markdown | full: `test_markdown` |
| Core | Git | the tab variable `review`: `<leader>uw` leaves its wrap alone, `<leader>uC` and `<leader>um` only warn while one is open, `<leader>bd` closes it, `windows.lua` shows no path bar there; `tabline.set_labeler` names it | `tests/toggles.lua`, `tests/git.lua`, full: `test_review` |
| Code, Markdown | Git | a review or native diff turns lenses, virtual lines and rendering off, and back when the last one closes | `tests/git.lua` |
| Workspace | Git | Claude's terminal and `ClaudeCodeAdd`: git sends it the changes | `tests/git.lua`, by hand with a real Claude |
| Workspace | Git | pickers' `confirm` opens a file from a review in the tab before it; the log pickers' Enter reviews a commit; `<leader>bd` beside a review keeps it whole | `tests/git.lua`, full: `test_review` |
| Workspace | Git | persistence's `PersistenceSavePre`, on which every review closes (`review.close_all`) | `tests/git.lua` |
| Workspace | Git | `dotfiles.picker.open`, which the git picker keys call | `tests/workspace.lua` |
| Workspace | Code | blink.cmp's LSP capabilities reach servers started before the first insert | none (plugin wiring) |
| Workspace | Markdown | mini.pairs leaves the backtick alone; Markdown adds its own pair | `tests/keys.lua` |
| Workspace | LaTeX | completion; LaTeX keeps its own snippets, not friendly-snippets | full: `test_snippets` |
| Code | LaTeX, Markdown | each adds its servers (texlab, ltex_plus; rumdl, marksman) and uses the formatting rules | full: `test_tex`, `test_markdown` |
| Code | LaTeX | ltex is pinned to the position encoding texlab uses | none (`:checkhealth vim.lsp` warns) |
| Core settings | Install | Install installs whatever the settings list | `tests/install.lua`, `fresh` |
| Install | Code, Git, LaTeX | Mason packages, codediff's library; BasicTeX and its packages (`macos/nvim/tex.sh`), Skim and `~/.latexmkrc` by `macos/nvim/link.sh` | `fresh`, quick: Skim, the tex step |

## Decisions

The choices that shape the whole setup, each with its reason and where it is told in full. A
reader (or an agent) who wants to change one starts here.

| Decision | Why | Where |
|---|---|---|
| Snacks for pickers, file tree, terminals, notifications and the dashboard | one plugin already here before a new one (`AGENTS.md`, plugin rule) | [workspace](workspace.md) |
| Native LSP (`vim.lsp.enable`, `after/lsp/`); Mason only installs, never at startup | mason-tool-installer only duplicated `dotfiles/install/` and was dropped | [code](code.md), [install](install.md) |
| Format on save only where the project declares a style | never restyle other people's code | [code](code.md) |
| Prettier only beside a trusted `.nvim.lua` | it runs the project's JavaScript | [code](code.md) |
| Neotest and code_runner.nvim, not runners of our own | proven plugins before our own code | `AGENTS.md` |
| nvim-dap-view, not nvim-dap-ui | nvim-dap-ui needed a six-window layout and nvim-nio | [code](code.md) |
| vim-tmux-navigator on Neovim's side | one key crosses windows and panes both ways; `tmux.conf` still loads and works without the Neovim config | [install](install.md), [workspace](workspace.md) |
| `lazy-lock.json` committed, nothing updates itself | a bad update has a way back (`:Lazy restore`) | [install](install.md#updating) |
| No comments that say what, one `why:` line at most, never a repeat of a doc | names and `desc` say what; reasons live in these docs | `AGENTS.md` |
| The install split into parts; LaTeX inside nvim, on BasicTeX | a machine whose shell must stay as it is gets only Neovim; LaTeX is only used from Neovim, and BasicTeX with a few packages is about 400 MB, not MacTeX's 10 GB | [install](install.md) |

## Keeping it true

A new cross-context fact is a row here, with its check, and nowhere else. A row with "none" is a
known gap, not a promise.
