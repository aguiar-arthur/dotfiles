local aligned = require("dotfiles.git.aligned")
local review = require("dotfiles.git.review")

local M = {}

local function any_diff_window()
  return vim.iter(vim.api.nvim_list_wins()):any(function(win)
    return vim.wo[win].diff
  end)
end

local function refresh_aligned()
  if review.any() or any_diff_window() then
    aligned.on()
  else
    aligned.off()
  end
end

function M.watch_diff()
  local group = vim.api.nvim_create_augroup("user_native_diff", { clear = true })
  vim.api.nvim_create_autocmd({ "DiffUpdated", "WinClosed" }, {
    group = group,
    callback = vim.schedule_wrap(refresh_aligned),
  })
end

function M.setup()
  require("dotfiles.tabline").set_labeler(function(tab)
    return review.is(tab) and "review: " .. review.label(tab) or nil
  end)
  local group = vim.api.nvim_create_augroup("user_review", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = function(ev)
      local tab = ev.data.tabpage
      review.mark(tab, ev.data.mode)
      refresh_aligned()
      vim.iter(vim.api.nvim_tabpage_list_wins(tab)):each(require("dotfiles.windows").bar)
      vim.schedule(function()
        review.close_others(tab)
      end)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "PersistenceSavePre",
    callback = review.close_all,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffClose",
    callback = function(ev)
      review.unmark(ev.data.tabpage)
      refresh_aligned()
    end,
  })
end

return M
