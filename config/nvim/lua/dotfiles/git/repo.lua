local M = {}

function M.run(...)
  local result = vim.system({ "git", ... }, { text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout) or nil
end

function M.dir()
  local file = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or ""
  local dir = file ~= "" and vim.fs.dirname(file) or ""
  return vim.fn.isdirectory(dir) == 1 and dir or vim.fn.getcwd()
end

function M.base(dir)
  dir = dir or M.dir()
  local base = M.run("-C", dir, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
  for _, name in ipairs({ "origin/main", "origin/master" }) do
    base = base or (M.run("-C", dir, "rev-parse", "--verify", "--quiet", name) and name)
  end
  if not base then
    vim.notify("No origin/HEAD, origin/main or origin/master", vim.log.levels.ERROR)
    return nil
  end
  return base, dir
end

return M
