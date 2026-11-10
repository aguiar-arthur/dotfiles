local repo = require("dotfiles.git.repo")
local review = require("dotfiles.git.review")

local M = {}

local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

local function short(commit)
  return commit:sub(1, 7)
end

local function against_parent(commit, dir)
  local parent = repo.run("-C", dir, "rev-parse", "--verify", "--quiet", commit .. "^")
  review.expect(short(commit))
  vim.cmd.CodeDiff(parent or EMPTY_TREE, commit)
end

function M.commit(picker, item)
  local chosen = picker:selected()
  picker:close()
  if #chosen == 2 then
    table.sort(chosen, function(a, b)
      return a.idx > b.idx
    end)
    review.expect(short(chosen[1].commit) .. ".." .. short(chosen[2].commit))
    vim.cmd.CodeDiff(chosen[1].commit, chosen[2].commit)
  elseif item and item.commit then
    against_parent(item.commit, item.cwd or vim.fn.getcwd())
  end
end

function M.worktree(picker, item)
  picker:close()
  if item and item.commit then
    review.expect(short(item.commit) .. " vs working tree")
    vim.cmd.CodeDiff(item.commit)
  end
end

return M
