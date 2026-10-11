local M = {
  colorscheme = "dracula",
  wrap = true,
  format_on_save = true,
  spelllang = { "en_us", "pt_br" },
  mason_servers = {
    "lua_ls",
    "basedpyright",
    "ruff",
    "bashls",
    "texlab",
    "jsonls",
    "yamlls",
    "taplo",
    "html",
    "cssls",
    "vtsls",
    "clangd",
  },
  treesitter_indent = {
    "bash",
    "c",
    "cpp",
    "css",
    "html",
    "javascript",
    "json",
    "lua",
    "toml",
    "tsx",
    "typescript",
  },
  mason_tools = { "shellcheck", "debugpy", "codelldb", "js-debug-adapter" },
  system_servers = { rumdl = "rumdl", clojure_lsp = "clojure-lsp" },
  parsers = {
    "bash",
    "c",
    "clojure",
    "cpp",
    "css",
    "diff",
    "html",
    "javascript",
    "json",
    "latex",
    "lua",
    "luadoc",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "regex",
    "ruby",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  },
}

local path = vim.fn.stdpath("config") .. "/lua/config/local.lua"
if vim.uv.fs_stat(path) then
  local ok, overrides = pcall(dofile, path)
  if not ok then
    vim.schedule(function()
      vim.notify("lua/config/local.lua failed: " .. tostring(overrides), vim.log.levels.ERROR)
    end)
  elseif type(overrides) == "table" then
    M = vim.tbl_deep_extend("force", M, overrides)
  end
end

return M
