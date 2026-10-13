local M = {}

local last

M.commands = {
  python = function()
    return { require("dotfiles.python").path() }
  end,
  lua = { "nvim", "-l" },
  sh = { "bash" },
}

function M.run(cmd, cwd)
  if last and last.buf and vim.api.nvim_buf_is_valid(last.buf) then
    pcall(last.close, last)
  end
  local origin = vim.api.nvim_get_current_win()
  last = Snacks.terminal.open(cmd, {
    cwd = cwd,
    interactive = false,
    win = { position = "bottom", height = 12 },
  })
  if vim.api.nvim_win_is_valid(origin) then
    vim.api.nvim_set_current_win(origin)
  end
  return last
end

function M.run_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Save the file first", vim.log.levels.WARN)
    return
  end
  vim.cmd("silent update")
  local cmd = M.commands[vim.bo.filetype]
  cmd = type(cmd) == "function" and cmd() or vim.deepcopy(cmd)
  table.insert(cmd, file)
  M.run(cmd, vim.fs.dirname(file))
end

return M
