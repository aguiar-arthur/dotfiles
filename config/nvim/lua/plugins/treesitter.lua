local parsers = require("config.settings").parsers

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup({})

    vim.api.nvim_create_autocmd("UIEnter", {
      group = vim.api.nvim_create_augroup("user_treesitter_install", { clear = true }),
      once = true,
      callback = function()
        if vim.fn.executable("tree-sitter") == 1 then
          ts.install(parsers)
        else
          vim.notify("tree-sitter CLI not found: brew install tree-sitter-cli", vim.log.levels.WARN)
        end
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        require("dotfiles.toggles").start_treesitter(ev.buf)
      end,
    })
  end,
}
