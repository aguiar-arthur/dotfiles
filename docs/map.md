# Context map

How the contexts relate. Read it when a change touches something a context **offers** (its
Contract section); a change that stays inside one context needs only that context's doc.

## Kinds

| Context | Kind | Why |
|---|---|---|
| Core | shared kernel | settings, keys and toggles every context uses; a change here is agreed with all |
| Workspace, Code, Git | core domain | where the editing day happens |
| LaTeX, Markdown | supporting | file-type specifics on top of Code and Workspace |
| Install | generic | brew, links and lockfile; follows what Core's settings say |
| Tests | cross-cutting | checks every context |

## Relationships

Upstream offers, downstream consumes; a change upstream may break downstream.

| Upstream | Downstream | Kind | Contract | Checked by |
|---|---|---|---|---|
| Core | all | published language | `settings.lua` keys (servers, tools, parsers, notes, spell), `<leader>` / `,` split | `tests/files.lua`, `helpers.lua` |
| Core | Markdown | customer / supplier | the global conceal toggle (`<leader>uc`) is re-applied to render-markdown | full: `test_markdown` |
| Core | Git | customer / supplier | `<leader>uw` leaves a review's wrap alone | `tests/toggles.lua`, full: `test_review` |
| Workspace | Git | customer / supplier | pickers' `confirm` opens a file from a review in a new tab | full: `test_review` |
| Workspace | Code | customer / supplier | blink.cmp's LSP capabilities reach servers started before the first insert | none (plugin wiring) |
| Workspace | Markdown | conformist | mini.pairs leaves the backtick alone; Markdown adds its own pair | `tests/keys.lua` |
| Workspace | LaTeX | customer / supplier | completion; LaTeX keeps its own snippets, not friendly-snippets | full: `test_snippets` |
| Code | LaTeX, Markdown | open host | each adds its servers (texlab, ltex_plus; rumdl, marksman) and uses the formatting rules | full: `test_tex`, `test_markdown` |
| Code | LaTeX | conformist | ltex is pinned to the position encoding texlab uses | none (`:checkhealth vim.lsp` warns) |
| Core settings | Install | conformist | Install installs whatever the settings list | `tests/helpers.lua`, `fresh` |
| Install | Code, Git, LaTeX | supplier | Mason packages, codediff's library; Skim and `~/.latexmkrc` by `link.sh` | `fresh`, quick: Skim |

## Shared words

A word that means something different per context is defined where it is owned.

| Word | Owner | Meaning there |
|---|---|---|
| toggle | Core | a global `<leader>u` key |
| review | Git | a codediff tab |
| jump | Git | a tab a picker opens from a review |
| picker | Workspace | any Snacks list |
| preview | Markdown | the pandoc HTML page |
| probe | Tests | a full-mode check that waits for a Lua value |

## Keeping it true

A new cross-context fact is a row here, with its check, and a line in both contexts' Contract
sections, not a sentence in a Pitfalls list. A row with "none" is a known gap, not a promise.
