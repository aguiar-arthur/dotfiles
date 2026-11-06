local review = require("dotfiles.git.review")

local M = {}

local function file_win(win)
  return vim.api.nvim_win_get_config(win).relative == ""
    and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end

function M.edit_win(review_tab)
  local before = vim.api.nvim_list_tabpages()[vim.api.nvim_tabpage_get_number(review_tab) - 1]
  if before and not review.is(before) then
    local focused = vim.api.nvim_tabpage_get_win(before)
    local found = file_win(focused) and focused
      or vim.iter(vim.api.nvim_tabpage_list_wins(before)):find(file_win)
    if found then
      return found
    end
  end
  local from = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_tabpage(review_tab)
  vim.cmd("-tabnew")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(from)
  return win
end

local function same_file(win, item)
  if not (item and win and vim.api.nvim_win_is_valid(win)) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if item.buf == buf then
    return true
  end
  local path = Snacks.picker.util.path(item)
  local function real(name)
    return vim.uv.fs_realpath(name) or vim.fs.normalize(name)
  end
  return path ~= nil and real(vim.api.nvim_buf_get_name(buf)) == real(path)
end

function M.pick_win(picker, item)
  local tab = vim.api.nvim_get_current_tabpage()
  if not review.is(tab) or same_file(picker.main, item) then
    return nil
  end
  local win = M.edit_win(tab)
  picker.main = win
  if not picker.shown then
    vim.api.nvim_set_current_win(win)
  end
  return win
end

return M
