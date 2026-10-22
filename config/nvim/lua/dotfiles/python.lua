local M = {}

function M.path()
  local venv =
    vim.fs.find(".venv", { path = vim.fn.expand("%:p:h"), upward = true, type = "directory" })[1]
  if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
    return venv .. "/bin/python"
  end
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  local found = vim.fn.exepath("python3")
  return found ~= "" and found or "python3"
end

return M
