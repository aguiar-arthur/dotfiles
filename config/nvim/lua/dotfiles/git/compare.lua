local repo = require("dotfiles.git.repo")
local review = require("dotfiles.git.review")

local M = {}

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
    review.expect(rev .. "...", { "git", "diff", rev .. "..." })
    vim.cmd.CodeDiff(rev .. "...")
  end
end

function M.file(picker, item)
  picker:close()
  local rev = revision(item)
  if rev then
    review.expect("this file vs " .. rev, { "git", "diff", rev, "--", "%" })
    vim.cmd.CodeDiff("file", rev)
  end
end

function M.origin()
  local base = repo.base()
  if base then
    review.expect(base .. "...", { "git", "diff", base .. "..." })
    vim.cmd.CodeDiff(base .. "...")
  end
end

function M.commits()
  local base = repo.base()
  if base then
    review.expect(base .. "..HEAD, by commit", { "git", "diff", base .. "..." })
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
