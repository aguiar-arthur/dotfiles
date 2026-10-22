# Git

Hunks in the buffer, history pickers, lazygit, and the side by side review of the working
tree or the branch. Its relationships are in [map](map.md).

## Language

- **hunk**: a changed block, marked by gitsigns in the status column.
- **review**: a codediff tab, opened by `<leader>gD` (working tree), `<leader>gV` (the
  branch against origin's default branch) or `<leader>gd` (this file against HEAD).
- **jump tab**: the one tab, just before a review, where files opened from it go; it remembers
  its review in `vim.t.review_tab`.
- **base branch**: `origin/HEAD`, else `origin/main`, else `origin/master`.

## Files

| Path | Holds |
|---|---|
| `config/nvim/lua/plugins/editor.lua` (gitsigns) | signs, line blame, `]c` / `[c`, `<leader>g` hunk keys, `ih` |
| `config/nvim/lua/plugins/editor.lua` (codediff) | `<leader>gD`, `<leader>gV`, `<leader>gd`, `<leader>gq`, the review's own keys, `git.setup()` |
| `config/nvim/lua/dotfiles/git.lua` | the base branch, "is this tab a review", the jump tab, back to the review, `<leader>bd` beside a review, `<leader>gO` |
| `config/nvim/lua/config/keymaps.lua` | `<leader>bd`, through `git.close_buffer` |
| `config/nvim/lua/plugins/snacks.lua` | lazygit, git pickers (`gl`, `gt`, `gc`, `gh`, `gL`), `gO`, the `confirm` that opens jumps in a tab |

## How it works

`<leader>g`: lazygit, hunks, blame, changes (`gc` working tree hunks; `gD` / `gV` review),
history (`gh` file, `gL` line, `gl` repo). codediff.nvim downloads its prebuilt diff library in
its lazy.nvim `build` step, so `install.sh` fetches it with the plugins.

A file opened from a review never replaces a side of the diff nor the tab the review came from:
it goes to the review's jump tab, made with `-tabnew` just before the review the first time and
reused (moved back there if needed) after. The pickers' `confirm` points `picker.main` at that
tab's window; `gf` / `<leader>gf` is codediff's `open_in_prev_tab`, which `git.setup()` wraps so
the jump tab is the previous tab. References always show their list. `<leader>gq` closes the jump
tab and returns to its review even after visiting other tabs, or closes the review when pressed
in it; `<leader>bd` on a file the review shows does the same instead of deleting the buffer the
review uses (codediff tears a review down when one of its buffers goes). Closing a review
(`CodeDiffClose`) closes its jump tab, so none is left pointing nowhere; `tabclose = "uselast"`
makes a plain `:q` return to the last tab.
Every review key of codediff is under `<leader>g` (hunks as gitsigns has them, `<leader>ga`
stages the file, `<leader>gi` / `<leader>gz` layout and folding), so `gc`, `t` and `-` keep their
Vim meaning on the real side, which is the file being edited. The right side of the review
is the real file, so `gd`, `K` and edits work there. The two sides never wrap.
`<leader>op` inside a review toggles the file list (codediff's `toggle_explorer` is set to it and to
`<leader>ge`; its keys are buffer-local, so everywhere else `<leader>op` is still the file tree).

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
  `]c` / `[c` replaced the review's; they now ask codediff first, and fall back to Vim's own
  `]c` in a `:diffthis` window. `<leader>gs` / `<leader>gr` meet the same way on the real side,
  where both do the same thing; codediff's own run on the old side.
- `git.setup()` replaces `open_in_prev_tab` in `codediff.ui.view.actions.panes`, which codediff
  looks up on each press, because codediff's keymaps take only keys, not functions. If an update
  renames it, `git.setup()` warns and `gf` in a review opens the previous tab again; the quick
  tests check the function is still there. Drop the wrap once codediff takes a function there.
- codediff cannot diff against the index (`:CodeDiff file` wants a revision `rev-parse` knows), so
  `<leader>gd` is against HEAD; the index diff is `<leader>gD`, which opens on the current file.
- A review's old side is a `codediff://` buffer gitbrowse cannot place, so `git.browse()` resolves
  the side's revision to a commit and opens a permalink from the file's real buffer; the index
  (`:0`) and the real side use the usual `Snacks.gitbrowse()`.

## Checks

| What | Where |
|---|---|
| Base branch order, review detection, the jump tab (made before the review, reused, moved back), `Space g q` and `Space b d` from a jump or a review, closing jump tabs, `Space g O` on each side, the `gf` wrap warning and codediff still having `open_in_prev_tab` | `tests/helpers.lua` |
| Toggles beside a review | `tests/toggles.lua` |
| A `Space g V` review: file list, `]c`, unwrapped sides and `Space u w`, an edit on the real side, `Space g e` / `Space o p`, `gc` left alone, `Space g O` on the old side, a picked file and `gf` open in the jump tab, which is reused, `Space g q` returns, `q` closes the review and its jump tab; `Space g d` | full: `test_review` in `tests/git.sh` |
| `Space g D` opens on the current file, and closes a review; lazygit: `e`, stage, unstage, commit, back to the window it came from | full: `test_lazygit` |
| Debugging from the real side of a review | full: `test_review_debug` |

## Changing it

- **A git key**: gitsigns keys go in `on_attach` (buffer-local), picker keys in `snacks.lua`,
  review keys in codediff's `opts.keymaps`; then the README's Git tables.
- **Review behaviour**: logic goes in `dotfiles/git.lua`, with a case in `tests/helpers.lua`.
