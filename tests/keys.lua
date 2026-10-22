local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local root = T.dir({
  ["a.lua"] = { "local a = 1", "local b = 2", "local c = 3", "local d = 4", "local e = 5" },
  ["a.tex"] = { "\\documentclass{article}" },
  ["a.md"] = {
    "# Title",
    "",
    "Math $x^2$.",
    "",
    "| a | b |",
    "|---|---|",
    "| 1 | 2 |",
    "",
    "<kbd>Ctrl</kbd>",
  },
  [".rumdl.toml"] = {},
})

vim.cmd("edit " .. root .. "/a.lua")
local ns = vim.api.nvim_create_namespace("test")
vim.diagnostic.set(ns, 0, {
  { lnum = 1, col = 0, message = "warning", severity = vim.diagnostic.severity.WARN },
  { lnum = 3, col = 0, message = "error", severity = vim.diagnostic.severity.ERROR },
})
local function jump(lhs)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.fn.maparg(lhs, "n", false, true).callback()
  return vim.api.nvim_win_get_cursor(0)[1]
end
T.eq("]d goes to the next diagnostic", jump("]d"), 2)
T.eq("]e skips warnings and goes to the error", jump("]e"), 4)

local copied
local function copy(lines)
  copied = table.concat(lines, "\n")
end
vim.g.clipboard = {
  name = "test",
  copy = { ["+"] = copy, ["*"] = copy },
  paste = {
    ["+"] = function()
      return {}
    end,
    ["*"] = function()
      return {}
    end,
  },
}
local notify = vim.notify
vim.notify = function() end
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.api.nvim_feedkeys(vim.keycode("<leader>cs"), "mx", false)
vim.notify = notify
local want = "a.lua:2:1-2:11\n\n```lua\nlocal b = 2\n```\n"
T.eq("Space c s in normal mode shares the line", copied and copied:sub(-#want), want)
T.eq("Space c s returns to normal mode", vim.api.nvim_get_mode().mode, "n")

vim.cmd("edit " .. root .. "/a.tex")
T.eq("TeX: ,lw counts words", vim.fn.maparg(",lw", "n", false, true).desc, "Count words")
T.eq("TeX: lines are not hard-wrapped", vim.bo.textwidth, 0)

vim.cmd("edit " .. root .. "/a.md")
T.eq(
  "Markdown: ,p is the preview",
  vim.fn.maparg(",p", "n", false, true).desc,
  "Markdown preview (browser)"
)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.api.nvim_feedkeys("i`", "tx", false)
T.eq("Markdown: a backtick gets its pair", vim.fn.getline(2), "``")
vim.cmd("silent undo")

if vim.fn.executable("pandoc") == 1 then
  local opened
  vim.ui.open = function(path)
    opened = path
  end
  vim.fn.maparg(",p", "n", false, true).callback()
  vim.wait(15000, function()
    return opened ~= nil
  end)
  local html = opened and table.concat(vim.fn.readfile(opened), "\n") or ""
  T.eq(",p opens an HTML page with MathML", html:find("<math", 1, true) ~= nil, true)
  T.eq(",p keeps tables", html:find("<table", 1, true) ~= nil, true)
  T.eq(",p renders the HTML in the Markdown", html:find("<kbd>Ctrl</kbd>", 1, true) ~= nil, true)
  local before = opened and vim.uv.fs_stat(opened).mtime
  vim.cmd("silent write")
  vim.wait(15000, function()
    local now = vim.uv.fs_stat(opened).mtime
    return now.sec ~= before.sec or now.nsec ~= before.nsec
  end)
  local after = opened and vim.uv.fs_stat(opened).mtime
  T.eq(
    "saving rebuilds the preview",
    after and (after.sec ~= before.sec or after.nsec ~= before.nsec),
    true
  )
end

if vim.fn.executable("rumdl") == 1 then
  vim.wait(15000, function()
    return #vim.lsp.get_clients({ bufnr = 0, name = "rumdl" }) > 0 and vim.bo.formatexpr == ""
  end)
  T.eq("rumdl attaches to Markdown", #vim.lsp.get_clients({ bufnr = 0, name = "rumdl" }), 1)
  T.eq("gq keeps wrapping: formatexpr is cleared", vim.bo.formatexpr, "")
  local unknown = {}
  for _, mode in ipairs({ "n", "x" }) do
    local maps =
      vim.list_extend(vim.api.nvim_get_keymap(mode), vim.api.nvim_buf_get_keymap(0, mode))
    for _, m in ipairs(maps) do
      local command = (m.rhs or ""):match("^<[Cc][Mm][Dd]>[%s%.%%']*(%a+)")
      if command and vim.fn.exists(":" .. command) == 0 then
        unknown[#unknown + 1] = m.lhs:gsub(" ", "<Space>") .. " runs :" .. command
      end
    end
  end
  T.eq("every <Cmd> key runs a command that exists (LSP keys included)", unknown, {})
end

vim.cmd("enew")
vim.bo.filetype = "snacks_picker_list"
T.eq(
  "Claude: Space a b in the file tree adds the item under the cursor",
  vim.fn.maparg("<leader>ab", "n", false, true).desc,
  "Add the file under the cursor to Claude"
)
T.eq(
  "Claude: Space a B in the file tree adds it to the last session",
  vim.fn.maparg("<leader>aB", "n", false, true).desc,
  "Add the file under the cursor to the last Claude session"
)

T.done()
