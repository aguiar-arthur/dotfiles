local repo = require("dotfiles.git.repo")
local review = require("dotfiles.git.review")

local M = {}

local NETWORK_TIMEOUT_MS = 15000

function M.review(picker, item)
  picker:close()
  if item and item.number then
    review.expect("PR #" .. item.number)
    vim.cmd.CodeDiff("pr", tostring(item.number))
  end
end

function M.menu(picker, item)
  if item then
    picker:close()
    Snacks.picker.gh_actions({ item = item })
  end
end

function M.hunks(picker, item)
  if item then
    picker:close()
    Snacks.picker.gh_diff({ pr = item.number, repo = item.repo })
  end
end

local function with_gh(callback)
  if vim.fn.executable("gh") == 1 then
    callback()
  else
    vim.notify("gh is not installed", vim.log.levels.ERROR)
  end
end

function M.comments()
  with_gh(function()
    local dir = repo.dir()
    local command = { "gh", "pr", "view", "--json", "number" }
    local options = { text = true, cwd = dir, timeout = NETWORK_TIMEOUT_MS }
    vim.system(
      command,
      options,
      vim.schedule_wrap(function(result)
        local ok, data = pcall(vim.json.decode, result.stdout or "")
        if result.code == 0 and ok and data.number then
          Snacks.picker.gh_diff({ pr = data.number, cwd = dir })
        else
          vim.notify("This branch has no pull request", vim.log.levels.WARN)
        end
      end)
    )
  end)
end

function M.checks()
  with_gh(function()
    local command = { "gh", "pr", "checks", "--watch" }
    Snacks.terminal(command, { cwd = repo.dir(), interactive = false })
  end)
end

return M
