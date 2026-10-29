local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local copied
local function copy(lines)
  copied = table.concat(lines, "\n")
end
local function paste()
  return {}
end
vim.g.clipboard =
  { name = "test", copy = { ["+"] = copy, ["*"] = copy }, paste = { ["+"] = paste, ["*"] = paste } }

local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/.git", "p")
vim.fn.mkdir(root .. "/src", "p")
vim.fn.writefile(
  { "local x = 1", "  if x then", "    return x", "  end", "```" },
  root .. "/src/a.lua"
)
vim.cmd("filetype on")
vim.cmd("edit " .. root .. "/src/a.lua")

local share = require("dotfiles.share")
local function selection(keys)
  copied = nil
  vim.cmd("normal! \27")
  vim.api.nvim_feedkeys(vim.keycode(keys), "x", false)
  share.selection()
  vim.api.nvim_feedkeys("", "x", false)
  return { copied, vim.api.nvim_get_mode().mode }
end

T.case("Space c s on a selection", function()
  T.stub(vim, "notify", function() end)
  for _, case in ipairs({
    { "2GV3G", "src/a.lua:2:1-3:12\n\n```lua\n  if x then\n    return x\n```\n" },
    { "2G06lv1G06l", "src/a.lua:1:7-2:7\n\n```lua\nx = 1\n  if x \n```\n" },
    { "4G04l<C-v>2G02l", "src/a.lua:2:3-4:5\n\n```lua\nif \n  r\nend\n```\n" },
    { "2G02l<C-v>3G08l4G", "src/a.lua:2:3-4:9\n\n```lua\nif x th\n  retur\nend\n```\n" },
    { "2G02l<C-v>4G$", "src/a.lua:2:3-4:12\n\n```lua\nif x then\n  return x\nend\n```\n" },
    { "4GV5G", "src/a.lua:4:1-5:3\n\n````lua\n  end\n```\n````\n" },
  }) do
    T.eq(
      "Space c s after " .. case[1] .. " shares it and returns to normal mode",
      selection(case[1]),
      { case[2], "n" }
    )
  end
  T.eq("Space c s leaves virtualedit as it was", vim.o.virtualedit, "block")
end)

T.case("Space c s when the region cannot be read", function()
  T.stub(vim, "notify", function() end)
  T.stub(vim.fn, "getregion", function()
    error("boom")
  end)
  vim.cmd("normal! \27")
  vim.api.nvim_feedkeys(vim.keycode("1GV2G"), "x", false)
  local ok = pcall(share.selection)
  vim.api.nvim_feedkeys("", "x", false)
  T.eq(
    "Space c s fails loudly, restores virtualedit and leaves Visual mode",
    { ok, vim.o.virtualedit, vim.api.nvim_get_mode().mode },
    { false, "block", "n" }
  )
end)

T.case("Space c f, Space c p and Space c P", function()
  T.stub(vim, "notify", function() end)
  copied = nil
  share.file()
  T.eq(
    "Space c f shares the whole file",
    copied,
    "src/a.lua:1:1-5:3\n\n````lua\nlocal x = 1\n  if x then\n    return x\n  end\n```\n````\n"
  )
  share.path()
  T.eq("Space c p copies the path from the git root", copied, "src/a.lua")
  share.path(true)
  T.eq("Space c P copies the full path", copied, vim.api.nvim_buf_get_name(0))
end)

vim.fn.delete(root, "rf")
T.done()
