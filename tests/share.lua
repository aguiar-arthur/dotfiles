local copied
local function copy(lines)
  copied = table.concat(lines, "\n")
end
local function paste()
  return {}
end
vim.g.clipboard =
  { name = "test", copy = { ["+"] = copy, ["*"] = copy }, paste = { ["+"] = paste, ["*"] = paste } }
vim.notify = function() end

local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/.git", "p")
vim.fn.mkdir(root .. "/src", "p")
vim.fn.writefile(
  { "local x = 1", "  if x then", "    return x", "  end", "```" },
  root .. "/src/a.lua"
)
vim.cmd("filetype on")
vim.cmd("edit " .. root .. "/src/a.lua")

local failed = {}
local function case(keys, want)
  copied = nil
  vim.cmd("normal! \27")
  vim.api.nvim_feedkeys(vim.keycode(keys), "x", false)
  require("dotfiles.share").selection()
  vim.api.nvim_feedkeys("", "x", false)
  if copied ~= want then
    failed[#failed + 1] = ("%s\nwanted:\n%s\ngot:\n%s"):format(keys, want, tostring(copied))
  elseif vim.api.nvim_get_mode().mode ~= "n" then
    failed[#failed + 1] = keys .. ": did not return to normal mode"
  end
end

case("2GV3G", "src/a.lua:2:1-3:12\n\n```lua\n  if x then\n    return x\n```\n")
case("2G06lv1G06l", "src/a.lua:1:7-2:7\n\n```lua\nx = 1\n  if x \n```\n")
case("4G04l<C-v>2G02l", "src/a.lua:2:3-4:5\n\n```lua\nif \n  r\nend\n```\n")
case("2G02l<C-v>3G08l4G", "src/a.lua:2:3-4:9\n\n```lua\nif x th\n  retur\nend\n```\n")
case("2G02l<C-v>4G$", "src/a.lua:2:3-4:12\n\n```lua\nif x then\n  return x\nend\n```\n")
case("4GV5G", "src/a.lua:4:1-5:3\n\n````lua\n  end\n```\n````\n")

local share = require("dotfiles.share")
local function same(name, got, want)
  if got ~= want then
    failed[#failed + 1] = ("%s\nwanted:\n%s\ngot:\n%s"):format(name, want, tostring(got))
  end
end
copied = nil
share.file()
same(
  "Space c f shares the whole file",
  copied,
  "src/a.lua:1:1-5:3\n\n````lua\nlocal x = 1\n  if x then\n    return x\n  end\n```\n````\n"
)
share.path()
same("Space c p copies the path from the git root", copied, "src/a.lua")
share.path(true)
same("Space c P copies the full path", copied, vim.api.nvim_buf_get_name(0))

vim.fn.delete(root, "rf")
if #failed > 0 then
  io.stderr:write(table.concat(failed, "\n\n") .. "\n")
  vim.cmd("cquit 1")
end
