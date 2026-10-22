test_review() {
  local repo="$PROJ/review" g=(git -c user.name=t -c user.email=t@t)
  rm -rf "$repo" "$PROJ/review.git"
  git init -q --bare "$PROJ/review.git" && git -C "$PROJ" clone -q review.git review 2>/dev/null
  printf 'a = 1\n\nb = 2\n' >"$repo/r.lua"
  "${g[@]}" -C "$repo" add r.lua && "${g[@]}" -C "$repo" commit -qm base && git -C "$repo" push -q origin HEAD 2>/dev/null
  printf 'a = 1\n\nb = 3\n' >"$repo/r.lua"
  "${g[@]}" -C "$repo" commit -qam change
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
  keys Space u w
  probe "Space u w in a review keeps the sides unwrapped" 'vim.wo.wrap and 1 or 0' 0 5
  probe "and says why" "$(notified "Wrap stays off in a review")" 1 5
  keys g g O
  keys "x = 0" Escape
  keys Space s
  probe "an edit on the real side reaches the disk" 'vim.fn.readfile(vim.fn.expand("%:p"))[1]' "x = 0" 10
  keys Space g e
  probe "Space g e hides the file list" 'vim.fn.winnr("$")' 2 5
  keys Space g e
  probe "Space g e shows it again" 'vim.fn.winnr("$")' 3 5
  keys Space o p
  probe "Space o p hides the file list in a review" 'vim.fn.winnr("$")' 2 5
  keys Space o p
  probe "Space o p shows the file list again" 'vim.fn.winnr("$")' 3 5
  probe "gc stays the comment operator in a review" 'vim.fn.maparg("gc", "n", false, true).buffer or 0' 0 5
  keys Space f f
  sleep 1
  keys r.lua Enter
  probe "Space g V: a picked file opens in a jump tab just before the review" 'vim.fn.tabpagenr("$") * 10 + vim.fn.tabpagenr()' 32 10
  probe "Space g V: that tab wraps" 'vim.wo.wrap and 1 or 0' 1 5
  probe "Space g V: the review keeps its diff" '#vim.fn.tabpagebuflist(3)' 3 5
  keys Space g q
  probe "Space g q closes that tab and returns to the review" 'vim.fn.tabpagenr("$") * 10 + vim.fn.tabpagenr()' 22 10
  keys g f
  probe "gf opens the file in a jump tab too" 'vim.fn.tabpagenr("$") * 10 + vim.fn.tabpagenr()' 32 10
  probe "and leaves the first tab's file alone" 'vim.fn.fnamemodify(vim.fn.bufname(vim.fn.tabpagebuflist(1)[1]), ":t")' other.txt 5
  keys g t
  keys Space f f
  sleep 1
  keys r.lua Enter
  probe "a second pick reuses the jump tab" 'vim.fn.tabpagenr("$") * 10 + vim.fn.tabpagenr()' 32 10
  keys g t
  keys C-h C-h
  probe "the cursor goes back to the file list" 'vim.bo.filetype' codediff-explorer 5
  keys q
  probe "q closes the review and its jump tab" 'vim.fn.tabpagenr("$")' 1 10
  send ':edit r.lua<CR>'
  keys Space g d
  probe "Space g d reviews the file against HEAD" 'vim.fn.tabpagenr("$")' 2 20
  keys Space g q
  probe "Space g q in a review closes it" 'vim.fn.tabpagenr("$")' 1 10
  stop_nvim
}

test_lazygit() {
  local repo="$PROJ/review" staged='vim.trim(vim.fn.system("git -C " .. vim.fn.getcwd() .. " diff --cached --name-only"))'
  if ! have lazygit; then
    skip "lazygit stage and commit" "lazygit not installed"
    return
  fi
  printf 'a = 1\n\nb = 4\n' >"$repo/r.lua"
  printf 'disableStartupPopups: true\n' >"$T/lazygit.yml"
  LG_CONFIG_FILE="$T/lazygit.yml" start_nvim "$repo" other.txt
  keys Space g D
  probe "Space g D reviews the working tree" 'vim.fn.tabpagenr("$")' 2 20
  keys Space g D
  probe "Space g D inside a review closes it" 'vim.fn.tabpagenr("$")' 1 10
  keys Space g g
  probe "lazygit opens in terminal mode" 'vim.fn.mode()' t 20
  sleep 2
  keys j e
  probe "lazygit: e opens the file in a new tab" 'vim.fn.expand("%:t") .. vim.fn.tabpagenr("$")' r.lua2 15
  probe "lazygit: and that tab is in normal mode" 'vim.fn.mode()' n 5
  stop_nvim
  LG_CONFIG_FILE="$T/lazygit.yml" start_nvim "$repo" r.lua
  keys Space w v
  send ':lua vim.g.home = vim.api.nvim_get_current_win()<CR>'
  keys Space g g
  probe "lazygit opens in terminal mode" 'vim.fn.mode()' t 20
  sleep 2
  keys Space
  probe "lazygit: space stages the file" "$staged" r.lua 10
  keys Space
  probe "lazygit: space unstages it" "$staged" "" 10
  keys Space c
  sleep 1
  keys "commit in lazygit" Enter
  probe "lazygit: c commits with a message" 'vim.trim(vim.fn.system("git -C " .. vim.fn.getcwd() .. " log -1 --format=%s"))' "commit in lazygit" 10
  keys q
  probe "lazygit: q returns to the window it came from, in normal mode" 'vim.api.nvim_get_current_win() == vim.g.home and vim.fn.mode() == "n" and 1 or 0' 1 10
  stop_nvim
}

test_review_debug() {
  local repo="$PROJ/review" g=(git -c user.name=t -c user.email=t@t)
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
  probe "the debug panels open in the review tab" '#vim.tbl_filter(function(w) return vim.bo[vim.api.nvim_win_get_buf(w)].filetype:find("dap") end, vim.api.nvim_tabpage_list_wins(0))' 6 10
  probe "no tab is added" 'vim.fn.tabpagenr("$")' 2 5
  keys ,dt
  keys ,du
  probe ",du gives the review its three windows back" 'vim.fn.winnr("$")' 3 10
  probe "and the sides stay unwrapped" 'vim.wo.wrap and 1 or 0' 0 5
  stop_nvim
  "${g[@]}" -C "$repo" checkout -q d.py
}
