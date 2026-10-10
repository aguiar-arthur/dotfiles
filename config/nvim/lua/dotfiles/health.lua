local M = {}

local health = vim.health

local required = { "git", "rg", "fd", "tree-sitter", "cc" }
local optional = { "lazygit", "node", "npm", "rumdl", "pandoc" }

local function check_version()
  health.start("Neovim")
  local v = vim.version()
  local text = ("%d.%d.%d"):format(v.major, v.minor, v.patch)
  if vim.fn.has("nvim-0.11") == 1 then
    health.ok("Neovim " .. text)
  else
    health.error("Neovim " .. text .. " is older than 0.11", "brew upgrade neovim")
  end
end

local function check_settings(settings)
  health.start("Settings")
  if settings.local_error then
    health.error("lua/config/local.lua failed: " .. tostring(settings.local_error))
  elseif settings.local_file then
    health.ok("local overrides loaded from " .. settings.local_file)
  else
    health.info("no lua/config/local.lua (defaults only)")
  end
  if vim.g.colors_name == settings.colorscheme then
    health.ok("colorscheme " .. settings.colorscheme)
  else
    health.warn(
      ("colorscheme is %s, settings ask for %s"):format(
        tostring(vim.g.colors_name),
        settings.colorscheme
      )
    )
  end
  local enabled = {}
  for name, on in pairs(settings.languages) do
    if on then
      enabled[#enabled + 1] = name
    end
  end
  table.sort(enabled)
  health.info("languages: " .. table.concat(enabled, ", "))
end

local function check_executables(settings)
  health.start("Programs")
  for _, bin in ipairs(required) do
    if vim.fn.executable(bin) == 1 then
      health.ok(bin .. ": " .. vim.fn.exepath(bin))
    else
      health.error(bin .. " is missing", "brew bundle")
    end
  end
  for _, bin in ipairs(optional) do
    if vim.fn.executable(bin) == 1 then
      health.ok(bin .. ": " .. vim.fn.exepath(bin))
    else
      health.warn(bin .. " is missing; the features that use it will not work", "brew bundle")
    end
  end
  for _, bin in ipairs(settings.executables) do
    if vim.fn.executable(bin) == 1 then
      health.ok(bin .. ": " .. vim.fn.exepath(bin))
    else
      health.warn(bin .. " is missing; an enabled language needs it", "see docs/install.md")
    end
  end
end

local function check_plugins()
  health.start("Plugins")
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    health.error("lazy.nvim is not loaded")
    return
  end
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local lock = {}
  if vim.uv.fs_stat(lockfile) then
    lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
  end
  local missing, drift, count = {}, {}, 0
  for _, plugin in pairs(lazy.plugins()) do
    count = count + 1
    if not plugin._.installed then
      missing[#missing + 1] = plugin.name
    elseif lock[plugin.name] then
      local head = vim.trim(vim.fn.system({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }))
      if vim.v.shell_error == 0 and head ~= lock[plugin.name].commit then
        drift[#drift + 1] = plugin.name
      end
    end
  end
  if #missing > 0 then
    health.error("not installed: " .. table.concat(missing, ", "), ":Lazy install")
  else
    health.ok(count .. " plugins installed")
  end
  if #drift > 0 then
    health.warn(
      "differ from lazy-lock.json: " .. table.concat(drift, ", "),
      { "commit the lock if the update works", ":Lazy restore to go back" }
    )
  else
    health.ok("every plugin matches lazy-lock.json")
  end
end

local function check_mason(settings)
  health.start("Mason")
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    health.info("mason is not loaded yet (it loads with the first file)")
    return
  end
  local installed = {}
  for _, name in ipairs(registry.get_installed_package_names()) do
    installed[name] = true
  end
  local wanted = vim.deepcopy(settings.mason_tools)
  local mapping = {}
  local mok, mlsp = pcall(require, "mason-lspconfig")
  if mok and mlsp.get_mappings then
    mapping = mlsp.get_mappings().lspconfig_to_package or {}
  end
  for _, server in ipairs(settings.mason_servers) do
    wanted[#wanted + 1] = mapping[server] or server
  end
  local absent = {}
  for _, name in ipairs(wanted) do
    if not installed[name] then
      absent[#absent + 1] = name
    end
  end
  if #absent > 0 then
    health.warn(
      "not installed yet: " .. table.concat(absent, ", "),
      ":Mason shows progress and errors"
    )
  else
    health.ok(#wanted .. " tools installed")
  end
end

local function check_extras(settings)
  health.start("Extras")
  local fonts = {}
  for _, dir in ipairs({ "~/Library/Fonts", "/Library/Fonts", "~/.local/share/fonts" }) do
    vim.list_extend(fonts, vim.fn.glob(vim.fn.expand(dir) .. "/*Nerd*", false, true))
  end
  if #fonts > 0 then
    health.ok("a Nerd Font is installed")
  else
    health.warn("no Nerd Font found; icons will show as boxes", "brew bundle")
  end
  local spell = vim.fn.stdpath("data") .. "/site/spell"
  for _, lang in ipairs(settings.spelllang) do
    local short = lang:match("^(%a+)")
    if short ~= "en" and #vim.fn.glob(spell .. "/" .. short .. ".*.spl", false, true) == 0 then
      health.info(
        ("spell file for %s not downloaded yet; Neovim offers it the first time"):format(lang)
      )
    end
  end
end

function M.check()
  local settings = require("config.settings")
  check_version()
  check_settings(settings)
  check_executables(settings)
  check_plugins()
  check_mason(settings)
  check_extras(settings)
end

return M
