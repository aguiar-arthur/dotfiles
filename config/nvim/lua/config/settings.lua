local defaults = {
  colorscheme = "dracula",
  wrap = true,
  format_on_save = true,
  spelllang = { "en_us", "pt_br" },
  languages = {
    lua = true,
    python = true,
    shell = true,
    tex = true,
    json = true,
    yaml = true,
    toml = true,
    markdown = true,
    web = true,
    c = true,
    clojure = true,
  },
}

local catalog = {
  lua = { servers = { "lua_ls" }, tools = { "stylua" } },
  python = { servers = { "basedpyright", "ruff" } },
  shell = { servers = { "bashls" }, tools = { "shfmt", "shellcheck" } },
  tex = { servers = { "texlab" }, executables = { "latexmk" } },
  json = { servers = { "jsonls" }, tools = { "prettier" } },
  yaml = { servers = { "yamlls" }, tools = { "prettier" } },
  toml = { servers = { "taplo" } },
  markdown = { servers = { "rumdl" } },
  web = { servers = { "html", "cssls", "vtsls" }, tools = { "prettier" } },
  c = { servers = { "clangd" } },
  clojure = { system = { clojure_lsp = "clojure-lsp" }, executables = { "clojure-lsp" } },
}

local M = vim.deepcopy(defaults)

local path = vim.fn.stdpath("config") .. "/lua/config/local.lua"
local found = vim.uv.fs_stat(path) and path or nil
M.local_file = found
if found then
  local ok, overrides = pcall(dofile, found)
  if not ok then
    M.local_error = overrides
    vim.schedule(function()
      vim.notify("lua/config/local.lua failed: " .. tostring(overrides), vim.log.levels.ERROR)
    end)
  elseif type(overrides) == "table" then
    M = vim.tbl_deep_extend("force", M, overrides)
    M.local_file = found
  end
end

local function collect(field)
  local seen, list = {}, {}
  for name, enabled in pairs(M.languages) do
    local entry = catalog[name]
    if enabled and entry and entry[field] then
      for key, value in pairs(entry[field]) do
        local item = type(key) == "number" and value or key
        if not seen[item] then
          seen[item] = true
          list[#list + 1] = item
        end
      end
    end
  end
  table.sort(list)
  return list
end

M.mason_servers = collect("servers")
M.mason_tools = collect("tools")
M.executables = collect("executables")

M.system_servers = {}
for name, enabled in pairs(M.languages) do
  local entry = catalog[name]
  if enabled and entry and entry.system then
    for server, bin in pairs(entry.system) do
      M.system_servers[server] = bin
    end
  end
end

return M
