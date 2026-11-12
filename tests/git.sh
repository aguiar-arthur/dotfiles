test_review() {
  review_repo review
  local repo="$PROJ/review"
  printf 'side\n' >"$repo/side.txt"
  start_nvim "$repo" other.txt
  keys Space g V
  wait_for 'vim.fn.tabpagenr("$")' 2 20
  probe "Space g V: the cursor starts in the file list" 'vim.bo.filetype' codediff-explorer 10
  probe "Space g V: the file list is 40 columns wide" 'vim.api.nvim_win_get_width(0)' 40 5
  keys C-l C-l gg
  wait_for 'vim.fn.expand("%:t")' r.lua 10
  keys ]c
  probe "Space g V: ]c goes to the branch's change" 'vim.fn.line(".")' 3 10
  probe "Space g V: the sides do not wrap" 'vim.wo.wrap and 1 or 0' 0 5
  probe "Space g V: the wrap toggle stays on" 'require("dotfiles.toggles").values.wrap and 1 or 0' 1 5
  probe "Space g V: the new side's bar names the working tree and the hunk" 'vim.api.nvim_eval_statusline(vim.wo.winbar, { winid = 0, use_winbar = true, maxwidth = 200 }).str' " new working tree  hunk 1/1" 5
  keys Space u w
  probe "Space u w in a review keeps the sides unwrapped" 'vim.wo.wrap and 1 or 0' 0 5
  probe "and says why" "$(notified "Wrap stays off in a review")" 1 5
  keys g g O
  keys "x = 0" Escape
  keys Space s
  probe "an edit on the real side reaches the disk" 'vim.fn.readfile(vim.fn.expand("%:p"))[1]' "x = 0" 10
  keys Space o p
  probe "Space o p hides the file list in a review" 'vim.fn.winnr("$")' 2 5
  keys Space o p
  probe "Space o p shows the file list again" 'vim.fn.winnr("$")' 3 5
  probe "the review's tab is marked a review" 'require("dotfiles.git.review").is() and 1 or 0' 1 5
  keys Space g i
  sleep 1
  keys Space g i
  probe "Space g i twice keeps it a review" 'require("dotfiles.git.review").is() and 1 or 0' 1 10
  probe "gc stays the comment operator in a review" 'vim.fn.maparg("gc", "n", false, true).buffer or 0' 0 5
  keys C-l C-l
  keys g f
  probe "gf opens the file in the tab before the review" 'vim.fn.tabpagenr("$") * 10 + vim.fn.tabpagenr()' 21 10
  probe "and shows it there" 'vim.fn.expand("%:t")' r.lua 5
  send ':enew<CR>'
  keys g t
  keys Space f f
  wait_for 'vim.bo.filetype' snacks_picker_input 10
  keys side.txt
  wait_for 'P.picker_count() == 1 and 1 or 0' 1 10
  keys Enter
  probe "a picked file opens in the tab before the review too" 'vim.fn.tabpagenr("$") * 10 + vim.fn.tabpagenr()' 21 10
  probe "and shows it there" 'vim.fn.expand("%:t")' side.txt 5
  probe "that tab wraps" 'vim.wo.wrap and 1 or 0' 1 5
  probe "the review keeps its diff" '#vim.fn.tabpagebuflist(2)' 3 5
  keys g t
  send ':lua Snacks.picker.pick({ items = { { file = vim.fn.getcwd() .. "/other.txt", text = "other" } }, format = "text", auto_confirm = true })<CR>'
  probe "a pick with one result opens in the tab before the review" 'vim.fn.expand("%:t") .. vim.fn.tabpagenr()' other.txt1 10
  probe "and leaves the real side alone" 'vim.fn.fnamemodify(vim.fn.bufname(vim.fn.tabpagebuflist(2)[3]), ":t")' r.lua 5
  keys g t
  send ':lua Snacks.picker.pick({ items = { { file = vim.fn.getcwd() .. "/r.lua", text = "r", pos = { 3, 0 } } }, format = "text", auto_confirm = true })<CR>'
  probe "a pick in the file the review shows stays in the review" 'vim.fn.line(".") .. vim.fn.expand("%:t") .. vim.fn.tabpagenr()' 3r.lua2 10
  probe "the tab line names what the review compares" 'vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str:find("review: origin/", 1, true) and 1 or 0' 1 5
  keys C-h C-h
  probe "gt goes back to the review's file list" 'vim.bo.filetype' codediff-explorer 5
  keys g T
  keys Space g q
  probe "Space g q from the tab before closes the review" 'vim.fn.tabpagenr("$")' 1 10
  keys Space g D
  probe "Space g D reviews the edit" 'vim.fn.tabpagenr("$")' 2 20
  keys C-h C-h
  probe "Space g D: the file list has the cursor" 'vim.bo.filetype' codediff-explorer 10
  keys q
  probe "q in the file list closes the review" 'vim.fn.tabpagenr("$")' 1 10
  send ':edit r.lua<CR>'
  keys Space g d
  probe "Space g d reviews the file against HEAD" 'vim.fn.tabpagenr("$")' 2 20
  keys Space g q
  probe "Space g q in a review closes it" 'vim.fn.tabpagenr("$")' 1 10
  keys Space g h
  probe "Space g h opens the file's history as a review" 'require("dotfiles.git.review").is(vim.api.nvim_list_tabpages()[2]) and 1 or 0' 1 20
  keys Space g q
  probe "Space g q closes the history" 'vim.fn.tabpagenr("$")' 1 10
  keys 3G Space g L
  probe "Space g L opens the line's history as a review" 'require("dotfiles.git.review").is(vim.api.nvim_list_tabpages()[2]) and 1 or 0' 1 20
  keys Space g q
  wait_for 'vim.fn.tabpagenr("$")' 1 10
  keys Space g l
  wait_for 'P.picker_count() > 0 and 1 or 0' 1 15
  keys Enter
  probe "Enter in Space g l reviews the commit" 'vim.fn.tabpagenr("$")' 2 20
  probe "and checks nothing out" 'vim.fn.system("git -C " .. vim.fn.getcwd() .. " symbolic-ref -q HEAD") ~= "" and 1 or 0' 1 5
  probe "and leaves the edit alone" 'vim.fn.readfile(vim.fn.getcwd() .. "/r.lua")[1]' "x = 0" 5
  keys Space g q
  wait_for 'vim.fn.tabpagenr("$")' 1 10
  keys Space g v b
  wait_for 'P.picker_count() > 0 and 1 or 0' 1 15
  keys Enter
  probe "Enter in Space g v b compares with the branch" 'require("dotfiles.git.review").is(vim.api.nvim_list_tabpages()[2]) and 1 or 0' 1 20
  probe "and checks nothing out" 'vim.fn.system("git -C " .. vim.fn.getcwd() .. " symbolic-ref -q HEAD") ~= "" and 1 or 0' 1 5
  keys Space g V
  probe "a second review replaces the first" 'vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str:find("review: origin/", 1, true) and vim.fn.tabpagenr("$") or 0' 2 20
  keys Space g q
  wait_for 'vim.fn.tabpagenr("$")' 1 10
  send ':edit r.lua<CR>'
  keys 3G Space g p
  wait_for 'P.floats_shown() > 0 and 1 or 0' 1 10
  keys k
  wait_for 'P.floats_shown()' 0 10
  keys Space g V
  wait_for 'vim.fn.tabpagenr("$")' 2 20
  keys C-l C-l Space g z
  sleep 1
  probe "Space g z after a hunk preview raises nothing" 'select(2, vim.fn.execute("messages"):gsub("Invalid buffer id", "")) ' 0 5
  keys Space g q
  wait_for 'vim.fn.tabpagenr("$")' 1 10
  send ':edit r.lua<CR>'
  send ':silent !git add r.lua<CR>'
  keys Space g C
  probe "Space g C reviews what is staged" 'vim.fn.tabpagenr("$")' 2 20
  keys C-l C-l gg Space g u
  probe "Space g u there unstages the change" 'vim.trim(vim.fn.system("git -C " .. vim.fn.getcwd() .. " diff --cached --name-only"))' "" 15
  stop_nvim
}

test_pr_review() {
  review_repo pr
  local repo="$PROJ/pr" g=(git -c user.name=t -c user.email=t@t)
  local tab_has='vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str:find("%s", 1, true) and 1 or 0'
  local head='vim.trim(vim.fn.system("git -C " .. vim.fn.getcwd() .. " rev-parse %s"))'
  printf 's = 1\n' >"$repo/s.lua"
  "${g[@]}" -C "$repo" add s.lua && "${g[@]}" -C "$repo" commit -qm second
  git -C "$repo" push -q origin HEAD:refs/pull/7/head
  start_nvim "$repo" other.txt
  send ':lua require("dotfiles.git.reviewed").target = function(_, _, dir, done) done({ baseRefName = vim.trim(vim.fn.system({ "git", "-C", dir, "branch", "--show-current" })) }) end<CR>'
  send ':lua require("dotfiles.git.reviewed").review(7, vim.fn.getcwd())<CR>'
  probe "a pull request opens as a review" 'vim.fn.tabpagenr("$")' 2 20
  probe "its tab line names it, and the file it opened on is not read yet" "$(printf "$tab_has" "▱▱▱▱▱ 0/2 seen")" 1 10
  keys ]u
  probe "]u counts the file it leaves and opens the next" "$(printf "$tab_has" "1/2 seen")" 1 10
  keys ]u
  probe "]u on the last file completes the review" "$(notified "Review complete: 2/2 seen")" 1 5
  probe "and records the head it showed" "$(printf "$head" refs/pr-review/7/reviewed)" "$(git -C "$repo" rev-parse HEAD)" 5
  keys ]u
  probe "]u with every file seen says so" "$(notified "Every file of this review was seen")" 1 5
  printf 't = 1\n' >"$repo/t.lua"
  "${g[@]}" -C "$repo" add t.lua && "${g[@]}" -C "$repo" commit -qm third
  git -C "$repo" push -q origin HEAD:refs/pull/7/head
  send ':lua require("dotfiles.git.reviewed").since(7, vim.fn.getcwd())<CR>'
  probe "since the last review shows only the new push" "$(printf "$tab_has" "since")" 1 20
  probe "one file, open but not read yet" "$(printf "$tab_has" "0/1 seen")" 1 10
  probe "and the review replaces the first" 'vim.fn.tabpagenr("$")' 2 5
  keys ]u
  probe "reading it records the new head" "$(printf "$head" refs/pr-review/7/reviewed)" "$(git -C "$repo" rev-parse HEAD)" 10
  stop_nvim
}

test_lazygit() {
  local repo="$PROJ/lazygit" staged='vim.trim(vim.fn.system("git -C " .. vim.fn.getcwd() .. " diff --cached --name-only"))'
  if ! have lazygit; then
    skip "lazygit stage and commit" "lazygit not installed"
    return
  fi
  review_repo lazygit
  printf 'a = 1\n\nb = 4\n' >"$repo/r.lua"
  printf 'disableStartupPopups: true\ngui:\n  language: en\n' >"$T/lazygit.yml"
  printf 'z = 0\n' >"$repo/a.lua"
  start_nvim "$repo" r.lua
  keys Space g D
  probe "Space g D from a file opens the review on that file" 'vim.fn.fnamemodify(vim.fn.bufname(vim.fn.tabpagebuflist()[3]), ":t")' r.lua 20
  stop_nvim
  rm -f "$repo/a.lua"
  LG_CONFIG_FILE="$T/lazygit.yml" start_nvim "$repo" other.txt
  keys Space g D
  probe "Space g D reviews the working tree" 'vim.fn.tabpagenr("$")' 2 20
  keys Space g D
  probe "Space g D inside a review closes it" 'vim.fn.tabpagenr("$")' 1 10
  keys Space g g
  probe "lazygit opens in terminal mode" 'vim.fn.mode()' t 20
  expect_screen "lazygit shows its file list" Files
  keys j e
  probe "lazygit: e opens the file in a new tab" 'vim.fn.expand("%:t") .. vim.fn.tabpagenr("$")' r.lua2 15
  probe "lazygit: and that tab is in normal mode" 'vim.fn.mode()' n 5
  stop_nvim
  LG_CONFIG_FILE="$T/lazygit.yml" start_nvim "$repo" r.lua
  keys C-w v
  send ':lua vim.g.home = vim.api.nvim_get_current_win()<CR>'
  keys Space g g
  probe "lazygit opens in terminal mode" 'vim.fn.mode()' t 20
  expect_screen "lazygit shows its file list" Files
  keys Space
  probe "lazygit: space stages the file" "$staged" r.lua 10
  keys Space
  probe "lazygit: space unstages it" "$staged" "" 10
  keys Space c
  expect_screen "lazygit asks for the commit summary" "Commit summary"
  keys "commit in lazygit" Enter
  probe "lazygit: c commits with a message" 'vim.trim(vim.fn.system("git -C " .. vim.fn.getcwd() .. " log -1 --format=%s"))' "commit in lazygit" 10
  keys q
  probe "lazygit: q returns to the window it came from, in normal mode" 'vim.api.nvim_get_current_win() == vim.g.home and vim.fn.mode() == "n" and 1 or 0' 1 10
  stop_nvim
}

test_review_debug() {
  review_repo debug
  local repo="$PROJ/debug" g=(git -c user.name=t -c user.email=t@t)
  printf 'x = 1\ny = x + 1\nprint(y)\n' >"$repo/d.py"
  "${g[@]}" -C "$repo" add d.py && "${g[@]}" -C "$repo" commit -qm py
  printf '# changed\n' >>"$repo/d.py"
  start_nvim "$repo" other.txt
  keys Space g D
  probe "debug in a review: the review opens" 'vim.fn.tabpagenr("$")' 2 20
  probe "and shows d.py on the real side" 'vim.fn.winnr("$")' 3 10
  keys C-l C-l
  probe "the cursor is on d.py" 'vim.fn.expand("%:t")' d.py 10
  keys :2 Enter
  keys ,db
  keys ,dc
  probe "debug in a review: stops at the breakpoint" 'require("dap").session() and require("dap").session().stopped_thread_id and 1 or 0' 1 60
  probe "the debug panels open in the review tab" 'P.dap_panels()' 2 10
  probe "no tab is added" 'vim.fn.tabpagenr("$")' 2 5
  keys ,dt
  keys ,du
  probe ",du gives the review its three windows back" 'vim.fn.winnr("$")' 3 10
  probe "and the sides stay unwrapped" 'vim.wo.wrap and 1 or 0' 0 5
  stop_nvim
}
