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

function M.missing(settings)
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return nil
  end
  local installed = {}
  for _, name in ipairs(registry.get_installed_package_names()) do
    installed[name] = true
  end
  local absent = {}
  for _, name in ipairs(M.wanted(settings)) do
    if not installed[name] then
      absent[#absent + 1] = name
    end
  end
  return absent
end

return M
