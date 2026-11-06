local review = require("dotfiles.git.review")

local M = {}

local function tiled(win)
  return vim.api.nvim_win_get_config(win).relative == ""
end

local function name(tab)
  if review.is(tab) then
    return "review: " .. review.label(tab)
  end
  local focused = vim.api.nvim_tabpage_get_win(tab)
  local win = tiled(focused) and focused
    or vim.iter(vim.api.nvim_tabpage_list_wins(tab)):find(tiled)
    or focused
  local file = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
  return file ~= "" and vim.fn.fnamemodify(file, ":t") or "[No Name]"
end

function M.render()
  local current = vim.api.nvim_get_current_tabpage()
  local parts = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local label = name(tab):gsub("%%", "%%%%")
    parts[#parts + 1] = ("%%#%s#%%%dT %s "):format(
      tab == current and "TabLineSel" or "TabLine",
      vim.api.nvim_tabpage_get_number(tab),
      label
    )
  end
  return table.concat(parts) .. "%#TabLineFill#%T"
end

return M
