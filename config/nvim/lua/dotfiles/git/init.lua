local aligned = require("dotfiles.git.aligned")
local review = require("dotfiles.git.review")

local M = {}

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
      aligned.on()
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
      if not review.any() then
        aligned.off()
      end
    end,
  })
end

return M
