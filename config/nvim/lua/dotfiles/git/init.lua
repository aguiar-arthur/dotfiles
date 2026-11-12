local aligned = require("dotfiles.git.aligned")
local bars = require("dotfiles.git.bars")
local explorer = require("dotfiles.git.explorer")
local review = require("dotfiles.git.review")
local reviewed = require("dotfiles.git.reviewed")

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
    local summary = explorer.summary(tab)
    return "review: " .. review.label(tab) .. (summary and "  " .. summary or "")
  end)
  explorer.on_complete(function(tab)
    vim.cmd.redrawtabline()
    vim.notify("Review complete: " .. explorer.progress(tab))
    reviewed.mark(tab)
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
      bars.set(tab)
      explorer.restore(tab)
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
      explorer.select(ev.data.tabpage, ev.data.path)
      bars.set(ev.data.tabpage)
      vim.cmd.redrawtabline()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter", "WinEnter", "FileType" }, {
    group = group,
    callback = function()
      local tab = vim.api.nvim_get_current_tabpage()
      if review.is(tab) then
        vim.schedule(function()
          if vim.api.nvim_tabpage_is_valid(tab) then
            bars.set(tab)
          end
        end)
      end
    end,
  })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    callback = function()
      if review.is() then
        vim.cmd("redrawstatus!")
      end
    end,
  })
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    callback = function()
      vim.iter(review.all()):each(require("dotfiles.git.session").redraw)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffClose",
    callback = function(ev)
      review.unmark(ev.data.tabpage)
      explorer.clear(ev.data.tabpage)
      aligned.refresh()
    end,
  })
end

return M
