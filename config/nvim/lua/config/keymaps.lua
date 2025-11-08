-- lua/config/keymaps.lua
-- Centralized keybindings configuration

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-----------------------------------------------------------
-- Basic Commands
-----------------------------------------------------------
map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>w", ":w<CR>", opts)

-----------------------------------------------------------
-- File Navigation (NvimTree + Telescope)
-----------------------------------------------------------
map("n", "<leader>e", ":NvimTreeToggle<CR>", opts)
map("n", "<leader>r", ":NvimTreeRefresh<CR>", opts)
map("n", "<leader>f", ":NvimTreeFindFile<CR>", opts)

map("n", "<leader>ff", ":Telescope find_files<CR>", opts)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opts)

-----------------------------------------------------------
-- Quick Jump (Hop)
-----------------------------------------------------------
local ok_hop, hop = pcall(require, "hop")
if ok_hop then
  local directions = require("hop.hint").HintDirection
  map("", "f", function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
  end, { remap = true })
  map("", "F", function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
  end, { remap = true })
  map("", "t", function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
  end, { remap = true })
  map("", "T", function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
  end, { remap = true })
  map("n", "s", ":HopChar2<CR>", opts)
  map("n", "S", ":HopWord<CR>", opts)
end

-----------------------------------------------------------
-- Quick Switch (Harpoon)
-----------------------------------------------------------
local ok_harpoon, harpoon = pcall(require, "harpoon")
if ok_harpoon then
  map("n", "<leader>a", function() harpoon:list():append() end, opts)
  map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, opts)
  map("n", "<C-h>", function() harpoon:list():select(1) end, opts)
  map("n", "<C-j>", function() harpoon:list():select(2) end, opts)
  map("n", "<C-k>", function() harpoon:list():select(3) end, opts)
  map("n", "<C-l>", function() harpoon:list():select(4) end, opts)
  map("n", "<C-S-P>", function() harpoon:list():prev() end, opts)
  map("n", "<C-S-N>", function() harpoon:list():next() end, opts)
end

-----------------------------------------------------------
-- Code Navigation (LSP)
-----------------------------------------------------------
map("n", "K", vim.lsp.buf.hover, opts)
map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "gr", vim.lsp.buf.references, opts)
map("n", "gi", vim.lsp.buf.implementation, opts)
map("n", "<leader>rn", vim.lsp.buf.rename, opts)
map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
map("n", "[d", vim.diagnostic.goto_prev, opts)
map("n", "]d", vim.diagnostic.goto_next, opts)
map("n", "<leader>d", vim.diagnostic.open_float, opts)

-----------------------------------------------------------
-- Git (Gitsigns)
-----------------------------------------------------------
local ok_gs, gs = pcall(require, "gitsigns")
if ok_gs then
  map("n", "]c", function() gs.next_hunk() end, opts)
  map("n", "[c", function() gs.prev_hunk() end, opts)
  map("n", "<leader>hs", gs.stage_hunk, opts)
  map("n", "<leader>hr", gs.reset_hunk, opts)
  map("n", "<leader>hu", gs.undo_stage_hunk, opts)
  map("n", "<leader>hp", gs.preview_hunk, opts)
  map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, opts)
  map("n", "<leader>tb", gs.toggle_current_line_blame, opts)
  map("n", "<leader>hd", gs.diffthis, opts)
end

-----------------------------------------------------------
-- Diagnostics (Trouble)
-----------------------------------------------------------
map("n", "<leader>xx", "<cmd>TroubleToggle<CR>", opts)
map("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<CR>", opts)
map("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>", opts)
map("n", "<leader>xl", "<cmd>TroubleToggle loclist<CR>", opts)
map("n", "<leader>xq", "<cmd>TroubleToggle quickfix<CR>", opts)

-----------------------------------------------------------
-- Todo Comments
-----------------------------------------------------------
local ok_todo, todo = pcall(require, "todo-comments")
if ok_todo then
  map("n", "]t", function() todo.jump_next() end, opts)
  map("n", "[t", function() todo.jump_prev() end, opts)
  map("n", "<leader>xt", "<cmd>TodoTrouble<CR>", opts)
  map("n", "<leader>xT", "<cmd>TodoTelescope<CR>", opts)
end

-----------------------------------------------------------
-- Terminal
-----------------------------------------------------------
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", opts)
map("n", "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<CR>", opts)
map("n", "<leader>tv", "<cmd>ToggleTerm size=60 direction=vertical<CR>", opts)
map("n", "<leader>tg", "<cmd>lua _lazygit_toggle()<CR>", opts)

-----------------------------------------------------------
-- Buffer Navigation
-----------------------------------------------------------
map("n", "<Tab>", "<cmd>bnext<CR>", opts)
map("n", "<S-Tab>", "<cmd>bprevious<CR>", opts)
map("n", "<leader>bd", "<cmd>bp<bar>bd #<CR>", opts)
map("n", "<leader>bb", "<cmd>lua if pcall(require, 'telescope.builtin') then require('telescope.builtin').buffers() end<CR>", opts)

-----------------------------------------------------------
-- Splits
-----------------------------------------------------------
map("n", "<leader>sv", "<cmd>vsplit<CR>", opts)
map("n", "<leader>sh", "<cmd>split<CR>", opts)
map("n", "<leader>sc", "<C-w>c", opts)
map("n", "<leader>so", "<C-w>o", opts)

-----------------------------------------------------------
-- Window Movement (Smart)
-----------------------------------------------------------
local function is_mapped(mode, lhs)
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    if m.lhs == lhs then return true end
  end
  return false
end

if not is_mapped("n", "<C-h>") then map("n", "<C-h>", "<C-w>h", opts) end
if not is_mapped("n", "<C-j>") then map("n", "<C-j>", "<C-w>j", opts) end
if not is_mapped("n", "<C-k>") then map("n", "<C-k>", "<C-w>k", opts) end
if not is_mapped("n", "<C-l>") then map("n", "<C-l>", "<C-w>l", opts) end

-----------------------------------------------------------
-- Resize Splits
-----------------------------------------------------------
map("n", "<C-Up>", "<cmd>resize +2<CR>", opts)
map("n", "<C-Down>", "<cmd>resize -2<CR>", opts)
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opts)
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)
