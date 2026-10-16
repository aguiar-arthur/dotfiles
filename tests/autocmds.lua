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

vim.cmd("only | edit " .. root .. "/a.txt")
local first = vim.api.nvim_get_current_win()
vim.cmd("vsplit")
local second = vim.api.nvim_get_current_win()
T.eq("the active window has the cursorline", vim.wo[second].cursorline, true)
T.eq("an inactive window loses the cursorline", vim.wo[first].cursorline, false)
T.eq("a file window shows its path in the winbar", vim.wo[second].winbar, " %f%m")
local float = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
  relative = "editor",
  row = 1,
  col = 1,
  width = 10,
  height = 3,
})
T.eq("a float gets no winbar", vim.wo[float].winbar, "")
vim.api.nvim_win_close(float, true)

local opened = 0
local dashboard = Snacks.dashboard
Snacks.dashboard = function()
  opened = opened + 1
  vim.bo.filetype = "snacks_dashboard"
end
vim.cmd("only | silent! %bwipeout!")
vim.wait(100)
opened = 0
vim.cmd("edit " .. root .. "/a.txt")
vim.cmd("enew")
vim.cmd("bdelete " .. vim.fn.bufnr(root .. "/a.txt"))
vim.wait(200, function()
  return opened > 0
end)
T.eq("closing the last file shows the welcome screen", opened, 1)
vim.cmd("edit " .. root .. "/a.txt")
vim.cmd("enew")
vim.cmd("bdelete")
vim.wait(100)
T.eq("closing a buffer beside another file keeps it", opened, 1)
Snacks.dashboard = dashboard

vim.cmd("tabonly | only | edit " .. root .. "/b.txt")
vim.fn.writefile({ "after" }, root .. "/b.txt")
local later = os.time() + 10
vim.uv.fs_utime(root .. "/b.txt", later, later)
vim.api.nvim_exec_autocmds("FocusGained", {})
vim.defer_fn(function()
  T.eq("focus reloads a file changed on disk", vim.fn.getline(1), "after")
  T.done()
end, 100)
