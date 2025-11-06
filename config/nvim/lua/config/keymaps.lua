local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- General
map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>w", ":w<CR>", opts)

-- File Explorer (NvimTree)
map("n", "<leader>e", ":NvimTreeToggle<CR>", opts)
map("n", "<leader>r", ":NvimTreeRefresh<CR>", opts)
map("n", "<leader>f", ":NvimTreeFindFile<CR>", opts)

-- Telescope
map("n", "<leader>ff", ":Telescope find_files<CR>", opts)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opts)

-- LSP
map("n", "K", vim.lsp.buf.hover, opts)
map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "gr", vim.lsp.buf.references, opts)
map("n", "gi", vim.lsp.buf.implementation, opts)
map("n", "<leader>rn", vim.lsp.buf.rename, opts)
map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
map("n", "[d", vim.diagnostic.goto_prev, opts)
map("n", "]d", vim.diagnostic.goto_next, opts)
map("n", "<leader>e", vim.diagnostic.open_float, opts)
