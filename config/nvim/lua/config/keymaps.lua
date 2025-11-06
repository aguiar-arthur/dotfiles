local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>w", ":w<CR>", opts)
map("n", "<leader>e", ":NvimTreeToggle<CR>", opts)
map("n", "<leader>ff", ":Telescope find_files<CR>", opts)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opts)
