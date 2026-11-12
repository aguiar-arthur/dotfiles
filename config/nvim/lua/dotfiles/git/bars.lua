local review = require("dotfiles.git.review")
local session = require("dotfiles.git.session")

local M = {}

M.bar = "%{%v:lua.require'dotfiles.git.bars'.render()%}"
M.foldtext = "v:lua.require'dotfiles.git.bars'.fold()"

local SCOPES = { "function", "method", "class", "struct", "impl", "interface", "module" }

function M.fold()
  local lines = vim.v.foldend - vim.v.foldstart + 1
  return {
    { ("  ··· %d unchanged line%s ···"):format(lines, lines == 1 and "" or "s"), "Comment" },
  }
end

local function scoped(node)
  local kind = node:type()
  for _, scope in ipairs(SCOPES) do
    if kind:find(scope, 1, true) then
      return true
    end
  end
  return false
end

function M.scope(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not (ok and parser) then
    return nil
  end
  pcall(parser.parse, parser)
  local row = vim.api.nvim_win_get_cursor(win)[1] - 1
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local found, node = pcall(vim.treesitter.get_node, {
    bufnr = buf,
    pos = { row, math.max(0, (line:find("%S") or 1) - 1) },
  })
  node = found and node or nil
  while node do
    local name = scoped(node) and node:field("name")[1]
    if name then
      return (vim.treesitter.get_node_text(name, buf):gsub("%s+", " "))
    end
    node = node:parent()
  end
  return nil
end

local function describe(side, buf)
  if not side.path or side.path == "" then
    return "no file"
  end
  local rev = side.revision
  if not rev then
    return vim.bo[buf].buftype == "" and "working tree" or "?"
  end
  if rev == ":0" then
    return "staged"
  end
  return (rev:gsub("%x%x%x%x%x%x%x+", function(commit)
    return commit:sub(1, 7)
  end))
end

local function hunk(tab, win, which)
  local changes = session.hunks(tab)
  if #changes == 0 then
    return nil
  end
  local line, at = vim.api.nvim_win_get_cursor(win)[1], 0
  for i, change in ipairs(changes) do
    if change[which] and change[which].start_line <= line then
      at = i
    end
  end
  return (at > 0 and at or "-") .. "/" .. #changes
end

function M.render()
  -- why: inside %{} Neovim makes the window being drawn the current one; g:statusline_winid is unset
  local win = vim.api.nvim_get_current_win()
  local tab = vim.api.nvim_win_get_tabpage(win)
  local original, modified = session.windows(tab)
  local which = win == original and "original" or win == modified and "modified" or nil
  if not which then
    return ""
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local side = session.side(buf, tab) or {}
  local text = describe(side, buf)
  local base = which == "original" and review.label(tab):match("^(.-)%.%.%.$")
  if base and side.revision then
    text = "fork point of " .. base .. " @ " .. text
  end
  local scope = M.scope(win)
  if scope then
    text = text .. " · " .. scope
  end
  local at = hunk(tab, win, which)
  return (" %%#Comment#%s%%* %s%s"):format(
    which == "original" and "old" or "new",
    text:gsub("%%", "%%%%"),
    at and "  %#Comment#hunk " .. at .. "%*" or ""
  )
end

function M.set(tab)
  for _, win in ipairs({ session.windows(tab) }) do
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winbar = M.bar
      vim.wo[win].foldtext = M.foldtext
    end
  end
end

return M
