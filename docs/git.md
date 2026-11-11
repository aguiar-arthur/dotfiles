# Git

Hunks in the buffer, lazygit, and codediff reviews: the working tree, the staged changes, any
branch, a pull request, two revisions, a file's or a line's history. Its relationships are in
[map](map.md).

## Language

- **hunk**: a changed block, marked by gitsigns in the status column.
- **review**: a codediff tab (`:CodeDiff` in any form: `<leader>gD`, `gC`, `gV`, `gd`, `gh`,
  `gL`, Enter in `gP`, a `<leader>gv` key, or Enter in the log picker); `review.is()` knows it
  by the tab variable `review`, the tab line shows its tab variable `review_label`.
- **real side**: the side of a review that is the working file. Only a review against the working
  tree has one, which includes `<base>...` (the merge base against the working tree, so with the
  branch checked out `<leader>gV` has `gd` and `K`); a review of commits, of staged changes or of a
  pull request from `gP` (fetched, never checked out) shows two read-only copies, with no filetype
  and no language server.
- **aligned view**: what stays off while any review or native diff is open, because it adds or hides
  rows on the real side only: code lens, the diagnostics' virtual lines, render-markdown, and the
  context float, which covers a row of one side. The winbar of `windows.lua` is off in a review's
  tab.
- **editing tab**: the tab just before a review, where files opened from the review go.
- **base branch**: `origin/HEAD`, else `origin/main`, else `origin/master`.

## How it works

Everything git is under `<leader>g` (which-key lists it): gitsigns for the hunks and blame of the
file you edit, lazygit to commit, push, switch branches and handle stashes, pickers to jump, and
codediff for every side by side view. The keys stop where lazygit or a review already does the
job. `<leader>gv` holds what compares with something else (another branch, typed revisions, the
branch commit by commit, gitsigns' marks against the branch's fork point). `gP` lists pull requests
through `gh`: Enter is a codediff review, while `C-e` and `C-o` are Snacks' own actions, the only
way to write to a pull request from here. codediff.nvim downloads its prebuilt diff library in
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
the review's window. `<leader>bo` / `<leader>bD` (`dotfiles/buffers.lua`) only warn while any
review is open, for the same reason.

Snacks' log pickers check a commit out on Enter (`git checkout <commit> -- <file>` for a file's
log, which drops its uncommitted changes); their `confirm` is `log.commit` instead, which
reviews the commit against its parent (git's empty tree for the first commit) or, with two picked
by `Tab`, compares them, older first; `C-e` compares one with the working tree. `git_log_file` and
`git_log_line` have no key but keep that `confirm`, since `Snacks.picker` can still open them. A
file's and a line's history are codediff's own `:CodeDiff history`, so they look and behave like any
other review. Likewise `git_branches` checks out on Enter, so `gvb` and `gvf` give it a `confirm`.

Every codediff key is under `<leader>g` (merge conflicts: `gm` plus codediff's own letters, one
conflict at a time; a whole file is lazygit's). So `gc`, `t` and `-` keep their Vim meaning on the
real side, which is the file being edited, and `gd`, `K` and edits work there. On the real file
hunks are gitsigns' (codediff's stage and discard keys are off); its `<leader>gs` unstages a hunk
already staged. A review of staged changes shows two codediff buffers gitsigns does not attach to,
so codediff's `<leader>gu` unstages a hunk there; no gitsigns key uses it. `ih` is both plugins' on
the real file (they select the same hunk) and codediff's alone on the old side. The two sides never
wrap, and neither does the diff preview of the git pickers (`previewers.diff.wo` in `snacks.lua`):
Snacks wraps it by default, which breaks the box it draws around a long hunk header. So those
pickers (`git_layout`) put the list on top and the diff below it at full width, where a cut line is
rare. `<leader>op` inside a review toggles the file list (codediff's `toggle_explorer` is set to it;
its keys are buffer-local, so everywhere else `<leader>op` is still the file tree).

The file list is a tree (`i` flips it to a list), so a pull request reads by folder. It hides
lockfiles, `*.min.*` and `*.snap` (`explorer.file_filter` in `plugins/git.lua`): they are noise
in a review by hand, but a changed dependency hides there too, so a review of a pull request that
touches a manifest also wants `<leader>gg` or `git diff` on the lockfile. The tab line adds how
many of the listed files you have opened (`dotfiles/git/explorer.lua`); it counts opened files,
not a position, because `]f` does not walk the list in the order codediff hands the formatter, and
a position would lie. The tally comes from the group formatter and `CodeDiffFileSelect`, so it
shows only in the file-list mode, and only for groups that were drawn. `+` / `-` gutter signs and
the line numbers' colour mark the changed rows beside the background, which the Dracula greens
and reds alone make hard to tell apart. `<leader>gw` ignores whitespace changes; codediff reads
the option when it renders a file, so it applies from the next file you open, not to the one on
screen.

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
- Claude's proposals are a native diff with one real side and one scratch side, misaligned by lenses
  like a review. `:diffthis` fires no `OptionSet`, so `watch_diff` (registered in codediff's `init`,
  before any review) listens to `DiffUpdated` and `WinClosed`.
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
- The pickers' `confirm` is replaced by this context's, which must call
  `snacks.picker.actions.jump` directly: actions such as `tab` route back through `confirm` and
  recurse.
- A new review draws its file list and fires `CodeDiffOpen` before the review it replaces fires
  `CodeDiffClose`, so state of one review (the tally of opened files) is kept per tab: cleared
  globally, closing the old review wiped the new one's.
- Every review closes before a session is saved (`PersistenceSavePre`): a restored review came
  back as plain buffers named `codediff://…` and `CodeDiff Explorer`.

## Checks

`tests/git.lua`, `toggles.lua`; full: `test_review`, `test_lazygit` and `test_review_debug` in
`tests/git.sh`. `tests/nvim.sh` prints what each check covers.

## Changing it

- **A git key**: gitsigns keys go in `on_attach` (buffer-local), picker keys in the Snacks spec of
  `plugins/git.lua`, `:CodeDiff` keys and the keys inside a review in codediff's spec.
- **A new git subject**: a new file in `dotfiles/git/`; this module may grow (see `AGENTS.md`).
- **Review behaviour**: logic goes in the file of `dotfiles/git/` that holds its subject, with a
  case in `tests/git.lua`; use codediff's options, command and events, not its modules.
