local T = dofile(vim.env.DOT .. "/tests/lib.lua")

T.case("startup loads only what must be there at once", function()
  local loaded = {}
  for _, plugin in ipairs(require("lazy").plugins()) do
    if plugin._.loaded then
      loaded[#loaded + 1] = plugin.name
    end
  end
  table.sort(loaded)
  T.eq(
    "startup: a new plugin waits for its event, key, command or file type",
    loaded,
    { "dracula.nvim", "lazy.nvim", "nvim-treesitter", "snacks.nvim", "vimtex" }
  )
end)

T.case("ui2 is still in this Neovim", function()
  local found = {}
  for _, module in ipairs({ "vim._core.ui2", "vim._core.ui2.cmdline", "vim._core.ui2.messages" }) do
    found[#found + 1] = pcall(require, module)
  end
  T.eq(
    "ui2: the modules options.lua turns on are there (else delete its line, see docs/core.md)",
    { found, type(require("vim._core.ui2").enable) },
    { { true, true, true }, "function" }
  )
end)

T.case("the dashboard's q", function()
  local function qmap(buf)
    return vim.api.nvim_buf_call(buf, function()
      return vim.fn.maparg("q", "n", false, true).rhs
    end)
  end
  local dash = vim.api.nvim_create_buf(false, true)
  vim.bo[dash].filetype = "snacks_dashboard"
  local dash_win = vim.api.nvim_open_win(
    dash,
    false,
    { relative = "editor", row = 1, col = 1, width = 20, height = 5 }
  )
  vim.keymap.set("n", "q", "<cmd>qa<CR>", { buffer = dash })
  vim.api.nvim_exec_autocmds("User", { pattern = "SnacksDashboardUpdatePost" })
  T.eq("dashboard: q closes a floating dashboard instead of quitting", qmap(dash), "<cmd>bd<CR>")
  vim.api.nvim_win_close(dash_win, true)
  local main = vim.api.nvim_create_buf(false, true)
  vim.bo[main].filetype = "snacks_dashboard"
  vim.api.nvim_set_current_buf(main)
  vim.keymap.set("n", "q", "<cmd>qa<CR>", { buffer = main })
  vim.api.nvim_exec_autocmds("User", { pattern = "SnacksDashboardUpdatePost" })
  T.eq("dashboard: q still quits the start dashboard", qmap(main), "<cmd>qa<CR>")
end)

T.case("ui2", function()
  local module = "vim._core.ui2"
  local warning
  T.stub(package.loaded, module, nil)
  T.stub(package.preload, module, function()
    error("module '" .. module .. "' not found")
  end)
  T.stub(vim, "notify", function(msg, level)
    warning = { msg:match("^[^:]*"), level }
  end)
  vim.o.grepprg = ""
  local ok = pcall(T.config, "config/options.lua")
  vim.wait(1000, function()
    return warning ~= nil
  end)
  T.eq(
    "ui2: a Neovim without it still runs the rest of options.lua, and says so",
    { ok, vim.o.grepprg, warning },
    {
      true,
      "rg --vimgrep --smart-case",
      { "ui2 is off, delete its line in options.lua", vim.log.levels.WARN },
    }
  )
end)

T.case("folds are for file windows", function()
  local dir = T.dir({ ["f.lua"] = { "local function f()", "  return 1", "end" } })
  vim.cmd("edit " .. dir .. "/f.lua")
  vim.treesitter.get_parser(0):parse()
  T.eq("a file folds by its syntax", vim.fn.foldlevel(2) > 0, true)
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].filetype = "lua"
  vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { "local function f()", "  return 1", "end" })
  vim.api.nvim_set_current_buf(scratch)
  T.eq("a scratch window does not, it would leave a stale entry behind", vim.fn.foldlevel(2), 0)
  vim.cmd("enew")
end)

T.done()
