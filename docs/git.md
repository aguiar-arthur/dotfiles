# Git

Hunks in the buffer, lazygit, and codediff reviews: the working tree, the staged changes, any
branch, a pull request, two revisions, a file's or a line's history. Its relationships are in
[map](map.md).

## Language

- **hunk**: a changed block, marked by gitsigns in the status column.
- **review**: a codediff tab (`:CodeDiff` in any form: `<leader>gD`, `gC`, `gV`, `gd`, `gh`,
  `gL`, `gP`, a `<leader>gv` key, or Enter in the log picker); `review.is()` knows it by the tab
  variable `review`, the tab line shows its tab variable `review_label`.
- **real side**: the side of a review that is the working file. Only a review against the working
  tree has one; a review of commits or of staged changes shows two read-only copies, with no
  filetype and no language server.
- **aligned view**: what stays off while any review is open, because it adds or hides rows on the
  real side only: code lens, the diagnostics' virtual lines, render-markdown, and the context
  float, which covers a row of one side. The winbar of `windows.lua` is off in a review's tab.
- **editing tab**: the tab just before a review, where files opened from the review go.
- **base branch**: `origin/HEAD`, else `origin/main`, else `origin/master`.

## Files

| Path | Holds |
|---|---|
| `config/nvim/lua/plugins/git.lua` (gitsigns) | signs (also of untracked files), blame, `]c` / `[c`, `<leader>g` hunk keys, the marks against the base (`gvs`), `ih` |
| `config/nvim/lua/plugins/git.lua` (codediff) | the review keys (`gD`, `gC`, `gV`, `gd`, `gh`, `gL`, `gP`, `gvv`, `gvc`, `gq`), the keys inside a review and a merge conflict, its options (hunks across files, moves, line counts, opening a file by moving in the list), `git.setup()` |
| `config/nvim/lua/dotfiles/git/init.lua` | `setup()`: what `CodeDiffOpen` and `CodeDiffClose` start |
| `config/nvim/lua/dotfiles/git/review.lua` | the `review` and `review_label` tab variables, closing a review (and every review before a session is saved), one at a time |
| `config/nvim/lua/dotfiles/git/aligned.lua` | the aligned view and bringing it back |
| `config/nvim/lua/dotfiles/git/jump.lua` | the editing tab and where a pick goes |
| `config/nvim/lua/dotfiles/git/buffers.lua` | `<leader>bd` beside a review, `<leader>bo` / `<leader>bD` while one is open |
| `config/nvim/lua/dotfiles/git/tabline.lua` | the tab line |
| `config/nvim/lua/dotfiles/git/repo.lua` | running git, the current file's folder, the base branch |
| `config/nvim/lua/dotfiles/git/compare.lua` | comparing with a branch or the base, the branch by commit or hunk, the marks against the base |
| `config/nvim/lua/dotfiles/git/log.lua` | the log pickers' actions, the commit of a line, a stash |
| `config/nvim/lua/dotfiles/git/pr.lua` | the pull request picker's actions, this branch's comments and checks |
| `config/nvim/lua/config/keymaps.lua` | `<leader>bd`, `<leader>bo`, `<leader>bD`, through `buffers.close_buffer` / `close_buffers` |
| `config/nvim/lua/plugins/snacks.lua` | lazygit, the git pickers (`gl`, `gt`, `gc`, `gvb`, `gvf`, `gvh`, `gvp`) and their Enter, `gO`, the `confirm` that sends a file from a review to the editing tab |
| `config/nvim/lua/plugins/ui.lua` | the which-key groups `<leader>g`, `<leader>gm` and `<leader>gv` |

## How it works

Everything git is under `<leader>g`: gitsigns for the hunks and blame of the file you edit
(the end-of-line blame starts off, `<leader>gB` shows it),
lazygit (`gg`) to commit, push and switch branches, pickers to jump (`gt` changed files, `gc`
changed hunks, `gl` the log) and codediff for every side by side view. `<leader>gv` holds what
compares with something else: another branch (`gvb`, `gvf`), typed revisions (`gvv`), the branch by
commit (`gvc`) or by hunk (`gvh`), gitsigns' marks against the branch's fork point (`gvs`, its
`change_base`), the commit of the cursor's line (`gvl`: `git blame` of the buffer's text, so an
unsaved line has no commit yet) and a stash (`gvz`; Enter reviews it, `C-e` applies it). `gvp` lists
pull requests through `gh`: Enter is a codediff review, while `C-e` (actions: comment, start a
review, check out) and `C-o` (hunks with their comments, `a` in the preview adds one) are Snacks'
own, the only way to write to a pull request from here. `gvo` opens those hunks for this branch's
pull request and `gvk` watches its checks in a terminal. `C-g` in `gl` searches what commits changed
(`git log -S`). codediff.nvim downloads its prebuilt diff library in
its lazy.nvim `build` step, so `macos/nvim/install.sh` fetches it with the plugins.

We use codediff only through what it documents: its options, its `:CodeDiff` command, its `User`
events and `:tabclose` (it cleans up on `TabClosed`). `setup()` sets the tab variable `review` on
`CodeDiffOpen` and clears it on `CodeDiffClose`; that is how the wrap toggle, the pickers and
`<leader>bd` know a review. The same events turn the aligned view on and, when the last review
closes, back as it was; `<leader>uC` and `<leader>um` only warn meanwhile, since turning those on
would misalign the sides. `CodeDiffOpen` also closes any other review, so the tab before a review
stays the editing tab. Its data has no revisions and codediff's winbar stays empty, so
`review.expect` gives the label before a key runs `:CodeDiff`; a typed `:CodeDiff` is labelled from
the `:` history.

A review keeps its own tab and files go to the tab before it, the way codediff's `gf` already works:
the pickers' `confirm` (`jump.pick_win`) points `picker.main` at that tab's focused file window, or
its first one (made with `-tabnew` when there is no such tab, it is a review, or it has no file
window), so a pick never replaces a side of the diff nor a terminal. A pick in the file the window
already shows stays there, so `gd` or a symbol inside the file does not leave the review. `gt` /
`gT` switch between the two. `<leader>gq` closes the review from either tab (opening a tab first
when the review is the last one, as codediff's own `q` does); `<leader>bd` in a review closes it,
and on a file a review shows it only warns, because `Snacks.bufdelete` would take the buffer out of
the review's window. `<leader>bo` / `<leader>bD` (`buffers.close_buffers`) only warn while any
review is open, for the same reason.

Snacks' log pickers check a commit out on Enter (`git checkout <commit> -- <file>` for a file's
log, which drops its uncommitted changes); their `confirm` is `log.commit` instead, which
reviews the commit against its parent (git's empty tree for the first commit) or, with two picked
by `Tab`, compares them, older first; `C-e` compares one with the working tree. `git_log_file` and
`git_log_line` have no key but keep that `confirm`, since `Snacks.picker` can still open them. A
file's and a line's history are codediff's own `:CodeDiff history`, so they look and behave like any
other review. Likewise `git_branches` checks out on Enter, so `gvb` and `gvf` give it a `confirm`.

Every codediff key is under `<leader>g`: `ga` stages the file, `gi` / `gz` switch the layout and
fold, `gM` lines the other side up with moved code, `gE` focuses the file list, and the merge
conflict keys are `gm` plus codediff's own letters
(`t` theirs, `o` ours, `b` both, `x` none; upper case for the whole file). So `gc`, `t` and `-`
keep their Vim meaning on the real side, which is the file being edited, and `gd`, `K` and edits
work there. On the real file hunks are gitsigns' (codediff's stage and discard keys are off); its
`<leader>gs` unstages a hunk already staged. A review of staged changes shows two codediff
buffers gitsigns does not attach to, so codediff's `<leader>gu` unstages a hunk there; no
gitsigns key uses it. `ih` is both plugins' on the real file (they select the same hunk) and
codediff's alone on the old side. The two sides never wrap, and neither does the diff preview of
the git pickers (`previewers.diff.wo` in `snacks.lua`): Snacks wraps it by default, which breaks
the box it draws around a long hunk header. So those pickers (`git_layout`) put the list on top and
the diff below it at full width, where a cut line is rare. `<leader>op` inside a review toggles
the file list (codediff's `toggle_explorer` is set to it and to `<leader>ge`; its keys are
buffer-local, so everywhere else `<leader>op` is still the file tree).

## Contract

Offers: nothing other contexts rely on.

Consumes:

- [core](core.md): in a review `vim.go.wrap` is off (codediff sets it with `vim.wo`), and
  `<leader>uw` leaves it alone; `<leader>uC` and `<leader>um` warn while one is open; the tab line
  is `tabline.render`; the winbar of `windows.lua` stays out of a review.
- [code](code.md), [markdown](markdown.md): the aligned view turns their lenses, virtual lines and
  rendering off during a review.
- [workspace](workspace.md): Snacks pickers and lazygit; the custom `confirm` must call
  `snacks.picker.actions.jump` directly.
- [install](install.md): codediff's prebuilt diff library, fetched in its `build` step.
- [workspace](workspace.md): persistence closes every review before it saves a session.

## Pitfalls

- Anything that adds or hides a row on the real side misaligns the two sides, since the old side
  has no filetype and no server: lenses shifted a Lua file by a row per lens, render-markdown a
  README by 17 rows, so the sides of a Markdown review did not even start together, and the path
  winbar pushed the real side of `<leader>gd` down one row. Check a new such feature with the
  aligned view.
- `lsp.lua` turns lenses on when nvim-lspconfig loads, which a review of commits opened from the
  dashboard delays until the first file, in the middle of the review; `aligned.on` loads it first.
- Snacks' `gh_actions` and `gh_diff` actions fail on an empty list, which is any repository with no
  open pull request, so `C-e` and `C-o` go through `pr.menu` and `pr.hunks`, which check the item.
- `Snacks.picker.gh_pr` came back empty in some test runs and full in others, with the same
  arguments and the API limits untouched; the cause is unknown, and opening it again fills it.
- A picker with one result and `auto_confirm` (most `gd`) never opens, so Snacks' `picker:close`
  has no picker window to leave and stays in the current window: setting `picker.main` was not
  enough and `gd` replaced the real side. `jump.pick_win` moves the focus itself when
  `not picker.shown`.
- `gf` from a read-only side opens the working file at the same line number, which may be other code
  by then; that is codediff's and only as good as the file matches.
- gitsigns attaches to a file a review opens after codediff maps its keys, and its buffer-local
  `]c` / `[c` replaced the review's; they now ask codediff first (`require("codediff").next_hunk`,
  public), and fall back to Vim's own `]c` in a `:diffthis` window.
- codediff cannot diff against the index (`:CodeDiff file` wants a revision `rev-parse` knows), so
  `<leader>gd` is against HEAD; the index diff is `<leader>gD`, which opens on the current file.
- `<leader>gO` on a review's old side opens the current branch: that side is a `codediff://`
  buffer, and placing it would mean reading codediff's internals again.
- `<leader>gV` reads the base branch in the current file's repository (else the working
  directory), as codediff does; asking the working directory gave another repository's base.
- `:tabclose` on the last tab fails (E784), so closing a review alone opens a tab first.

## Checks

| What | Where |
|---|---|
| Base branch order and its repository, the `review` variable from codediff's events, the editing tab (before, its focused window, made when missing, never a review nor a tab without a file window), where a pick goes (one result, a listed one, the same file), one review at a time, the aligned view, bringing it back and loading the servers first, no path bar, the tab line and its labels, a float in a tab, `Space g q`, `Space b d`, `Space b o` and `Space b D` around a review and on a review alone, Enter and `C-e` in the log pickers (parent, first commit, two picked), the actions of `Space g v`, `Space g v l` (committed, first commit, unsaved, no file, outside git), a stash, the pull request keys on an empty list, this branch's pull request | `tests/git.lua` |
| Toggles beside a review, `Space u C` and `Space u m` while one is open | `tests/toggles.lua` |
| A `Space g V` review: file list, `]c`, unwrapped sides and `Space u w`, an edit on the real side, `Space g e` / `Space o p`, `Space g i`, `gc` left alone, `gf` and a pick open in the tab before, a pick with one result too, one in the same file stays, the tab line, `gt` back, `Space g q` and `q` close; `Space g D`, `Space g d`, `Space g h`, `Space g L`; Enter in `Space g l` reviews without a checkout; `Space g v b` compares without one; `Space g v l`; `Space g v z`; a second review replaces the first; `Space g C` and `Space g u` unstaging there | full: `test_review` in `tests/git.sh` |
| `Space g D` opens on the current file, and closes a review; lazygit: `e`, stage, unstage, commit, back to the window it came from | full: `test_lazygit` |
| Debugging from the real side of a review | full: `test_review_debug` |

## Changing it

- **A git key**: gitsigns keys go in `on_attach` (buffer-local), picker keys in `snacks.lua`,
  `:CodeDiff` keys and the keys inside a review in codediff's spec; then the README's Git tables.
- **A new git subject**: a new file in `dotfiles/git/`; this module may grow (see `AGENTS.md`).
- **Review behaviour**: logic goes in the file of `dotfiles/git/` that holds its subject, with a
  case in `tests/git.lua`; use codediff's options, command and events, not its modules.
