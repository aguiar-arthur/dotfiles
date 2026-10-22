roundtrip() {
  keys Space $2
  probe "$1: opens in terminal mode" 'vim.fn.mode()' t 20
  keys $3
  probe "$1: closing returns to the window it came from" 'vim.api.nvim_get_current_win() == vim.g.home and vim.fn.mode() == "n" and 1 or 0' 1 10
}

claude_stub() {
  send ":lua local c = require(\"claudecode\"); c.start(); require(\"claudecode.terminal\").setup({}, \"${1:-sleep 600}\"); c.is_claude_connected = function() return true end; c._broadcast_at_mention = function() return true, nil, { file_path = \"x\" } end<CR>"
}

test_claude() {
  start_nvim "$PROJ" look.lua
  claude_stub
  keys V j Space a s
  probe "Space a s opens Claude with the cursor in it, in terminal mode" 'vim.fn.mode() .. vim.bo.buftype' tterminal 20
  keys C-\\ C-n
  keys q
  probe "q hides Claude and returns to the code in normal mode" 'vim.fn.mode() .. vim.bo.buftype' n 5
  keys C-w v
  set_home
  roundtrip "Space t f" "t f" "C-\\ C-n q"
  roundtrip "Space a c" "a c" "C-\\ C-n q"
  keys C-w l
  set_home
  roundtrip "Space t f (other window)" "t f" "C-\\ C-n q"
  roundtrip "Space a c (other window)" "a c" "C-\\ C-n q"
  keys Space o p
  probe "the file tree takes the cursor" 'vim.bo.filetype' snacks_picker_list 15
  set_home
  keys Space a b
  probe "Space a b in the tree opens Claude in terminal mode" 'vim.fn.mode()' t 20
  keys C-\\ C-n q
  probe "closing Claude returns to the tree" 'vim.bo.filetype' snacks_picker_list 5
  keys Space a B
  probe "Space a B in the tree opens Claude in terminal mode" 'vim.fn.mode()' t 20
  keys C-\\ C-n q
  keys q
  keys Space a c
  probe "Claude opens before a resize" 'vim.bo.buftype' terminal 10
  resize 120 30
  probe "Claude refits a smaller terminal" 'math.abs(vim.api.nvim_win_get_width(0) - 110) <= 2 and 1 or 0' 1 10
  resize 200 50
  probe "and a larger one" 'math.abs(vim.api.nvim_win_get_width(0) - 184) <= 2 and 1 or 0' 1 10
  stop_nvim
}

test_claude_notices() {
  printf '%s\n' "sleep 3; printf '\\033]9;needs you\\007'; sleep 600" >"$T/osc.sh"
  start_nvim "$PROJ" look.lua
  claude_stub "sh $T/osc.sh"
  keys Space a c
  sleep 1
  keys C-\\ C-n q
  probe "a message from a hidden Claude is notified" "$(notified "needs you")" 1 20
  stop_nvim
  start_nvim "$PROJ" look.lua
  claude_stub "sleep 2"
  keys Space a c
  keys C-\\ C-n q
  probe "a hidden Claude that exits is notified" "$(notified "Claude exited")" 1 20
  stop_nvim
}

test_terminals() {
  start_nvim "$PROJ" look.lua
  set_home
  keys Space t f
  probe "Space t f: the float terminal opens in terminal mode" 'vim.fn.mode() == "t" and vim.api.nvim_win_get_config(0).title[1][1] == " Terminal " and 1 or 0' 1 20
  lua_do 'vim.g.tbuf = vim.api.nvim_get_current_buf()'
  resize 120 30
  probe "the float refits a smaller terminal" 'math.abs(vim.api.nvim_win_get_width(0) - 110) <= 2 and math.abs(vim.api.nvim_win_get_height(0) - 27) <= 2 and 1 or 0' 1 10
  resize 200 50
  keys C-\\ C-n q
  probe "q hides the float and returns to the code" "$HOME_BACK" 1 10
  keys Space t f
  probe "Space t f again brings back the same terminal" 'vim.api.nvim_get_current_buf() == vim.g.tbuf and vim.fn.mode() == "t" and 1 or 0' 1 10
  keys C-\\ C-n q
  keys Space t h
  probe "Space t h: another terminal, 15 lines, in terminal mode" 'vim.fn.mode() == "t" and vim.api.nvim_win_get_height(0) == 15 and vim.api.nvim_get_current_buf() ~= vim.g.tbuf and 1 or 0' 1 20
  keys C-\\ C-n C-k
  probe "C-k from the bottom terminal reaches the code" "$HOME_BACK" 1 10
  keys Space t h
  probe "Space t h hides it" '#vim.tbl_filter(function(w) return vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "terminal" and not vim.api.nvim_win_get_config(w).hide end, vim.api.nvim_list_wins())' 0 10
  keys Space t v
  probe "Space t v: a terminal 60 columns wide in terminal mode" 'vim.fn.mode() == "t" and vim.api.nvim_win_get_width(0) == 60 and 1 or 0' 1 20
  stop_nvim
}

test_tree_and_pickers() {
  start_nvim "$PROJ" look.lua
  set_home
  keys Space o p
  probe "Space o p: the tree opens 40 columns wide with the cursor in it" 'vim.bo.filetype == "snacks_picker_list" and vim.api.nvim_win_get_width(0) == 40 and 1 or 0' 1 15
  keys C-l
  probe "C-l goes from the tree to the code" 'vim.bo.filetype' lua 5
  keys C-h
  probe "C-h goes back to the tree" 'vim.bo.filetype' snacks_picker_list 5
  keys q
  probe "q closes the tree and returns to the code" "$HOME_BACK" 1 10
  keys Space o p
  sleep 1
  keys Space o p
  probe "Space o p twice leaves no tree" "$(tiles)" 1 10
  keys Space f f
  probe "Space f f: the picker input is in insert mode" 'vim.fn.mode() .. vim.bo.filetype' isnacks_picker_input 15
  keys Escape
  probe "Escape once leaves insert mode and keeps the picker" 'vim.fn.mode() .. vim.bo.filetype' nsnacks_picker_input 5
  keys Escape
  probe "Escape twice closes the picker and returns to the code" "$HOME_BACK" 1 10
  keys Space f f
  sleep 1
  keys sample.lua
  sleep 1
  keys Enter
  probe "a picked file opens in the same window" 'vim.fn.expand("%:t")' sample.lua 10
  probe "and no window is added" "$(tiles)" 1 5
  keys Space f f
  sleep 1
  keys look.lua C-v
  probe "C-v in a picker opens a vertical split" "$(tiles)" 2 10
  keys C-w o
  keys Space o d
  probe "Space o d: the dashboard opens over the code" 'vim.bo.filetype' snacks_dashboard 10
  keys q
  probe "q on that dashboard closes it instead of quitting" 'vim.bo.filetype' lua 10
  stop_nvim
  start_nvim "$PROJ" look.lua
  lua_do 'vim.diagnostic.set(vim.api.nvim_create_namespace("test"), 0, { { lnum = 0, col = 0, message = "x" } })'
  keys Space d x
  probe "Space d x lists the diagnostics in a picker" 'vim.bo.filetype' snacks_picker_input 15
  probe "and the picker has the diagnostic" '(function() local p = Snacks.picker.get()[1] return p and p:count() or 0 end)()' 1 10
  keys Escape
  sleep 0.5
  keys Escape
  probe "Escape twice closes it and returns to the code" 'vim.bo.filetype' lua 5
  stop_nvim
}

test_sessions() {
  start_nvim "$PROJ" look.lua
  keys :vsplit Space Enter
  keys :tabnew Space sample.lua Enter
  probe "sessions: two tabs before quitting" 'vim.fn.tabpagenr("$")' 2 10
  keys :qa Enter
  start_nvim "$PROJ" look.lua
  keys Space S r
  probe "Space S r restores the tabs of the last session" 'vim.fn.tabpagenr("$")' 2 15
  keys Space S d
  keys :tabonly Enter
  keys :qa Enter
  start_nvim "$PROJ" look.lua
  keys Space S r
  probe "Space S d keeps the old session: the closed tab is back" 'vim.fn.tabpagenr("$")' 2 15
  stop_nvim
}
