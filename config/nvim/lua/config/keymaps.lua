-- lua/config/keymaps.lua
-- Centralized keybindings configuration (Emacs-style organization)

local map = vim.keymap.set

-----------------------------------------------------------
-- Basic Commands
-----------------------------------------------------------
map("n", "<leader>q", ":q<CR>", { noremap = true, silent = true, desc = "Quit" })
map("n", "<leader>s", ":w<CR>", { noremap = true, silent = true, desc = "Save" })

-----------------------------------------------------------
-- Open/Toggle (o prefix - like Emacs open)
-----------------------------------------------------------
map("n", "<leader>op", ":NvimTreeToggle<CR>", { noremap = true, silent = true, desc = "Toggle File Tree" })
map("n", "<leader>or", ":NvimTreeRefresh<CR>", { noremap = true, silent = true, desc = "Refresh Tree" })
map("n", "<leader>of", ":NvimTreeFindFile<CR>", { noremap = true, silent = true, desc = "Find File in Tree" })

-----------------------------------------------------------
-- File/Find (f prefix)
-----------------------------------------------------------
map("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true, desc = "Find Files" })
map("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true, desc = "Live Grep" })
map("n", "<leader>fr", ":Telescope oldfiles<CR>", { noremap = true, silent = true, desc = "Recent Files" })

-----------------------------------------------------------
-- LSP (l prefix - like Emacs)
-----------------------------------------------------------
map("n", "<leader>ld", vim.lsp.buf.definition, { noremap = true, silent = true, desc = "Find Definition" })
map("n", "<leader>lr", vim.lsp.buf.references, { noremap = true, silent = true, desc = "Find References" })
map("n", "<leader>li", vim.lsp.buf.implementation, { noremap = true, silent = true, desc = "Find Implementation" })
map("n", "<leader>lt", vim.lsp.buf.type_definition, { noremap = true, silent = true, desc = "Find Type Definition" })
map("n", "<leader>ln", vim.lsp.buf.rename, { noremap = true, silent = true, desc = "Rename Symbol" })
map("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, { noremap = true, silent = true, desc = "Format Buffer" })
map("n", "<leader>la", vim.lsp.buf.code_action, { noremap = true, silent = true, desc = "Execute Code Action" })
map("n", "<leader>lh", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "Show Documentation" })
map("n", "<leader>lD", vim.lsp.buf.declaration, { noremap = true, silent = true, desc = "Go to Declaration" })
map("n", "<leader>lR", ":LspRestart<CR>", { noremap = true, silent = true, desc = "Restart LSP" })

-- LSP Diagnostics
map("n", "<leader>ll", vim.diagnostic.setloclist, { noremap = true, silent = true, desc = "List Diagnostics" })
map("n", "[d", vim.diagnostic.goto_prev, { noremap = true, silent = true, desc = "Previous Diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { noremap = true, silent = true, desc = "Next Diagnostic" })

-- Alternative single-key LSP bindings (optional, for quick access)
map("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "Hover Documentation" })
map("n", "gd", vim.lsp.buf.definition, { noremap = true, silent = true, desc = "Go to Definition" })
map("n", "gr", vim.lsp.buf.references, { noremap = true, silent = true, desc = "Go to References" })
map("n", "gi", vim.lsp.buf.implementation, { noremap = true, silent = true, desc = "Go to Implementation" })

-----------------------------------------------------------
-- Code (c prefix - like Emacs)
-----------------------------------------------------------
map("n", "<leader>cc", "gcc", { remap = true, desc = "Comment Line" })
map("v", "<leader>cc", "gc", { remap = true, desc = "Comment Selection" })
map("n", "<leader>ct", "gcc", { remap = true, desc = "Toggle Comment" })
map("n", "<leader>cj", vim.lsp.buf.definition, { noremap = true, silent = true, desc = "Jump to Definition" })
map("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, { noremap = true, silent = true, desc = "Format Code" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { noremap = true, silent = true, desc = "Code Action" })
map("n", "<leader>cr", vim.lsp.buf.rename, { noremap = true, silent = true, desc = "Rename" })

-----------------------------------------------------------
-- Window Management (w prefix - like Emacs)
-----------------------------------------------------------
-- Window Navigation
map("n", "<leader>wh", "<C-w>h", { noremap = true, silent = true, desc = "Move to Left Window" })
map("n", "<leader>wj", "<C-w>j", { noremap = true, silent = true, desc = "Move to Window Below" })
map("n", "<leader>wk", "<C-w>k", { noremap = true, silent = true, desc = "Move to Window Above" })
map("n", "<leader>wl", "<C-w>l", { noremap = true, silent = true, desc = "Move to Right Window" })
map("n", "<leader>ww", "<C-w>w", { noremap = true, silent = true, desc = "Jump to Next Window" })

-- Window Splits
map("n", "<leader>wv", "<cmd>vsplit<CR>", { noremap = true, silent = true, desc = "Split Window Vertically" })
map("n", "<leader>ws", "<cmd>split<CR>", { noremap = true, silent = true, desc = "Split Window Horizontally" })
map("n", "<leader>wo", "<C-w>o", { noremap = true, silent = true, desc = "Close Other Windows (Maximize)" })

-- Window Resize
map("n", "<leader>wH", "<cmd>vertical resize -2<CR>", { noremap = true, silent = true, desc = "Narrow Window (Width)" })
map("n", "<leader>wJ", "<cmd>resize -2<CR>", { noremap = true, silent = true, desc = "Shrink Window (Height)" })
map("n", "<leader>wK", "<cmd>resize +2<CR>", { noremap = true, silent = true, desc = "Enlarge Window (Height)" })
map("n", "<leader>wL", "<cmd>vertical resize +2<CR>", { noremap = true, silent = true, desc = "Widen Window (Width)" })
map("n", "<leader>w=", "<C-w>=", { noremap = true, silent = true, desc = "Balance Window Sizes" })

-- Window Close
map("n", "<leader>wc", "<C-w>c", { noremap = true, silent = true, desc = "Close Current Window" })
map("n", "<leader>wq", ":q<CR>", { noremap = true, silent = true, desc = "Quit Window" })

-- Alternative arrow key resizing (keep if you like)
map("n", "<C-Up>", "<cmd>resize +2<CR>", { noremap = true, silent = true, desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { noremap = true, silent = true, desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { noremap = true, silent = true, desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { noremap = true, silent = true, desc = "Increase Window Width" })

-----------------------------------------------------------
-- Buffer Management (b prefix)
-----------------------------------------------------------
map("n", "<leader>bb", "<cmd>lua if pcall(require, 'telescope.builtin') then require('telescope.builtin').buffers() end<CR>", { noremap = true, silent = true, desc = "List Buffers" })
map("n", "<leader>bd", "<cmd>bp<bar>bd #<CR>", { noremap = true, silent = true, desc = "Close Buffer" })
map("n", "<leader>bn", "<cmd>bnext<CR>", { noremap = true, silent = true, desc = "Next Buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { noremap = true, silent = true, desc = "Previous Buffer" })
map("n", "<leader>bk", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Kill Buffer" })

-- Alternative Tab navigation (keep if you like)
map("n", "<Tab>", "<cmd>bnext<CR>", { noremap = true, silent = true, desc = "Next Buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { noremap = true, silent = true, desc = "Previous Buffer" })

-----------------------------------------------------------
-- Git (g prefix)
-----------------------------------------------------------
local ok_gs, gs = pcall(require, "gitsigns")
if ok_gs then
  map("n", "<leader>gs", gs.stage_hunk, { noremap = true, silent = true, desc = "Stage Hunk" })
  map("n", "<leader>gr", gs.reset_hunk, { noremap = true, silent = true, desc = "Reset Hunk" })
  map("n", "<leader>gu", gs.undo_stage_hunk, { noremap = true, silent = true, desc = "Undo Stage Hunk" })
  map("n", "<leader>gp", gs.preview_hunk, { noremap = true, silent = true, desc = "Preview Hunk" })
  map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, { noremap = true, silent = true, desc = "Blame Line" })
  map("n", "<leader>gB", gs.toggle_current_line_blame, { noremap = true, silent = true, desc = "Toggle Blame" })
  map("n", "<leader>gd", gs.diffthis, { noremap = true, silent = true, desc = "Diff This" })
  map("n", "]c", function() gs.next_hunk() end, { noremap = true, silent = true, desc = "Next Git Hunk" })
  map("n", "[c", function() gs.prev_hunk() end, { noremap = true, silent = true, desc = "Previous Git Hunk" })
end

-----------------------------------------------------------
-- Diagnostics/Trouble (d prefix - for diagnostics)
-----------------------------------------------------------
map("n", "<leader>dx", "<cmd>TroubleToggle<CR>", { noremap = true, silent = true, desc = "Toggle Trouble" })
map("n", "<leader>dw", "<cmd>TroubleToggle workspace_diagnostics<CR>", { noremap = true, silent = true, desc = "Workspace Diagnostics" })
map("n", "<leader>dd", "<cmd>TroubleToggle document_diagnostics<CR>", { noremap = true, silent = true, desc = "Document Diagnostics" })
map("n", "<leader>dl", "<cmd>TroubleToggle loclist<CR>", { noremap = true, silent = true, desc = "Loclist" })
map("n", "<leader>dq", "<cmd>TroubleToggle quickfix<CR>", { noremap = true, silent = true, desc = "Quickfix" })

-----------------------------------------------------------
-- Todo Comments (still under d prefix since it's diagnostic-related)
-----------------------------------------------------------
local ok_todo, todo = pcall(require, "todo-comments")
if ok_todo then
  map("n", "]t", function() todo.jump_next() end, { noremap = true, silent = true, desc = "Next Todo" })
  map("n", "[t", function() todo.jump_prev() end, { noremap = true, silent = true, desc = "Previous Todo" })
  map("n", "<leader>dt", "<cmd>TodoTrouble<CR>", { noremap = true, silent = true, desc = "Todo Trouble" })
  map("n", "<leader>dT", "<cmd>TodoTelescope<CR>", { noremap = true, silent = true, desc = "Todo Telescope" })
end

-----------------------------------------------------------
-- Terminal (t prefix)
-----------------------------------------------------------
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", { noremap = true, silent = true, desc = "Float Terminal" })
map("n", "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<CR>", { noremap = true, silent = true, desc = "Horizontal Terminal" })
map("n", "<leader>tv", "<cmd>ToggleTerm size=60 direction=vertical<CR>", { noremap = true, silent = true, desc = "Vertical Terminal" })
map("n", "<leader>tg", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true, desc = "Lazygit" })

-----------------------------------------------------------
-- Quick Jump (Hop) - Keep s/S for hop since it's intuitive
-----------------------------------------------------------
local ok_hop, hop = pcall(require, "hop")
if ok_hop then
  local directions = require("hop.hint").HintDirection
  map("", "f", function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
  end, { remap = true, desc = "Hop Forward to Char" })
  map("", "F", function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
  end, { remap = true, desc = "Hop Backward to Char" })
  map("", "t", function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
  end, { remap = true, desc = "Hop Forward Til Char" })
  map("", "T", function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
  end, { remap = true, desc = "Hop Backward Til Char" })
  map("n", "s", ":HopChar2<CR>", { noremap = true, silent = true, desc = "Hop to 2 Chars" })
  map("n", "S", ":HopWord<CR>", { noremap = true, silent = true, desc = "Hop to Word" })
end

-----------------------------------------------------------
-- Quick Switch (Harpoon) - m prefix for "marks"
-----------------------------------------------------------
local ok_harpoon, harpoon = pcall(require, "harpoon")
if ok_harpoon then
  map("n", "<leader>ma", function() harpoon:list():append() end, { noremap = true, silent = true, desc = "Add File (Harpoon)" })
  map("n", "<leader>mm", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { noremap = true, silent = true, desc = "Harpoon Menu" })
  map("n", "<leader>m1", function() harpoon:list():select(1) end, { noremap = true, silent = true, desc = "Harpoon File 1" })
  map("n", "<leader>m2", function() harpoon:list():select(2) end, { noremap = true, silent = true, desc = "Harpoon File 2" })
  map("n", "<leader>m3", function() harpoon:list():select(3) end, { noremap = true, silent = true, desc = "Harpoon File 3" })
  map("n", "<leader>m4", function() harpoon:list():select(4) end, { noremap = true, silent = true, desc = "Harpoon File 4" })
  map("n", "<leader>mn", function() harpoon:list():next() end, { noremap = true, silent = true, desc = "Harpoon Next" })
  map("n", "<leader>mp", function() harpoon:list():prev() end, { noremap = true, silent = true, desc = "Harpoon Previous" })
end

-----------------------------------------------------------
-- Smart Window Movement (Ctrl + hjkl)
-- Only map if not already taken by Harpoon or other plugins
-----------------------------------------------------------
local function is_mapped(mode, lhs)
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    if m.lhs == lhs then return true end
  end
  return false
end

if not is_mapped("n", "<C-h>") then 
  map("n", "<C-h>", "<C-w>h", { noremap = true, silent = true, desc = "Move to Left Window" }) 
end
if not is_mapped("n", "<C-j>") then 
  map("n", "<C-j>", "<C-w>j", { noremap = true, silent = true, desc = "Move to Bottom Window" }) 
end
if not is_mapped("n", "<C-k>") then 
  map("n", "<C-k>", "<C-w>k", { noremap = true, silent = true, desc = "Move to Top Window" }) 
end
if not is_mapped("n", "<C-l>") then 
  map("n", "<C-l>", "<C-w>l", { noremap = true, silent = true, desc = "Move to Right Window" }) 
end
