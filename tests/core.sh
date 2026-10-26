test_look() {
  {
    echo 'local function long()'
    for i in $(seq 1 80); do echo "  local v$i = $i"; done
    printf 'end\nreturn long\n'
  } >"$PROJ/look.lua"
  start_nvim "$PROJ" look.lua
  probe "mini.statusline draws the statusline" 'vim.o.statusline:find("MiniStatusline", 1, true) and 1 or 0' 1 15
  probe "Snacks draws the status column" 'vim.wo.statuscolumn:find("snacks.statuscolumn", 1, true) and 1 or 0' 1 15
  probe "ui2 draws the messages and the : line" 'vim.api.nvim_win_is_valid(require("vim._core.ui2").wins.cmd) and 1 or 0' 1 15
  lua_do 'vim.api.nvim_echo({ { "look" } }, false, { id = "look", kind = "progress", source = "test", status = "running", percent = 40 })'
  probe "the statusline shows running progress" 'MiniStatusline.active():find(vim.trim(vim.ui.progress_status()), 1, true) and vim.ui.progress_status() ~= "" and 1 or 0' 1 10
  lua_do 'vim.api.nvim_echo({ { "look" } }, false, { id = "look", kind = "progress", source = "test", status = "success", percent = 100 })'
  keys 70G
  probe "treesitter-context shows the enclosing function" '#vim.tbl_filter(function(w) return vim.w[w].treesitter_context end, vim.api.nvim_list_wins())' 1 15
  keys C-w v
  probe "C-w v opens a window on the right" 'vim.fn.win_screenpos(0)[2] > 1 and 1 or 0' 1 5
  keys C-w h
  probe "C-w h moves to the left window" 'vim.fn.win_screenpos(0)[2]' 1 5
  keys C-w l
  probe "C-w l moves to the right window" 'vim.fn.win_screenpos(0)[2] > 1 and 1 or 0' 1 5
  stop_nvim
}

test_windows() {
  start_nvim "$PROJ" look.lua
  probe "a file window shows its path in the winbar" 'vim.wo.winbar' " %f%m" 10
  keys C-w v
  probe "C-w v: two windows" "$(tiles)" 2 5
  probe "only the current window has the cursorline" '#vim.tbl_filter(function(w) return vim.wo[w].cursorline end, vim.api.nvim_tabpage_list_wins(0))' 1 5
  keys C-w s
  probe "C-w s: three windows" "$(tiles)" 3 5
  keys C-j
  probe "C-j goes to the window below" 'vim.fn.win_screenpos(0)[1] > 1 and 1 or 0' 1 5
  keys C-k
  probe "C-k goes to the window above" 'vim.fn.win_screenpos(0)[1]' 1 5
  send ':lua vim.g.w0 = vim.api.nvim_win_get_width(0)<CR>'
  keys 2 C-w '>'
  probe "2 C-w > makes the window 2 columns wider" 'vim.api.nvim_win_get_width(0) - vim.g.w0' 2 5
  keys 2 C-w '<'
  probe "2 C-w < narrows it again" 'vim.api.nvim_win_get_width(0) - vim.g.w0' 0 5
  keys C-w c
  probe "C-w c closes the window" "$(tiles)" 2 5
  keys C-w o
  probe "C-w o closes the others" "$(tiles)" 1 5
  keys :e Space sample.lua Enter
  probe "a second buffer opens" 'vim.fn.expand("%:t")' sample.lua 10
  keys [ b
  probe "[b goes to the previous buffer" 'vim.fn.expand("%:t")' look.lua 5
  keys ] b
  probe "]b goes to the next buffer" 'vim.fn.expand("%:t")' sample.lua 5
  keys C-w v
  keys Space b d
  probe "Space b d keeps both windows" "$(tiles)" 2 5
  probe "Space b d shows the other buffer" 'vim.fn.expand("%:t")' look.lua 5
  keys C-w o
  keys Space b d
  probe "Space b d on the last buffer shows the dashboard" 'vim.bo.filetype' snacks_dashboard 10
  stop_nvim
  start_nvim "$PROJ" look.lua
  keys C-w v
  keys Space u w
  probe "Space u w unwraps every window" '#vim.tbl_filter(function(w) return vim.api.nvim_win_get_config(w).relative == "" and vim.wo[w].wrap end, vim.api.nvim_tabpage_list_wins(0))' 0 5
  keys Space u w
  probe "Space u w wraps them again" '#vim.tbl_filter(function(w) return vim.api.nvim_win_get_config(w).relative == "" and vim.wo[w].wrap end, vim.api.nvim_tabpage_list_wins(0))' 2 5
  keys :help Enter
  probe ":help opens a help window" 'vim.bo.filetype' help 10
  keys q
  probe "q closes help and returns to the code" 'vim.bo.filetype' lua 5
  stop_nvim
}
