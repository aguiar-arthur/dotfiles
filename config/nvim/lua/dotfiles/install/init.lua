local M = {}

local steps = { "mason", "parsers", "spell" }

local function say(text)
  io.stdout:write(text .. "\n")
end

function M.run()
  local settings = require("config.settings")
  local failures = {}
  for _, step in ipairs(steps) do
    local ok, err = pcall(function()
      require("dotfiles.install." .. step).install(settings, failures, say)
    end)
    if not ok then
      failures[#failures + 1] = step .. ": " .. tostring(err)
    end
  end
  for _, failure in ipairs(failures) do
    say("ERROR  " .. failure)
  end
  vim.cmd(#failures == 0 and "qa!" or "cquit 1")
end

return M
