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

return M
