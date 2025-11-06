local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>w", ":w<CR>", opts)

-- File Navigation
map("n", "<leader>e", ":NvimTreeToggle<CR>", opts)
map("n", "<leader>r", ":NvimTreeRefresh<CR>", opts)
map("n", "<leader>f", ":NvimTreeFindFile<CR>", opts)

map("n", "<leader>ff", ":Telescope find_files<CR>", opts)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opts)

-- Quick Jump (Hop)
local hop = require("hop")
local directions = require("hop.hint").HintDirection
map("", "f", function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true }) end, { remap = true })
map("", "F", function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true }) end, { remap = true })
map("", "t", function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 }) end, { remap = true })
map("", "T", function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 }) end, { remap = true })
map("n", "s", ":HopChar2<cr>", { silent = true })
map("n", "S", ":HopWord<cr>", { silent = true })

-- Quick Switch (Harpoon)
local harpoon = require("harpoon")
map("n", "<leader>a", function() harpoon:list():append() end, opts)
map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, opts)
map("n", "<C-h>", function() harpoon:list():select(1) end, opts)
map("n", "<C-j>", function() harpoon:list():select(2) end, opts)
map("n", "<C-k>", function() harpoon:list():select(3) end, opts)
map("n", "<C-l>", function() harpoon:list():select(4) end, opts)
map("n", "<C-S-P>", function() harpoon:list():prev() end, opts)
map("n", "<C-S-N>", function() harpoon:list():next() end, opts)

-- Code Navigation
map("n", "K", vim.lsp.buf.hover, opts)
map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "gr", vim.lsp.buf.references, opts)
map("n", "gi", vim.lsp.buf.implementation, opts)
map("n", "<leader>rn", vim.lsp.buf.rename, opts)
map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
map("n", "[d", vim.diagnostic.goto_prev, opts)
map("n", "]d", vim.diagnostic.goto_next, opts)
map("n", "<leader>e", vim.diagnostic.open_float, opts)
