local h = dofile(vim.env.TEST_ROOT .. "/test/lib/harness.lua")

local function press(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
  vim.wait(300, function()
    return false
  end)
end

local function pause(ms)
  vim.wait(ms, function()
    return false
  end)
end

h.ready()

h.run("<leader>uw wraps every window, including windows opened later", function()
  vim.cmd("silent! only")
  vim.cmd("edit " .. vim.fn.fnameescape(vim.env.TEST_FILE))
  vim.cmd("split")
  assert(vim.wo.wrap, "wrap should be on by default")
  press("<Space>uw")
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    assert(not vim.wo[win].wrap, "window " .. win .. " still wraps")
  end
  vim.cmd("new")
  assert(not vim.wo.wrap, "a new window did not follow the toggle")
  vim.cmd("silent! only")
  press("<Space>uw")
  assert(vim.wo.wrap, "toggling again should wrap")
end)

h.run("the grn/grr/gra/gri/grt/grx defaults are removed", function()
  for _, lhs in ipairs({ "grn", "grr", "gra", "gri", "grt", "grx" }) do
    assert(vim.fn.maparg(lhs, "n") == "", lhs .. " is still mapped")
  end
end)

h.run("Markdown is formatted by rumdl", function()
  local formatters = require("conform").formatters_by_ft.markdown
  assert(vim.deep_equal(formatters, { "rumdl" }), vim.inspect(formatters))
end)

h.run("a diff view opens and closes with <leader>gv", function()
  vim.cmd("silent! only")
  vim.cmd("cd " .. vim.fn.fnameescape(vim.fn.fnamemodify(vim.env.TEST_FILE, ":h")))
  vim.cmd("edit " .. vim.fn.fnameescape(vim.env.TEST_FILE))
  press("<Space>gv")
  pause(3000)
  assert(next(require("diffview.lib").views), "no diff view was created")
  press("<Space>gv")
  pause(500)
  assert(not next(require("diffview.lib").views), "the diff view did not close")
end)

h.run("buffers of old revisions never get a language server", function()
  vim.cmd("silent! only")
  vim.cmd("edit " .. vim.fn.fnameescape(vim.env.TEST_FILE))
  press("<Space>gv")
  pause(3000)
  local seen = 0
  local bad = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("^diffview://") then
      seen = seen + 1
      if vim.bo[buf].buftype == "" then
        bad[#bad + 1] = name .. " has an empty buftype"
      end
      if #vim.lsp.get_clients({ bufnr = buf }) > 0 then
        bad[#bad + 1] = name .. " has a language server attached"
      end
    end
  end
  assert(seen > 0, "no diffview:// buffers found")
  assert(#bad == 0, table.concat(bad, "\n"))
end)

h.run("the review panel has the same keys as the Emacs one", function()
  local panel
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match("panels") then
      panel = buf
    end
  end
  assert(panel, "file panel buffer not found")
  local function bound(lhs)
    return vim.api.nvim_buf_call(panel, function()
      return vim.fn.maparg(lhs, "n") ~= ""
    end)
  end
  for _, lhs in ipairs({ "<Tab>", "<S-Tab>", "-", "q", "<CR>" }) do
    assert(bound(lhs), lhs .. " is not mapped in the file panel")
  end
  press("<Space>gv")
end)

local function child(local_source, expression)
  local path = vim.fn.stdpath("config") .. "/lua/config/local.lua"
  local out = vim.fn.tempname()
  local previous = vim.uv.fs_stat(path) and vim.fn.readfile(path) or nil
  vim.fn.writefile(vim.split(local_source, "\n"), path)
  vim.fn.system({
    "nvim",
    "--headless",
    "--cmd",
    "let g:loaded_spellfile_plugin=1",
    "-c",
    ("lua vim.fn.writefile({vim.json.encode(%s)}, %q)"):format(expression, out),
    "-c",
    "qa!",
  })
  if previous then
    vim.fn.writefile(previous, path)
  else
    vim.fn.delete(path)
  end
  local lines = vim.fn.readfile(out)
  assert(#lines > 0, "the child Neovim wrote nothing")
  return vim.json.decode(lines[1])
end

h.run("lua/config/local.lua overrides the settings", function()
  local result = child(
    "return { wrap = false, languages = { tex = false } }",
    "{ wrap = vim.o.wrap, servers = require('config.settings').mason_servers }"
  )
  assert(result.wrap == false, "wrap was not overridden")
  assert(not vim.tbl_contains(result.servers, "texlab"), "texlab still installed with tex off")
  assert(vim.tbl_contains(result.servers, "lua_ls"), "other languages were lost")
end)

h.run("a broken local.lua is reported and the defaults stay", function()
  local result =
    child("return {", "{ wrap = vim.o.wrap, err = require('config.settings').local_error ~= nil }")
  assert(result.wrap == true, "defaults were not kept")
  assert(result.err == true, "the error was not recorded")
end)

h.run(":checkhealth dotfiles runs every section", function()
  vim.cmd("checkhealth dotfiles")
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(not text:find("Failed to run healthcheck", 1, true), text)
  for _, section in ipairs({
    "Neovim ~",
    "Settings ~",
    "Programs ~",
    "Plugins ~",
    "Mason ~",
    "Extras ~",
  }) do
    assert(text:find(section, 1, true), "missing section " .. section)
  end
  vim.cmd("bwipeout!")
end)

h.finish()
