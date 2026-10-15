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
        local missing = require("dotfiles.treesitter").missing(parsers)
        if #missing == 0 then
          return
        end
        if vim.fn.executable("tree-sitter") == 1 then
          ts.install(missing)
        else
          vim.notify("tree-sitter CLI not found: brew install tree-sitter-cli", vim.log.levels.WARN)
        end
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        require("dotfiles.treesitter").attach(ev.buf)
      end,
    })
  end,
}
