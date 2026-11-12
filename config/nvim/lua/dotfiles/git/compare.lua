local repo = require("dotfiles.git.repo")
local review = require("dotfiles.git.review")

local M = {}

local NETWORK_TIMEOUT_MS = 15000

local marks_base

local function revision(item)
  return item and (item.branch or item.commit)
end

function M.not_current(item)
  if item.current then
    return false
  end
end

function M.branch(picker, item)
  picker:close()
  local rev = revision(item)
  if rev then
    review.expect(rev .. "...")
    vim.cmd.CodeDiff(rev .. "...")
  end
end

function M.file(picker, item)
  picker:close()
  local rev = revision(item)
  if rev then
    review.expect("this file vs " .. rev)
    vim.cmd.CodeDiff("file", rev)
  end
end

function M.refresh_base(base, dir)
  local remote, branch = base:match("^([^/]+)/(.+)$")
  local before = remote and repo.run("-C", dir, "merge-base", base, "HEAD")
  if not before then
    return
  end
  vim.system(
    { "git", "-C", dir, "fetch", "--quiet", "--no-tags", remote, branch },
    { text = true, timeout = NETWORK_TIMEOUT_MS },
    vim.schedule_wrap(function(result)
      local after = result.code == 0 and repo.run("-C", dir, "merge-base", base, "HEAD")
      if after and after ~= before then
        vim.notify(
          ("%s moved: this branch now forks from %s, not %s; Space g V again reviews against it"):format(
            base,
            after:sub(1, 7),
            before:sub(1, 7)
          ),
          vim.log.levels.WARN
        )
      end
    end)
  )
end

function M.origin()
  local base, dir = repo.base()
  if base then
    review.expect(base .. "...")
    vim.cmd.CodeDiff(base .. "...")
    M.refresh_base(base, dir)
  end
end

function M.commits()
  local base = repo.base()
  if base then
    review.expect(base .. "..HEAD, by commit")
    vim.cmd.CodeDiff("history", base .. "..HEAD")
  end
end

function M.toggle_marks()
  local gitsigns = require("gitsigns")
  if marks_base then
    marks_base = nil
    gitsigns.reset_base(true)
    vim.notify("Git marks: against the index")
    return
  end
  local base, dir = repo.base()
  local fork = base and repo.run("-C", dir, "merge-base", base, "HEAD")
  if fork then
    marks_base = base
    gitsigns.change_base(fork, true)
    vim.notify("Git marks: against " .. base)
  end
end

return M
