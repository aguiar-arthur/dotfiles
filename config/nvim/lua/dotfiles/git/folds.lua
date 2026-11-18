local session = require("dotfiles.git.session")

local M = {}

local function partner(win)
  local tab = vim.api.nvim_win_get_tabpage(win)
  local original, modified = session.windows(tab)
  local other = win == original and modified or win == modified and original or nil
  if not (other and vim.api.nvim_win_is_valid(other)) then
    return nil
  end
  local from = win == original and "original" or "modified"
  local to = from == "original" and "modified" or "original"
  local line = session.line(tab, from, to, vim.api.nvim_win_get_cursor(win)[1])
  return other,
    math.max(1, math.min(line, vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(other))))
end

function M.follow(win)
  local open = vim.api.nvim_win_call(win, function()
    return vim.fn.foldclosed(".") == -1
  end)
  local other, target = partner(win)
  if not (open and other) then
    return
  end
  vim.api.nvim_win_call(other, function()
    if vim.fn.foldclosed(target) ~= -1 then
      -- why: the cursor must sit in the opened fold, or Neovim scrolls the partner to keep it in view
      vim.api.nvim_win_set_cursor(other, { target, 0 })
      vim.cmd("normal! zv")
    end
  end)
end

function M.align(win, scrolled)
  local other, target = partner(win)
  local moved = other and scrolled[tostring(other)]
  local own = scrolled[tostring(win)]
  if not moved or moved.topline == 0 or (own and own.topline ~= 0) then
    return
  end
  vim.api.nvim_win_set_cursor(other, { target, 0 })
  vim.cmd("syncbind")
end

return M
