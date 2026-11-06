local M = {}

local MODE_LABELS = { explorer = "working tree", standalone = "file", history = "history" }

local expected

function M.is(tab)
  local ok, value = pcall(vim.api.nvim_tabpage_get_var, tab or 0, "review")
  return ok and value == true
end

function M.all()
  return vim.tbl_filter(M.is, vim.api.nvim_list_tabpages())
end

function M.any()
  return #M.all() > 0
end

function M.expect(label)
  expected = label
end

function M.mark(tab, mode)
  local typed = vim.fn.histget("cmd", -1):match("CodeDiff%s+(.+)$")
  vim.api.nvim_tabpage_set_var(tab, "review", true)
  vim.api.nvim_tabpage_set_var(tab, "review_label", expected or typed or MODE_LABELS[mode] or "")
  expected = nil
end

function M.unmark(tab)
  pcall(vim.api.nvim_tabpage_del_var, tab, "review")
  expected = nil
end

function M.label(tab)
  local ok, label = pcall(vim.api.nvim_tabpage_get_var, tab, "review_label")
  return ok and label or ""
end

local function close_tab(tab)
  if #vim.api.nvim_list_tabpages() == 1 then
    vim.cmd("tabnew")
  end
  vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
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
  close_tab(tab)
end

function M.close_all()
  vim.iter(M.all()):each(close_tab)
end

function M.close_others(tab)
  if not (vim.api.nvim_tabpage_is_valid(tab) and M.is(tab)) then
    return
  end
  for _, other in ipairs(M.all()) do
    if other ~= tab then
      close_tab(other)
    end
  end
end

return M
