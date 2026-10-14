local M = {}

local function git(...)
  local result = vim.system({ "git", ... }, { text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout) or nil
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
