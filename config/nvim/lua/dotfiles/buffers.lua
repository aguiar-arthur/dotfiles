local tabs = require("dotfiles.tabs")

local M = {}

local function shows(tab, buf)
  return vim.iter(vim.api.nvim_tabpage_list_wins(tab)):any(function(win)
    return vim.api.nvim_win_get_buf(win) == buf
  end)
end

function M.close_buffer()
  local buf = vim.api.nvim_get_current_buf()
  if tabs.review() then
    tabs.close(vim.api.nvim_get_current_tabpage())
  elseif vim.iter(tabs.reviews()):any(function(tab)
    return shows(tab, buf)
  end) then
    vim.notify("A review shows this file: close the review first (Space g q)", vim.log.levels.WARN)
  else
    Snacks.bufdelete()
  end
end

function M.close_buffers(which)
  if tabs.any_review() then
    vim.notify("A review is open: close it first (Space g q)", vim.log.levels.WARN)
  else
    Snacks.bufdelete[which]()
  end
end

return M
