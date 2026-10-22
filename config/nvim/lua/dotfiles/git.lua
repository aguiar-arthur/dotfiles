local M = {}

local function git(...)
  local result = vim.system({ "git", ... }, { text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout) or nil
end

function M.review(tab)
  local lifecycle = package.loaded["codediff.ui.lifecycle"]
  return lifecycle and lifecycle.get_session(tab or vim.api.nvim_get_current_tabpage()) ~= nil
end

function M.mark_jump(review_tab)
  vim.t.review_tab = review_tab
end

function M.jumps(review_tab)
  return vim.tbl_filter(function(tab)
    local ok, value = pcall(vim.api.nvim_tabpage_get_var, tab, "review_tab")
    return ok and value == review_tab
  end, vim.api.nvim_list_tabpages())
end

function M.jump_win(review_tab)
  local tab = M.jumps(review_tab)[1]
  local from = vim.api.nvim_get_current_win()
  if tab then
    vim.api.nvim_set_current_tabpage(tab)
    local here, review = vim.fn.tabpagenr(), vim.api.nvim_tabpage_get_number(review_tab)
    vim.cmd.tabmove(here < review and review - 2 or review - 1)
  else
    vim.api.nvim_set_current_tabpage(review_tab)
    vim.cmd("-tabnew")
    vim.bo.bufhidden = "wipe"
    M.mark_jump(review_tab)
  end
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(from)
  return win
end

function M.close_jumps(review_tab)
  for _, tab in ipairs(M.jumps(review_tab)) do
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
    end
  end
end

function M.back_to_review()
  local tab = vim.api.nvim_get_current_tabpage()
  if M.review(tab) then
    require("codediff.ui.lifecycle").close(tab)
    return
  end
  local review_tab = vim.t.review_tab
  if not review_tab then
    vim.notify("This tab was not opened from a review", vim.log.levels.WARN)
    return
  end
  vim.cmd.tabclose()
  if vim.api.nvim_tabpage_is_valid(review_tab) then
    vim.api.nvim_set_current_tabpage(review_tab)
  end
end

function M.close_buffer()
  local buf = vim.api.nvim_get_current_buf()
  local review_tab = M.review() and vim.api.nvim_get_current_tabpage() or vim.t.review_tab
  local shown = review_tab
    and vim.api.nvim_tabpage_is_valid(review_tab)
    and vim.iter(vim.api.nvim_tabpage_list_wins(review_tab)):any(function(win)
      return vim.api.nvim_win_get_buf(win) == buf
    end)
  if shown then
    M.back_to_review()
  else
    Snacks.bufdelete()
  end
end

function M.setup()
  local panes = require("codediff.ui.view.actions.panes")
  local open_in_prev_tab = panes.open_in_prev_tab
  panes.open_in_prev_tab = function(ctx)
    local win = M.jump_win(ctx.tabpage)
    open_in_prev_tab(ctx)
    require("dotfiles.toggles").apply(win)
  end
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("user_review", { clear = true }),
    pattern = "CodeDiffClose",
    callback = function(ev)
      vim.schedule(function()
        M.close_jumps(ev.data.tabpage)
      end)
    end,
  })
end

function M.review_vs_origin()
  local base = git("symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
  for _, name in ipairs({ "origin/main", "origin/master" }) do
    base = base or (git("rev-parse", "--verify", "--quiet", name) and name)
  end
  if not base then
    vim.notify("No origin/HEAD, origin/main or origin/master", vim.log.levels.ERROR)
    return
  end
  vim.cmd.CodeDiff(base .. "...")
end

return M
