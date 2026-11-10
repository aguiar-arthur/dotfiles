local aligned = require("dotfiles.git.aligned")
local explorer = require("dotfiles.git.explorer")
local review = require("dotfiles.git.review")

local M = {}

function M.watch_diff()
  local group = vim.api.nvim_create_augroup("user_native_diff", { clear = true })
  vim.api.nvim_create_autocmd({ "DiffUpdated", "WinClosed" }, {
    group = group,
    callback = vim.schedule_wrap(aligned.refresh),
  })
end

function M.setup()
  require("dotfiles.tabline").set_labeler(function(tab)
    if not review.is(tab) then
      return nil
    end
    local progress = explorer.progress()
    return "review: " .. review.label(tab) .. (progress and "  " .. progress or "")
  end)
  local group = vim.api.nvim_create_augroup("user_review", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = function(ev)
      local tab = ev.data.tabpage
      review.mark(tab, ev.data.mode)
      aligned.refresh()
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
    pattern = "CodeDiffFileSelect",
    callback = function(ev)
      explorer.select(ev.data.path)
      vim.cmd.redrawtabline()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffClose",
    callback = function(ev)
      review.unmark(ev.data.tabpage)
      explorer.clear()
      aligned.refresh()
    end,
  })
end

return M
