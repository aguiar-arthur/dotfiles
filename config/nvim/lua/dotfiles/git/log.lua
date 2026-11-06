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

function M.line_commit()
  local file = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or ""
  if file == "" then
    vim.notify("This window shows no file", vim.log.levels.WARN)
    return
  end
  local line = vim.fn.line(".")
  local dir = vim.fs.dirname(file)
  local args = { "git", "-C", dir, "blame", "-L", line .. "," .. line, "--porcelain" }
  vim.list_extend(args, { "--contents", "-", "--", file })
  local stdin = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local result = vim.system(args, { text = true, stdin = stdin }):wait()
  local commit = result.code == 0 and result.stdout:match("^(%x+)")
  if not commit then
    vim.notify("Git does not track this file", vim.log.levels.WARN)
  elseif commit:match("^0+$") then
    vim.notify("This line is not committed yet", vim.log.levels.WARN)
  else
    against_parent(commit, dir)
  end
end

function M.stash(picker, item)
  picker:close()
  if item and item.stash then
    review.expect(item.stash)
    vim.cmd.CodeDiff(item.stash .. "^", item.stash)
  end
end

return M
