local config = vim.fn.stdpath("config")
local failed = {}
for _, dir in ipairs({ "config", "dotfiles" }) do
  for _, file in ipairs(vim.fn.globpath(config .. "/lua/" .. dir, "*.lua", false, true)) do
    local name = dir .. "." .. vim.fn.fnamemodify(file, ":t:r")
    local ok, err = pcall(require, name)
    if not ok then
      failed[#failed + 1] = name .. ": " .. tostring(err):gsub("\n.*", "")
    end
  end
end
for _, file in ipairs(vim.fn.globpath(config .. "/lua/plugins", "*.lua", false, true)) do
  local ok, err = pcall(dofile, file)
  if not ok then
    failed[#failed + 1] = file .. ": " .. tostring(err):gsub("\n.*", "")
  end
end
if #failed > 0 then
  io.stderr:write(table.concat(failed, "\n") .. "\n")
  vim.cmd("cquit 1")
end
