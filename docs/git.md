# Git

Hunks in the buffer, lazygit, and codediff reviews: the working tree, the staged changes, the
branch, a pull request, a file's or a line's history. Its relationships are in [map](map.md).

## Language

- **hunk**: a changed block, marked by gitsigns in the status column.
- **review**: a codediff tab (`:CodeDiff` in any form: `<leader>gD`, `gC`, `gV`, `gd`, `gh`,
  `gL`, `gP`, or Enter in the log picker); `git.review()` knows it by the tab variable `review`.
- **editing tab**: the tab just before a review, where files opened from the review go.
- **base branch**: `origin/HEAD`, else `origin/main`, else `origin/master`.

## Files

| Path | Holds |
|---|---|
| `config/nvim/lua/plugins/editor.lua` (gitsigns) | signs, line blame, `]c` / `[c`, `<leader>g` hunk keys, `ih` |
| `config/nvim/lua/plugins/editor.lua` (codediff) | the review keys (`gD`, `gC`, `gV`, `gd`, `gh`, `gL`, `gP`, `gq`), the keys inside a review and a merge conflict, `git.setup()` |
| `config/nvim/lua/dotfiles/git.lua` | the base branch, the `review` tab variable, the editing tab, closing a review, `<leader>bd` beside a review, Enter in the log pickers |
| `config/nvim/lua/config/keymaps.lua` | `<leader>bd`, through `git.close_buffer` |
| `config/nvim/lua/plugins/snacks.lua` | lazygit, the git pickers (`gl`, `gt`, `gc`) and their Enter, `gO`, the `confirm` that sends a file from a review to the editing tab |
| `config/nvim/lua/plugins/ui.lua` | the which-key groups `<leader>g` and `<leader>gm` |

## How it works

Everything git is under `<leader>g`: gitsigns for the hunks and blame of the file you edit,
lazygit (`gg`) to commit, push and switch branches, pickers to jump (`gt` changed files, `gc`
changed hunks, `gl` the log) and codediff for every side by side view. codediff.nvim downloads
its prebuilt diff library in its lazy.nvim `build` step, so `install.sh` fetches it with the
plugins.

We use codediff only through what it documents: its options, its `:CodeDiff` command, its
`User` events and `:tabclose` (it cleans up on `TabClosed`). `git.setup()` sets the tab variable
`review` on `CodeDiffOpen` and clears it on `CodeDiffClose`; that is how the wrap toggle, the
pickers and `<leader>bd` know a review.

A review keeps its own tab and files go to the tab before it, the way codediff's `gf` already
works: the pickers' `confirm` points `picker.main` at a file window of that tab (made with
`-tabnew` when the review is the first tab or follows another review), so a pick never replaces
a side of the diff. `gt` / `gT` switch between the two. `<leader>gq` closes the review from
either tab; `<leader>bd` in a review closes it, and on a file a review shows it only warns,
because `Snacks.bufdelete` would take the buffer out of the review's window.

Snacks' log pickers check a commit out on Enter (`git checkout <commit> -- <file>` for a file's
log, which drops its uncommitted changes); their `confirm` is `git.review_commit` instead, which
reviews the commit against its parent. A file's and a line's history are codediff's own
`:CodeDiff history`, so they look and behave like any other review.

Every codediff key is under `<leader>g`: `ga` stages the file, `gi` / `gz` switch the layout and
fold, `gE` focuses the file list, and the merge conflict keys are `gm` plus codediff's own letters
(`t` theirs, `o` ours, `b` both, `x` none; upper case for the whole file). So `gc`, `t` and `-`
keep their Vim meaning on the real side, which is the file being edited, and `gd`, `K` and edits
work there. Hunks are gitsigns' alone (codediff's hunk keys are off); its `<leader>gs` unstages a
hunk already staged. The two sides never wrap. `<leader>op` inside a review toggles the file list
(codediff's `toggle_explorer` is set to it and to `<leader>ge`; its keys are buffer-local, so
everywhere else `<leader>op` is still the file tree).

## Contract

Offers: nothing other contexts rely on.

Consumes:

- [core](core.md): in a review `vim.go.wrap` is off (codediff sets it with `vim.wo`), and
  `<leader>uw` leaves it alone.
- [workspace](workspace.md): Snacks pickers and lazygit; the custom `confirm` must call
  `snacks.picker.actions.jump` directly.
- [install](install.md): codediff's prebuilt diff library, fetched in its `build` step.

## Pitfalls

- gitsigns attaches to a file a review opens after codediff maps its keys, and its buffer-local
  `]c` / `[c` replaced the review's; they now ask codediff first (`require("codediff").next_hunk`,
  public), and fall back to Vim's own `]c` in a `:diffthis` window.
- codediff cannot diff against the index (`:CodeDiff file` wants a revision `rev-parse` knows), so
  `<leader>gd` is against HEAD; the index diff is `<leader>gD`, which opens on the current file.
- `<leader>gO` on a review's old side opens the current branch: that side is a `codediff://`
  buffer, and placing it would mean reading codediff's internals again.
- An earlier version patched codediff's internal `open_in_prev_tab` and read its sessions; any
  codediff refactor could break it. Keep to the documented surface above.

## Checks

| What | Where |
|---|---|
| Base branch order, the `review` variable from codediff's events, the editing tab (before, made when missing, never a review), `Space g q` and `Space b d` around a review, Enter in the log pickers | `tests/helpers.lua` |
| Toggles beside a review | `tests/toggles.lua` |
| A `Space g V` review: file list, `]c`, unwrapped sides and `Space u w`, an edit on the real side, `Space g e` / `Space o p`, `Space g i`, `gc` left alone, `gf` and a pick open in the tab before, `gt` back, `Space g q` and `q` close; `Space g D`, `Space g d`, `Space g h`, `Space g L`; Enter in `Space g l` reviews without a checkout | full: `test_review` in `tests/git.sh` |
| `Space g D` opens on the current file, and closes a review; lazygit: `e`, stage, unstage, commit, back to the window it came from | full: `test_lazygit` |
| Debugging from the real side of a review | full: `test_review_debug` |

## Changing it

- **A git key**: gitsigns keys go in `on_attach` (buffer-local), picker keys in `snacks.lua`,
  `:CodeDiff` keys and the keys inside a review in codediff's spec; then the README's Git tables.
- **Review behaviour**: logic goes in `dotfiles/git.lua`, with a case in `tests/helpers.lua`; use
  codediff's options, command and events, not its modules.
