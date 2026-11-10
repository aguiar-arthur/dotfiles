local M = {}

function M.install(settings, failures, say)
  if vim.fn.executable("tree-sitter") ~= 1 then
    failures[#failures + 1] = "tree-sitter CLI is missing (brew bundle), parsers not installed"
    return
  end
  local ts = require("nvim-treesitter")
  local ok, err = pcall(function()
    ts.install(settings.parsers):wait(900000)
  end)
  if not ok then
    failures[#failures + 1] = "treesitter: " .. tostring(err)
    return
  end
  local missing = require("dotfiles.treesitter").missing(settings.parsers)
  if #missing > 0 then
    failures[#failures + 1] = "parsers not installed: " .. table.concat(missing, ", ")
  else
    say(("ok     %d treesitter parsers"):format(#settings.parsers))
  end
end

return M
