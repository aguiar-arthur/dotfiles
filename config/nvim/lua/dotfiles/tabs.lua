local M = {}

function M.review(tab)
  local ok, value = pcall(vim.api.nvim_tabpage_get_var, tab or 0, "review")
  return ok and value == true
end

function M.reviews()
  return vim.tbl_filter(M.review, vim.api.nvim_list_tabpages())
end

function M.any_review()
  return #M.reviews() > 0
end

function M.close(tab)
  if #vim.api.nvim_list_tabpages() == 1 then
    vim.cmd("tabnew")
  end
  vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
end

return M
