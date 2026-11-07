local M = {}

function M.path(dir)
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  dir = dir or vim.fn.expand("%:p:h")
  for _, name in ipairs({ ".venv", "venv" }) do
    local venv = vim.fs.find(name, { path = dir, upward = true, type = "directory" })[1]
    if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
      return venv .. "/bin/python"
    end
  end
  local found = vim.fn.exepath("python3")
  return found ~= "" and found or "python3"
end

return M
