# Context map

How the contexts relate. Read it when a change touches something a context **offers** (its
Contract section); a change that stays inside one context needs only that context's doc.

## Relationships

Upstream offers, downstream consumes; a change upstream may break downstream.

| Upstream | Downstream | Contract | Checked by |
|---|---|---|---|
| Core | all | `settings.lua` keys (servers, tools, parsers, notes, spell), `<leader>` / `,` split | `tests/files.lua`, `helpers.lua` |
| Core | Markdown | the global conceal toggle (`<leader>uc`) is re-applied to render-markdown | full: `test_markdown` |
| Core | Git | `<leader>uw` leaves a review's wrap alone | `tests/toggles.lua`, full: `test_review` |
| Workspace | Git | pickers' `confirm` opens a file from a review in the tab before it; the log pickers' Enter reviews a commit; `<leader>bd` beside a review keeps it whole | `tests/helpers.lua`, full: `test_review` |
| Workspace | Code | blink.cmp's LSP capabilities reach servers started before the first insert | none (plugin wiring) |
| Workspace | Markdown | mini.pairs leaves the backtick alone; Markdown adds its own pair | `tests/keys.lua` |
| Workspace | LaTeX | completion; LaTeX keeps its own snippets, not friendly-snippets | full: `test_snippets` |
| Code | LaTeX, Markdown | each adds its servers (texlab, ltex_plus; rumdl, marksman) and uses the formatting rules | full: `test_tex`, `test_markdown` |
| Code | LaTeX | ltex is pinned to the position encoding texlab uses | none (`:checkhealth vim.lsp` warns) |
| Core settings | Install | Install installs whatever the settings list | `tests/helpers.lua`, `fresh` |
| Install | Code, Git, LaTeX | Mason packages, codediff's library; Skim and `~/.latexmkrc` by `link.sh` | `fresh`, quick: Skim |

## Shared words

A word that means something different per context is defined where it is owned.

| Word | Owner | Meaning there |
|---|---|---|
| toggle | Core | a global `<leader>u` key |
| review | Git | a codediff tab |
| editing tab | Git | the tab just before a review, where files opened from it go |
| picker | Workspace | any Snacks list |
| preview | Markdown | the pandoc HTML page |
| probe | Tests | a full-mode check that waits for a Lua value |

## Keeping it true

A new cross-context fact is a row here, with its check, and a line in both contexts' Contract
sections, not a sentence in a Pitfalls list. A row with "none" is a known gap, not a promise.
