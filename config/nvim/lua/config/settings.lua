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

local core_parsers = { "diff", "query", "regex", "vim", "vimdoc", "ruby" }

local catalog = {
  lua = { servers = { "lua_ls" }, tools = { "stylua" }, parsers = { "lua", "luadoc" } },
  python = { servers = { "basedpyright", "ruff" }, parsers = { "python" } },
  shell = { servers = { "bashls" }, tools = { "shfmt", "shellcheck" }, parsers = { "bash" } },
  tex = { servers = { "texlab" }, executables = { "latexmk" }, parsers = { "latex" } },
  json = { servers = { "jsonls" }, tools = { "prettier" }, parsers = { "json" } },
  yaml = { servers = { "yamlls" }, tools = { "prettier" }, parsers = { "yaml" } },
  toml = { servers = { "taplo" }, parsers = { "toml" } },
  markdown = { servers = { "rumdl" }, parsers = { "markdown", "markdown_inline" } },
  web = {
    servers = { "html", "cssls", "vtsls" },
    tools = { "prettier" },
    parsers = { "html", "css", "javascript", "typescript", "tsx" },
  },
  c = { servers = { "clangd" }, parsers = { "c", "cpp" } },
  clojure = {
    system = { clojure_lsp = "clojure-lsp" },
    executables = { "clojure-lsp" },
    parsers = { "clojure" },
  },
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
M.parsers = collect("parsers")
for _, parser in ipairs(core_parsers) do
  if not vim.tbl_contains(M.parsers, parser) then
    M.parsers[#M.parsers + 1] = parser
  end
end
table.sort(M.parsers)

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
