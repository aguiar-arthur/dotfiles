local tabs = require("dotfiles.tabs")

local M = {}

local MODE_LABELS = { explorer = "working tree", standalone = "file", history = "history" }

local expected
local expected_pr
local expected_history

M.is = tabs.review
M.all = tabs.reviews
M.any = tabs.any_review

function M.expect(label, pr)
  expected = label
  expected_pr = pr
  expected_history = vim.fn.histnr("cmd")
end

function M.mark(tab, mode)
  if vim.fn.histnr("cmd") ~= expected_history then
    M.expect(nil)
  end
  local typed = vim.fn.histget("cmd", -1):match("CodeDiff%s+(.+)$")
  vim.api.nvim_tabpage_set_var(tab, "review", true)
  vim.api.nvim_tabpage_set_var(tab, "review_label", expected or typed or MODE_LABELS[mode] or "")
  local typed_pr = not expected and typed and tonumber(typed:match("^pr%s+(%d+)"))
  local pr = expected_pr or typed_pr and { number = typed_pr }
  if pr then
    vim.api.nvim_tabpage_set_var(tab, "review_pr", pr)
  end
  M.expect(nil)
end

function M.unmark(tab)
  pcall(vim.api.nvim_tabpage_del_var, tab, "review")
  pcall(vim.api.nvim_tabpage_del_var, tab, "review_pr")
  M.expect(nil)
end

function M.label(tab)
  local ok, label = pcall(vim.api.nvim_tabpage_get_var, tab, "review_label")
  return ok and label or ""
end

function M.pr(tab)
  local ok, pr = pcall(vim.api.nvim_tabpage_get_var, tab, "review_pr")
  return ok and pr or nil
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
