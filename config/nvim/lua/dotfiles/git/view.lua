local repo = require("dotfiles.git.repo")
local session = require("dotfiles.git.session")

local M = {}

local ignoring = false

function M.toggle_whitespace()
  ignoring = not ignoring
  require("codediff").setup({ diff = { ignore_trim_whitespace = ignoring } })
  vim.notify(
    (ignoring and "Ignoring" or "Showing") .. " whitespace changes from the next file you open",
    vim.log.levels.INFO
  )
end

function M.browse()
  local side = session.side(vim.api.nvim_get_current_buf())
  local commit = side and side.revision and side.revision:match("^%x+$")
  if not (commit and side.path and side.path ~= "") then
    return Snacks.gitbrowse()
  end
  local remote = repo.run("-C", side.root, "remote", "get-url", "origin")
  if not remote then
    vim.notify("This repository has no origin", vim.log.levels.WARN)
    return
  end
  local first, last = vim.fn.line("."), vim.fn.line(".")
  if vim.fn.mode():find("[vV]") then
    first, last = math.min(vim.fn.line("v"), last), math.max(vim.fn.line("v"), last)
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
  end
  local gitbrowse = require("snacks.gitbrowse")
  vim.ui.open(gitbrowse.get_url(gitbrowse.get_repo(remote), {
    commit = commit,
    file = side.path,
    line_start = first,
    line_end = last,
    line_count = last - first + 1,
  }, { what = "permalink" }))
end

return M
