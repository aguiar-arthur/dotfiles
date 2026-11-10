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

return M
