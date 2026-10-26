local map = vim.keymap.set
local function o(desc, extra)
  return vim.tbl_extend("force", { silent = true, desc = desc }, extra or {})
end

map("n", "<leader>q", "<cmd>q<CR>", o("Quit"))
map("n", "<leader>s", "<cmd>w<CR>", o("Save"))
map("n", "<Esc>", "<cmd>nohlsearch<CR>", o("Clear search highlight"))
map("n", "<leader>?", "<cmd>WhichKey<CR>", o("Show key bindings"))

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", o("Down", { expr = true }))
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", o("Up", { expr = true }))

map("x", "<", "<gv", o("Indent left (keep selection)"))
map("x", ">", ">gv", o("Indent right (keep selection)"))
map("n", "<A-j>", "<cmd>m .+1<CR>==", o("Move line down"))
map("n", "<A-k>", "<cmd>m .-2<CR>==", o("Move line up"))
map("x", "<A-j>", ":m '>+1<CR>gv=gv", o("Move selection down"))
map("x", "<A-k>", ":m '<-2<CR>gv=gv", o("Move selection up"))
map("i", ",", ",<c-g>u", o("Undo breakpoint"))
map("i", ".", ".<c-g>u", o("Undo breakpoint"))

map("x", "<leader>cs", function()
  require("dotfiles.share").selection()
end, o("Share selection (path and code block)"))
map("n", "<leader>cs", "V<leader>cs", { remap = true, desc = "Share line (path and code block)" })

for _, lhs in ipairs({ "grn", "grr", "gra", "gri", "grt", "grx" }) do
  for _, mode in ipairs({ "n", "x" }) do
    pcall(vim.keymap.del, mode, lhs)
  end
end

map("n", "<C-h>", "<C-w>h", o("Window left"))
map("n", "<C-j>", "<C-w>j", o("Window below"))
map("n", "<C-k>", "<C-w>k", o("Window above"))
map("n", "<C-l>", "<C-w>l", o("Window right"))

map("n", "<leader>bd", function()
  require("dotfiles.git").close_buffer()
end, o("Close buffer"))

local function diagnostic_jump(count, severity)
  return function()
    vim.diagnostic.jump({ count = count, severity = severity })
  end
end
local error_only = vim.diagnostic.severity.ERROR
map("n", "]d", diagnostic_jump(1), o("Next diagnostic"))
map("n", "[d", diagnostic_jump(-1), o("Previous diagnostic"))
map("n", "]e", diagnostic_jump(1, error_only), o("Next error"))
map("n", "[e", diagnostic_jump(-1, error_only), o("Previous error"))
