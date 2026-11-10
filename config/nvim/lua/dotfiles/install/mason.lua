local M = {}

function M.wanted(settings)
  local mapping = {}
  local ok, mlsp = pcall(require, "mason-lspconfig")
  if ok and mlsp.get_mappings then
    mapping = mlsp.get_mappings().lspconfig_to_package or {}
  end
  local wanted = vim.deepcopy(settings.mason_tools)
  for _, server in ipairs(settings.mason_servers) do
    wanted[#wanted + 1] = mapping[server] or server
  end
  return wanted
end

function M.broken(root)
  root = root or vim.fn.stdpath("data") .. "/mason/packages"
  local found = {}
  for name, kind in vim.fs.dir(root) do
    local venv = root .. "/" .. name .. "/venv"
    if
      kind == "directory"
      and vim.uv.fs_stat(venv)
      and vim.fn.executable(venv .. "/bin/python") == 0
    then
      found[name] = true
    end
  end
  return found
end

function M.missing(settings, root)
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return nil
  end
  local installed = {}
  for _, name in ipairs(registry.get_installed_package_names()) do
    installed[name] = true
  end
  local broken = M.broken(root)
  local absent = {}
  for _, name in ipairs(M.wanted(settings)) do
    if not installed[name] or broken[name] then
      absent[#absent + 1] = name
    end
  end
  return absent
end

function M.install(settings, failures, say)
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

  local wanted = M.wanted(settings)
  local absent = {}
  for _, name in ipairs(M.missing(settings) or {}) do
    absent[name] = true
  end
  local pending, problems = 0, {}
  for _, name in ipairs(wanted) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok then
      problems[#problems + 1] = name .. " is not in the Mason registry"
    elseif absent[name] and not pkg:is_installing() then
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

  local missing = M.missing(settings) or {}
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

return M
