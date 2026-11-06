local repo = require("dotfiles.git.repo")
local review = require("dotfiles.git.review")

local M = {}

local TIMEOUT_MS = 15000
local REVIEW_PROMPT = "Review the attached diff: bugs first, with file and line. Change nothing."
local MESSAGE_PROMPT =
  "Write a commit message for the staged changes. Show it to me, do not commit."

local function changes()
  if review.is() then
    return review.diff()
  end
  return { "git", "diff", "HEAD" }
end

local function write(text)
  local dir = vim.fn.stdpath("cache") .. "/claude"
  vim.fn.mkdir(dir, "p")
  local path = dir .. "/changes.diff"
  vim.fn.writefile(vim.split(text, "\n", { plain = true }), path)
  return path
end

local function with_changes(callback)
  local command = changes()
  if not command then
    vim.notify("This review has no single diff to send", vim.log.levels.WARN)
    return
  end
  local options = { text = true, cwd = repo.dir(), timeout = TIMEOUT_MS }
  vim.system(
    command,
    options,
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify(
          "Could not read the changes: " .. vim.trim(result.stderr or ""),
          vim.log.levels.ERROR
        )
      elseif vim.trim(result.stdout or "") == "" then
        vim.notify("No changes to send", vim.log.levels.WARN)
      else
        callback(write(result.stdout))
      end
    end)
  )
end

local function type_prompt(text)
  local buf = require("claudecode.terminal").get_active_terminal_bufnr()
  if not buf then
    vim.notify("Start Claude first (Space a c)", vim.log.levels.WARN)
    return false
  end
  vim.fn.chansend(vim.b[buf].terminal_job_id, text)
  vim.cmd("ClaudeCodeFocus")
  return true
end

function M.send()
  with_changes(function(path)
    vim.cmd("ClaudeCodeAdd " .. vim.fn.fnameescape(path))
  end)
end

function M.ask_review()
  with_changes(function(path)
    if type_prompt(REVIEW_PROMPT) then
      vim.cmd("ClaudeCodeAdd " .. vim.fn.fnameescape(path))
    end
  end)
end

function M.ask_message()
  if repo.run("-C", repo.dir(), "diff", "--cached", "--name-only") == "" then
    vim.notify("Nothing is staged", vim.log.levels.WARN)
    return
  end
  type_prompt(MESSAGE_PROMPT)
end

return M
