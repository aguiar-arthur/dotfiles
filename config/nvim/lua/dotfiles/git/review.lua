local tabs = require("dotfiles.tabs")

local M = {}

local MODE_LABELS = { explorer = "working tree", standalone = "file", history = "history" }

local expected
local expected_diff
local expected_history

M.is = tabs.review
M.all = tabs.reviews
M.any = tabs.any_review

function M.expect(label, diff)
  expected = label
  expected_history = vim.fn.histnr("cmd")
  expected_diff = diff
    and vim.tbl_map(function(arg)
      return arg == "%" and vim.fn.expand("%:p") or arg
    end, diff)
end

function M.mark(tab, mode)
  if vim.fn.histnr("cmd") ~= expected_history then
    M.expect(nil)
  end
  local typed = vim.fn.histget("cmd", -1):match("CodeDiff%s+(.+)$")
  vim.api.nvim_tabpage_set_var(tab, "review", true)
  vim.api.nvim_tabpage_set_var(tab, "review_label", expected or typed or MODE_LABELS[mode] or "")
  vim.api.nvim_tabpage_set_var(tab, "review_diff", expected_diff or vim.NIL)
  M.expect(nil)
end

function M.unmark(tab)
  pcall(vim.api.nvim_tabpage_del_var, tab, "review")
  M.expect(nil)
end

function M.label(tab)
  local ok, label = pcall(vim.api.nvim_tabpage_get_var, tab, "review_label")
  return ok and label or ""
end

function M.diff(tab)
  local ok, diff = pcall(vim.api.nvim_tabpage_get_var, tab or 0, "review_diff")
  return ok and diff ~= vim.NIL and diff or nil
end

function M.close()
  local here = vim.fn.tabpagenr()
  local reviews = M.all()
  local tab = vim.iter(reviews):find(function(t)
    return vim.api.nvim_tabpage_get_number(t) >= here
  end) or reviews[#reviews]
  if not tab then
    vim.notify("No review is open", vim.log.levels.WARN)
    return
  end
  tabs.close(tab)
end

function M.close_all()
  vim.iter(M.all()):each(tabs.close)
end

function M.close_others(tab)
  if not (vim.api.nvim_tabpage_is_valid(tab) and M.is(tab)) then
    return
  end
  for _, other in ipairs(M.all()) do
    if other ~= tab then
      tabs.close(other)
    end
  end
end

return M
