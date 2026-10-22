if vim.fn.has("nvim-0.12") == 0 then
  vim.notify(
    "This configuration requires Neovim >= 0.12 (brew upgrade neovim)",
    vim.log.levels.ERROR
  )
  return
end

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
