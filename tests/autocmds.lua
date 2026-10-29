local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local root = T.dir({
  ["a.txt"] = { "one", "two", "three", "four", "five" },
  ["b.txt"] = { "before" },
})

T.case("yank highlight", function()
  vim.cmd("edit " .. root .. "/a.txt")
  vim.api.nvim_feedkeys("yy", "tx", false)
  local ns = vim.api.nvim_get_namespaces()["nvim.hlyank"]
  T.eq(
    "a yank is highlighted",
    ns ~= nil and #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) > 0,
    true
  )
end)

T.case("last line", function()
  vim.cmd("edit " .. root .. "/a.txt")
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  vim.cmd("edit " .. root .. "/b.txt")
  local a = vim.fn.bufnr(root .. "/a.txt")
  vim.cmd("bunload " .. a)
  vim.cmd("edit " .. root .. "/a.txt")
  T.eq("reopening a file goes back to the last line", vim.api.nvim_win_get_cursor(0)[1], 4)
end)

T.case("q closes help", function()
  vim.cmd("help")
  local help = vim.api.nvim_get_current_win()
  T.eq("help is left out of the buffer list", vim.bo.buflisted, false)
  vim.fn.maparg("q", "n", false, true).callback()
  T.eq("q closes the help window", vim.api.nvim_win_is_valid(help), false)
end)

T.case("new folders", function()
  local deep = root .. "/new/deep/c.txt"
  vim.cmd("edit " .. deep)
  vim.cmd("silent write")
  T.eq("writing creates missing folders", vim.uv.fs_stat(deep) ~= nil, true)
end)

T.case("resize", function()
  vim.cmd("vsplit")
  vim.cmd("vertical resize 10")
  vim.cmd("tabnew")
  vim.api.nvim_exec_autocmds("VimResized", {})
  T.eq("resizing stays on the current tab", vim.fn.tabpagenr(), 2)
  vim.cmd("tabprevious")
  local widths = vim.tbl_map(vim.api.nvim_win_get_width, vim.api.nvim_tabpage_list_wins(0))
  T.eq("resizing evens out the windows of every tab", math.abs(widths[1] - widths[2]) <= 1, true)
end)

T.case("cursorline and winbar", function()
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
  vim.cmd("split | terminal")
  T.eq("a terminal split from a file window has no winbar", vim.wo.winbar, "")
  vim.cmd("bwipeout!")
  vim.cmd("terminal")
  T.eq("a terminal opened in a file window drops its winbar", vim.wo.winbar, "")
  vim.cmd("bwipeout!")
end)

T.case("welcome screen", function()
  local opened = 0
  T.stub(Snacks, "dashboard", function()
    opened = opened + 1
    vim.bo.filetype = "snacks_dashboard"
  end)
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
end)

local changed_on_disk = false
T.case("focus reload, the change on disk", function()
  vim.cmd("tabonly | only | edit " .. root .. "/b.txt")
  vim.fn.writefile({ "after" }, root .. "/b.txt")
  local later = os.time() + 10
  vim.uv.fs_utime(root .. "/b.txt", later, later)
  vim.api.nvim_exec_autocmds("FocusGained", {})
  changed_on_disk = true
end)

T.case("TeX live mode", function()
  local settings = require("config.settings")
  T.stub(settings, "latex_live", false)
  local tex = root .. "/live.tex"
  vim.fn.writefile({ "\\documentclass{article}" }, tex)
  vim.cmd("edit " .. tex)
  local calls = { compile = 0, view = 0 }
  vim.api.nvim_buf_create_user_command(0, "VimtexCompile", function()
    calls.compile = calls.compile + 1
  end, {})
  vim.api.nvim_buf_create_user_command(0, "VimtexView", function()
    calls.view = calls.view + 1
  end, {})
  vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventInitPost" })
  vim.api.nvim_buf_set_lines(0, 1, 1, false, { "text" })
  vim.api.nvim_exec_autocmds("CursorHold", {})
  T.eq(
    "TeX: live mode off neither compiles nor saves",
    { calls.compile, vim.bo.modified },
    { 0, true }
  )
  settings.latex_live = true
  vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventInitPost" })
  T.eq("TeX: opening a file starts the build", calls.compile, 1)
  vim.api.nvim_exec_autocmds("CursorHold", {})
  T.eq("TeX: idle saves the file", { vim.bo.modified, vim.fn.readfile(tex)[2] }, { false, "text" })
  vim.api.nvim_buf_set_lines(0, 1, 1, false, { "mine" })
  vim.fn.writefile({ "\\documentclass{article}", "theirs" }, tex)
  local later_tex = os.time() + 20
  vim.uv.fs_utime(tex, later_tex, later_tex)
  vim.api.nvim_exec_autocmds("CursorHold", {})
  T.eq("TeX: idle never overwrites a file changed on disk", vim.fn.readfile(tex)[2], "theirs")
  vim.cmd("edit! " .. tex)
  vim.fn.writefile({ "\\documentclass{article}", "external" }, tex)
  local later_ext = os.time() + 40
  vim.uv.fs_utime(tex, later_ext, later_ext)
  vim.api.nvim_exec_autocmds("CursorHold", {})
  vim.wait(200)
  T.eq("TeX: idle reloads an untouched buffer changed on disk", vim.fn.getline(2), "external")
  vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventCompileSuccess" })
  T.eq("TeX: a build before any view leaves the viewer alone", calls.view, 0)
  vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventView" })
  vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventCompileSuccess" })
  T.eq("TeX: a build after a view syncs it", calls.view, 1)
  T.eq("TeX: an idle compiler is reported idle", require("dotfiles.vimtex").compiler(), "idle")
  vim.cmd("unlet b:vimtex.compiler")
  T.eq("TeX: no compiler is reported as none", require("dotfiles.vimtex").compiler(), "")
  local started = calls.compile
  vim.v.errmsg = ""
  pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "VimtexEventInitPost" })
  T.eq(
    "TeX: a buffer without a vimtex compiler opens quietly",
    { vim.v.errmsg, calls.compile },
    { "", started }
  )
end)

vim.cmd("edit " .. root .. "/b.txt")
vim.defer_fn(function()
  T.case("focus reload", function()
    if changed_on_disk then
      T.eq("focus reloads a file changed on disk", vim.fn.getline(1), "after")
    end
  end)
  T.done()
end, 100)
