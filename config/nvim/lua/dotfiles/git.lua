local M = {}

local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

local function git(...)
  local result = vim.system({ "git", ... }, { text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout) or nil
end

function M.review(tab)
  local ok, value = pcall(vim.api.nvim_tabpage_get_var, tab or 0, "review")
  return ok and value == true
end

local function shows(tab, buf)
  return vim.iter(vim.api.nvim_tabpage_list_wins(tab)):any(function(win)
    return vim.api.nvim_win_get_buf(win) == buf
  end)
end

function M.edit_win(review_tab)
  local before = vim.api.nvim_list_tabpages()[vim.api.nvim_tabpage_get_number(review_tab) - 1]
  local found = before
    and not M.review(before)
    and vim.iter(vim.api.nvim_tabpage_list_wins(before)):find(function(win)
      return vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
    end)
  if found then
    return found
  end
  local from = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_tabpage(review_tab)
  vim.cmd("-tabnew")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(from)
  return win
end

function M.close_review()
  local here = vim.fn.tabpagenr()
  local reviews = vim.tbl_filter(M.review, vim.api.nvim_list_tabpages())
  local tab = vim.iter(reviews):find(function(t)
    return vim.api.nvim_tabpage_get_number(t) >= here
  end) or reviews[#reviews]
  if not tab then
    vim.notify("No review is open", vim.log.levels.WARN)
    return
  end
  if #vim.api.nvim_list_tabpages() == 1 then
    vim.cmd("tabnew")
  end
  vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
end

function M.close_reviews()
  for _, tab in ipairs(vim.tbl_filter(M.review, vim.api.nvim_list_tabpages())) do
    if #vim.api.nvim_list_tabpages() == 1 then
      vim.cmd("tabnew")
    end
    vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
  end
end

function M.close_buffer()
  local buf = vim.api.nvim_get_current_buf()
  if M.review() then
    M.close_review()
  elseif
    vim.iter(vim.api.nvim_list_tabpages()):any(function(tab)
      return M.review(tab) and shows(tab, buf)
    end)
  then
    vim.notify("A review shows this file: close the review first (Space g q)", vim.log.levels.WARN)
  else
    Snacks.bufdelete()
  end
end

function M.close_buffers(which)
  if vim.iter(vim.api.nvim_list_tabpages()):any(M.review) then
    vim.notify("A review is open: close it first (Space g q)", vim.log.levels.WARN)
  else
    Snacks.bufdelete[which]()
  end
end

function M.review_commit(picker, item)
  picker:close()
  if item and item.commit then
    local dir = item.cwd or vim.fn.getcwd()
    local parent = git("-C", dir, "rev-parse", "--verify", "--quiet", item.commit .. "^")
    vim.cmd.CodeDiff(parent or EMPTY_TREE, item.commit)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_review", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = function(ev)
      vim.api.nvim_tabpage_set_var(ev.data.tabpage, "review", true)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffClose",
    callback = function(ev)
      pcall(vim.api.nvim_tabpage_del_var, ev.data.tabpage, "review")
    end,
  })
end

function M.review_vs_origin()
  local file = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or ""
  local dir = file ~= "" and vim.fs.dirname(file) or ""
  dir = vim.fn.isdirectory(dir) == 1 and dir or vim.fn.getcwd()
  local base = git("-C", dir, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
  for _, name in ipairs({ "origin/main", "origin/master" }) do
    base = base or (git("-C", dir, "rev-parse", "--verify", "--quiet", name) and name)
  end
  if not base then
    vim.notify("No origin/HEAD, origin/main or origin/master", vim.log.levels.ERROR)
    return
  end
  vim.cmd.CodeDiff(base .. "...")
end

return M
