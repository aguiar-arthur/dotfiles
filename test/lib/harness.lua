local M = {}

local lines = {}
local failed = 0

function M.check(name, passed, detail)
  if passed then
    lines[#lines + 1] = "ok " .. name
  else
    failed = failed + 1
    lines[#lines + 1] = "FAIL " .. name
    if detail then
      for _, row in ipairs(vim.split(tostring(detail), "\n", { plain = true })) do
        lines[#lines + 1] = "  " .. row
      end
    end
  end
end

function M.run(name, fn)
  local passed, err = pcall(fn)
  M.check(name, passed, err)
end

function M.ready()
  vim.wait(4000, function()
    return false
  end)
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  vim.wait(2000, function()
    return false
  end)
end

function M.messages()
  return vim.api.nvim_exec2("messages", { output = true }).output
end

function M.finish()
  vim.fn.writefile(lines, vim.env.TEST_OUT)
  vim.cmd(failed == 0 and "qa!" or "cquit 1")
end

return M
