local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local root = T.dir({
  ["a.txt"] = { "one", "two", "three", "four", "five" },
  ["b.txt"] = { "before" },
})

vim.cmd("edit " .. root .. "/a.txt")
vim.api.nvim_feedkeys("yy", "tx", false)
local ns = vim.api.nvim_get_namespaces()["nvim.hlyank"]
T.eq(
  "a yank is highlighted",
  ns ~= nil and #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) > 0,
  true
)

vim.api.nvim_win_set_cursor(0, { 4, 0 })
vim.cmd("edit " .. root .. "/b.txt")
local a = vim.fn.bufnr(root .. "/a.txt")
vim.cmd("bunload " .. a)
vim.cmd("edit " .. root .. "/a.txt")
T.eq("reopening a file goes back to the last line", vim.api.nvim_win_get_cursor(0)[1], 4)

vim.cmd("help")
local help = vim.api.nvim_get_current_win()
T.eq("help is left out of the buffer list", vim.bo.buflisted, false)
vim.fn.maparg("q", "n", false, true).callback()
T.eq("q closes the help window", vim.api.nvim_win_is_valid(help), false)

local deep = root .. "/new/deep/c.txt"
vim.cmd("edit " .. deep)
vim.cmd("silent write")
T.eq("writing creates missing folders", vim.uv.fs_stat(deep) ~= nil, true)

vim.cmd("vsplit")
vim.cmd("vertical resize 10")
vim.cmd("tabnew")
vim.api.nvim_exec_autocmds("VimResized", {})
T.eq("resizing stays on the current tab", vim.fn.tabpagenr(), 2)
vim.cmd("tabprevious")
local widths = vim.tbl_map(vim.api.nvim_win_get_width, vim.api.nvim_tabpage_list_wins(0))
T.eq("resizing evens out the windows of every tab", math.abs(widths[1] - widths[2]) <= 1, true)

vim.cmd("tabonly | only | edit " .. root .. "/b.txt")
vim.fn.writefile({ "after" }, root .. "/b.txt")
local later = os.time() + 10
vim.uv.fs_utime(root .. "/b.txt", later, later)
vim.api.nvim_exec_autocmds("FocusGained", {})
vim.defer_fn(function()
  T.eq("focus reloads a file changed on disk", vim.fn.getline(1), "after")
  T.done()
end, 100)
