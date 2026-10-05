-- "Core" keymaps (no plugin dependencies).
-- Plugin-specific keymaps live in each plugin spec (lua/plugins/*.lua),
-- via `keys = {}`, which also makes lazy.nvim load the plugin on demand.
-- LSP keymaps are buffer-local and live in lua/plugins/lsp.lua (LspAttach).
--
-- Group prefixes (kept from the previous configuration):
--   <leader>b buffer   c code   d diagnostics   D debug    f file/find
--   <leader>g git      l lsp    m marks         o open     S session
--   <leader>t terminal u ui     w window
--   <localleader> (",") → filetype keymaps (vimtex in .tex)

local map = vim.keymap.set
local function o(desc, extra)
  return vim.tbl_extend("force", { silent = true, desc = desc }, extra or {})
end

-- Basic ----------------------------------------------------------------
map("n", "<leader>q", "<cmd>q<CR>", o("Quit"))
map("n", "<leader>s", "<cmd>w<CR>", o("Save"))
map("n", "<Esc>", "<cmd>nohlsearch<CR>", o("Clear search highlight"))
map("n", "<leader>?", "<cmd>WhichKey<CR>", o("Show key bindings"))

-- Wrapped-line aware movement (useful with wrap in tex/md) -------------
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", o("Down", { expr = true }))
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", o("Up", { expr = true }))

-- Editing --------------------------------------------------------------
map("x", "<", "<gv", o("Indent left (keep selection)"))
map("x", ">", ">gv", o("Indent right (keep selection)"))
map("n", "<A-j>", "<cmd>m .+1<CR>==", o("Move line down"))
map("n", "<A-k>", "<cmd>m .-2<CR>==", o("Move line up"))
map("x", "<A-j>", ":m '>+1<CR>gv=gv", o("Move selection down"))
map("x", "<A-k>", ":m '<-2<CR>gv=gv", o("Move selection up"))
map("i", ",", ",<c-g>u", o("Undo breakpoint"))
map("i", ".", ".<c-g>u", o("Undo breakpoint"))

-- Code (commenting uses Neovim's native gc) -----------------------------
map("n", "<leader>cc", "gcc", { remap = true, desc = "Comment line" })
map("v", "<leader>cc", "gc", { remap = true, desc = "Comment selection" })

-- LSP defaults ----------------------------------------------------------
-- Neovim 0.11+ maps grn/grr/gra/gri/grt/grx globally. Our `gr` (references, lsp.lua)
-- would then wait 'timeoutlen' for a longer match; <leader>l covers all of them.
for _, lhs in ipairs({ "grn", "grr", "gra", "gri", "grt", "grx" }) do
  for _, mode in ipairs({ "n", "x" }) do
    pcall(vim.keymap.del, mode, lhs)
  end
end

-- Window ---------------------------------------------------------------
map("n", "<C-h>", "<C-w>h", o("Window left"))
map("n", "<C-j>", "<C-w>j", o("Window below"))
map("n", "<C-k>", "<C-w>k", o("Window above"))
map("n", "<C-l>", "<C-w>l", o("Window right"))
map("n", "<leader>wh", "<C-w>h", o("Window left"))
map("n", "<leader>wj", "<C-w>j", o("Window below"))
map("n", "<leader>wk", "<C-w>k", o("Window above"))
map("n", "<leader>wl", "<C-w>l", o("Window right"))
map("n", "<leader>ww", "<C-w>w", o("Next window"))
map("n", "<leader>wv", "<cmd>vsplit<CR>", o("Split vertically"))
map("n", "<leader>ws", "<cmd>split<CR>", o("Split horizontally"))
map("n", "<leader>wo", "<C-w>o", o("Close other windows"))
map("n", "<leader>wc", "<C-w>c", o("Close window"))
map("n", "<leader>wq", "<cmd>q<CR>", o("Quit window"))
map("n", "<leader>w=", "<C-w>=", o("Balance windows"))
map("n", "<leader>wH", "<cmd>vertical resize -2<CR>", o("Narrower"))
map("n", "<leader>wL", "<cmd>vertical resize +2<CR>", o("Wider"))
map("n", "<leader>wJ", "<cmd>resize -2<CR>", o("Shorter"))
map("n", "<leader>wK", "<cmd>resize +2<CR>", o("Taller"))

-- Buffer ---------------------------------------------------------------
map("n", "<Tab>", "<cmd>bnext<CR>", o("Next buffer"))
map("n", "<S-Tab>", "<cmd>bprevious<CR>", o("Previous buffer"))
map("n", "<leader>bn", "<cmd>bnext<CR>", o("Next buffer"))
map("n", "<leader>bp", "<cmd>bprevious<CR>", o("Previous buffer"))
map("n", "<leader>bk", "<cmd>bdelete!<CR>", o("Kill buffer (force)"))
map("n", "<leader>bd", function()
  if _G.Snacks then
    Snacks.bufdelete() -- closes the buffer without destroying the window layout
  else
    vim.cmd("bdelete")
  end
end, o("Close buffer"))

-- Diagnostics ----------------------------------------------------------
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, o("Next diagnostic"))
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, o("Previous diagnostic"))
map("n", "]e", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true }) end, o("Next error"))
map("n", "[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true }) end, o("Previous error"))
map("n", "<leader>cd", vim.diagnostic.open_float, o("Line diagnostics"))

-- Terminal mode --------------------------------------------------------
map("t", "<Esc><Esc>", [[<C-\><C-n>]], o("Exit terminal mode"))
map("t", "jk", [[<C-\><C-n>]], o("Exit terminal mode"))
map("t", "<C-h>", [[<C-\><C-n><C-w>h]], o("Window left"))
map("t", "<C-j>", [[<C-\><C-n><C-w>j]], o("Window below"))
map("t", "<C-k>", [[<C-\><C-n><C-w>k]], o("Window above"))
map("t", "<C-l>", [[<C-\><C-n><C-w>l]], o("Window right"))
