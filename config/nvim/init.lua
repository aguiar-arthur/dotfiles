-- Neovim >= 0.11 (native vim.lsp.config / vim.lsp.enable)
if vim.fn.has("nvim-0.11") == 0 then
  vim.notify("This configuration requires Neovim >= 0.11 (brew upgrade neovim)", vim.log.levels.ERROR)
  return
end

vim.loader.enable() -- Lua bytecode cache

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
