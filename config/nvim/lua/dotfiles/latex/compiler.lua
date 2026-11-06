local M = {}

function M.state()
  local ok, state = pcall(
    vim.api.nvim_eval,
    "exists('b:vimtex.compiler') ? (b:vimtex.compiler.is_running() ? 'running' : 'idle') : ''"
  )
  return ok and state or ""
end

return M
