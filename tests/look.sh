test_lua() {
  printf 'local x = 1\nreturn x\n' >"$PROJ/sample.lua"
  if ! mason lua-language-server; then
    skip "lua_ls attaches to Lua" "not installed by Mason"
    return
  fi
  start_nvim "$PROJ" sample.lua
  probe "lua_ls attaches to Lua" "$(clients lua_ls)" 1 60
  stop_nvim
}

test_look() {
  {
    echo 'local function long()'
    for i in $(seq 1 80); do echo "  local v$i = $i"; done
    printf 'end\nreturn long\n'
  } >"$PROJ/look.lua"
  start_nvim "$PROJ" look.lua
  probe "mini.statusline draws the statusline" 'vim.o.statusline:find("MiniStatusline", 1, true) and 1 or 0' 1 15
  probe "Snacks draws the status column" 'vim.wo.statuscolumn:find("snacks.statuscolumn", 1, true) and 1 or 0' 1 15
  keys 70G
  probe "treesitter-context shows the enclosing function" '#vim.tbl_filter(function(w) return vim.w[w].treesitter_context end, vim.api.nvim_list_wins())' 1 15
  keys Space w v
  probe "Space w v opens a window on the right" 'vim.fn.win_screenpos(0)[2] > 1 and 1 or 0' 1 5
  keys Space w h
  probe "Space w h moves to the left window" 'vim.fn.win_screenpos(0)[2]' 1 5
  keys Space w l
  probe "Space w l moves to the right window" 'vim.fn.win_screenpos(0)[2] > 1 and 1 or 0' 1 5
  stop_nvim
}
