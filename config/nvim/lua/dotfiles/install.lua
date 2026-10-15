local M = {}

local function say(text)
  io.stdout:write(text .. "\n")
end

local function install_tools(settings, failures)
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  local registry = require("mason-registry")
  local refreshed = false
  registry.refresh(function()
    refreshed = true
  end)
  if not vim.wait(60000, function()
    return refreshed
  end, 200) then
    failures[#failures + 1] = "the Mason registry did not answer within a minute (network?)"
    return
  end

  if #registry.get_all_package_names() == 0 then
    failures[#failures + 1] = "the Mason registry is empty: it could not be downloaded (network?)"
    return
  end

  local mason = require("dotfiles.mason")
  local wanted = mason.wanted(settings)
  local pending, problems = 0, {}
  for _, name in ipairs(wanted) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok then
      problems[#problems + 1] = name .. " is not in the Mason registry"
    elseif not pkg:is_installed() and not pkg:is_installing() then
      pending = pending + 1
      say("...    installing " .. name)
      pkg:install({}, function(success, result)
        pending = pending - 1
        if not success then
          problems[#problems + 1] = name .. ": " .. tostring(result)
        end
      end)
    end
  end

  local function busy()
    if pending > 0 then
      return true
    end
    for _, name in ipairs(wanted) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and pkg:is_installing() then
        return true
      end
    end
    return false
  end
  if not vim.wait(900000, function()
    return not busy()
  end, 500) then
    problems[#problems + 1] = "Mason installs did not finish within 15 minutes"
  end

  local missing = mason.missing(settings) or {}
  if #missing > 0 then
    problems[#problems + 1] = "not installed: " .. table.concat(missing, ", ")
  end
  if #problems > 0 then
    for _, problem in ipairs(problems) do
      failures[#failures + 1] = "Mason: " .. problem
    end
  else
    say(("ok     %d Mason servers and tools"):format(#wanted))
  end
end

local function install_parsers(settings, failures)
  if vim.fn.executable("tree-sitter") ~= 1 then
    failures[#failures + 1] = "tree-sitter CLI is missing (brew bundle), parsers not installed"
    return
  end
  local ts = require("nvim-treesitter")
  local ok, err = pcall(function()
    ts.install(settings.parsers):wait(900000)
  end)
  if not ok then
    failures[#failures + 1] = "treesitter: " .. tostring(err)
    return
  end
  local missing = require("dotfiles.treesitter").missing(settings.parsers)
  if #missing > 0 then
    failures[#failures + 1] = "parsers not installed: " .. table.concat(missing, ", ")
  else
    say(("ok     %d treesitter parsers"):format(#settings.parsers))
  end
end

local spell_url = "https://ftp.nluug.nl/pub/vim/runtime/spell/"

function M.spell_files(spelllang, dir)
  local files = {}
  for _, lang in ipairs(spelllang) do
    local short = lang:match("^(%a+)")
    local name = short .. ".utf-8.spl"
    local path = dir .. "/" .. name
    if short ~= "en" and not vim.uv.fs_stat(path) then
      files[#files + 1] = { url = spell_url .. name, path = path }
    end
  end
  return files
end

local function install_spell(settings, failures)
  local dir = vim.fn.stdpath("data") .. "/site/spell"
  vim.fn.mkdir(dir, "p")
  for _, file in ipairs(M.spell_files(settings.spelllang, dir)) do
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

function M.run()
  local settings = require("config.settings")
  local failures = {}
  install_tools(settings, failures)
  install_parsers(settings, failures)
  install_spell(settings, failures)
  for _, failure in ipairs(failures) do
    say("ERROR  " .. failure)
  end
  vim.cmd(#failures == 0 and "qa!" or "cquit 1")
end

return M
