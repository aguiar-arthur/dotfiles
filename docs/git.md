# Git

Hunks in the buffer, history pickers, lazygit, and the side by side review of the working
tree or the branch. Uses [workspace](workspace.md) pickers; [core](core.md) toggles leave the
review's wrap alone.

## Terms

- **hunk**: a changed block, marked by gitsigns in the status column.
- **review**: a codediff tab, opened by `<leader>gD` (working tree) or `<leader>gV` (the
  branch against origin's default branch).
- **jump**: a tab a picker opens from a review; it remembers its review in `vim.t.review_tab`.
- **base branch**: `origin/HEAD`, else `origin/main`, else `origin/master`.

## Files

| Path | Holds |
|---|---|
| `config/nvim/lua/plugins/editor.lua` (gitsigns) | signs, line blame, `]c` / `[c`, `<leader>g` hunk keys, `ih` |
| `config/nvim/lua/plugins/editor.lua` (codediff) | `<leader>gD`, `<leader>gV`, `<leader>gq`, the review's own keys |
| `config/nvim/lua/dotfiles/git.lua` | the base branch, "is this tab a review", jump marks, back to the review |
| `config/nvim/lua/plugins/snacks.lua` | lazygit, git pickers (`gl`, `gt`, `gc`, `gh`, `gL`), `gO`, the `confirm` that opens jumps in a tab |

## How it works

`<leader>g`: lazygit, hunks, blame, changes (`gc` working tree hunks; `gD` / `gV` review),
history (`gh` file, `gL` line, `gl` repo). codediff.nvim downloads its prebuilt diff library in
its lazy.nvim `build` step, so `install.sh` fetches it with the plugins.

Inside a review the pickers' `confirm` opens the file in a new tab, so a jump never replaces a
side of the diff; references always show their list. That tab remembers the review it came
from, so `<leader>gq` closes it and returns there even after visiting other tabs;
`tabclose = "uselast"` makes a plain `:q` return to the last tab. The right side of the review
is the real file, so `gd`, `K` and edits work there. The two sides never wrap.
`<leader>op` inside a review toggles the file list (codediff's `toggle_explorer` is set to it and to
`<leader>ge`; its keys are buffer-local, so everywhere else `<leader>op` is still the file tree).

## Pitfalls

- gitsigns attaches to a file a review opens after codediff maps its keys, and its buffer-local
  `]c` / `[c` replaced the review's; they now ask codediff first, and fall back to Vim's own
  `]c` in a `:diffthis` window.
- Snacks pickers: the custom `confirm` must call `snacks.picker.actions.jump` directly (see
  [workspace](workspace.md)).
- In a review `vim.go.wrap` is off (codediff sets it with `vim.wo`); see [core](core.md).

## Checks

| What | Where |
|---|---|
| Base branch order, review detection, `Space g q` back from a jump | `tests/helpers.lua` |
| Toggles beside a review | `tests/toggles.lua` |
| A `Space g V` review: file list, `]c`, unwrapped sides and `Space u w`, an edit on the real side, `Space g e` / `Space o p`, a picked file opens in a tab and `Space g q` returns, `q` closes | full: `test_review` in `tests/git.sh` |
| `Space g D` opens and closes a review; lazygit: `e`, stage, unstage, commit, back to the window it came from | full: `test_lazygit` |
| Debugging from the real side of a review | full: `test_review_debug` |

## Changing it

- **A git key**: gitsigns keys go in `on_attach` (buffer-local), picker keys in `snacks.lua`,
  review keys in codediff's `opts.keymaps`; then the README's Git tables.
- **Review behaviour**: logic goes in `dotfiles/git.lua`, with a case in `tests/helpers.lua`.
