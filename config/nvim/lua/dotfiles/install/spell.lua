local M = {}

local url = "https://ftp.nluug.nl/pub/vim/runtime/spell/"

function M.files(spelllang, dir)
  local files = {}
  for _, lang in ipairs(spelllang) do
    local short = lang:match("^(%a+)")
    local name = short .. ".utf-8.spl"
    local path = dir .. "/" .. name
    if short ~= "en" and not vim.uv.fs_stat(path) then
      files[#files + 1] = { url = url .. name, path = path }
    end
  end
  return files
end

function M.install(settings, failures, say)
  local dir = vim.fn.stdpath("data") .. "/site/spell"
  vim.fn.mkdir(dir, "p")
  for _, file in ipairs(M.files(settings.spelllang, dir)) do
    local result =
      vim.system({ "curl", "-fsSL", "--max-time", "120", "-o", file.path, file.url }):wait()
    if result.code == 0 then
      say("ok     spell file " .. vim.fs.basename(file.path))
    else
      vim.fn.delete(file.path)
      failures[#failures + 1] = "spell file " .. file.url .. ": " .. vim.trim(result.stderr or "")
    end
  end
end

return M
