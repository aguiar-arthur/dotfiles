local M = {}

local SECRETS = {
  "^%.env",
  "%.pem$",
  "%.key$",
  "%.p12$",
  "%.pfx$",
  "^id_[%w_]+$",
  "^%.netrc$",
  "^%.npmrc$",
  "^%.pypirc$",
  "credentials",
  "secret",
}

local START_TIMEOUT_MS = 15000
local POLL_MS = 200

local paused = false

function M.in_last_session(command)
  local terminal = require("claudecode.terminal")
  if not terminal.get_active_terminal_bufnr() then
    terminal.toggle_open_no_focus({}, "--continue")
  end
  vim.cmd(command)
end

function M.secret(name)
  local base = vim.fs.basename(name or ""):lower()
  for _, pattern in ipairs(SECRETS) do
    if base:find(pattern) then
      return true
    end
  end
  return false
end

function M.guard(buf)
  local selection = require("claudecode.selection")
  if M.secret(vim.api.nvim_buf_get_name(buf)) then
    if selection.state.tracking_enabled then
      selection.disable()
      paused = true
    end
  elseif paused then
    paused = false
    local claudecode = require("claudecode")
    if claudecode.state.server then
      selection.enable(claudecode.state.server, claudecode.state.config.visual_demotion_delay_ms)
    end
  end
end

local function away(buf)
  local ok, terminal = pcall(require, "claudecode.terminal")
  return ok
    and terminal.get_active_terminal_bufnr() == buf
    and vim.api.nvim_get_current_buf() ~= buf
end

function M.hide_for_session()
  local buf = require("claudecode.terminal").get_active_terminal_bufnr()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if
      buf
      and vim.api.nvim_win_get_buf(win) == buf
      and vim.api.nvim_win_get_config(win).relative == ""
    then
      pcall(vim.api.nvim_win_hide, win)
    end
  end
end

function M.send(prompt)
  local terminal = require("claudecode.terminal")
  local claudecode = require("claudecode")
  local function deliver()
    terminal.send_to_terminal(prompt, { submit = true })
    vim.cmd("ClaudeCodeFocus")
  end
  if terminal.get_active_terminal_bufnr() and claudecode.is_claude_connected() then
    return deliver()
  end
  if not terminal.get_active_terminal_bufnr() then
    terminal.toggle_open_no_focus({})
  end
  local timer, waited = assert(vim.uv.new_timer()), 0
  timer:start(
    POLL_MS,
    POLL_MS,
    vim.schedule_wrap(function()
      waited = waited + POLL_MS
      local connected = claudecode.is_claude_connected()
      if not connected and waited < START_TIMEOUT_MS then
        return
      end
      timer:stop()
      timer:close()
      if not connected then
        vim.notify("Claude did not start; nothing was sent", vim.log.levels.WARN)
        return
      end
      vim.defer_fn(deliver, claudecode.state.config.connection_wait_delay or 0)
    end)
  )
end

function M.mention()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" or vim.bo.buftype ~= "" then
    return nil
  end
  local first, last = vim.fn.line("."), vim.fn.line(".")
  if vim.fn.mode():find("^[vV\22]") then
    first, last = math.min(vim.fn.line("v"), last), math.max(vim.fn.line("v"), last)
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
  end
  local path = vim.fn.fnamemodify(name, ":.")
  return first == last and ("@%s#L%d"):format(path, first)
    or ("@%s#L%d-%d"):format(path, first, last)
end

function M.refuse(name)
  if not M.secret(name) then
    return false
  end
  vim.notify(
    ("Not sent to Claude: %s looks like a file of secrets"):format(vim.fs.basename(name)),
    vim.log.levels.WARN
  )
  return true
end

function M.ask()
  if M.refuse(vim.api.nvim_buf_get_name(0)) then
    return
  end
  local mention = M.mention()
  vim.ui.input({ prompt = "Ask Claude: " }, function(question)
    if question and vim.trim(question) ~= "" then
      M.send(mention and mention .. " " .. question or question)
    end
  end)
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
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      M.guard(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "PersistenceSavePre",
    callback = M.hide_for_session,
  })
  M.guard(vim.api.nvim_get_current_buf())
end

return M
