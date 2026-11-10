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
| Code | LaTeX, Markdown | each adds its servers (texlab; rumdl, marksman) and uses the formatting rules | full: `test_tex`, `test_markdown` |
| Core settings | Install | Install installs whatever the settings list | `tests/install.lua`, `fresh` |
| Install | Code, Git, LaTeX | Mason packages, codediff's library; MacTeX, Skim and `~/.latexmkrc` by `macos/nvim/link.sh` | `fresh`, quick: Skim |

## Keeping it true

A new cross-context fact is a row here, with its check, and nowhere else. A choice that stays in
one context, with its reason, is in that context's doc. A row with "none" is a
known gap, not a promise.
