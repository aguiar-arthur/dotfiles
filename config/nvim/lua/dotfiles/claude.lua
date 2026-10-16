local M = {}

function M.in_last_session(command)
  local terminal = require("claudecode.terminal")
  if not terminal.get_active_terminal_bufnr() then
    terminal.toggle_open_no_focus({}, "--continue")
  end
  vim.cmd(command)
end

local function away(buf)
  local ok, terminal = pcall(require, "claudecode.terminal")
  return ok
    and terminal.get_active_terminal_bufnr() == buf
    and vim.api.nvim_get_current_buf() ~= buf
end

function M.watch()
  local group = vim.api.nvim_create_augroup("user_claude_watch", { clear = true })
  vim.api.nvim_create_autocmd("TermRequest", {
    group = group,
    callback = function(ev)
      local message = tostring(ev.data.sequence):match("^\27%]9;(.*)")
      if message and not message:match("^4;") and away(ev.buf) then
        vim.notify(message, vim.log.levels.INFO, { title = "Claude" })
      end
    end,
  })
  vim.api.nvim_create_autocmd("TermClose", {
    group = group,
    callback = function(ev)
      if away(ev.buf) then
        vim.notify("Claude exited", vim.log.levels.WARN, { title = "Claude" })
      end
    end,
  })
end

return M
