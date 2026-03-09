return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    config = function()
      local lspconfig = require("lspconfig")

      if not lspconfig.lua_ls.manager then
        lspconfig.lua_ls.setup({
          settings = {
            Lua = {
              diagnostics = { globals = { "vim", "love" } },
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
              runtime = { version = "LuaJIT" },
            },
          },
        })
      end
    end,
  },

  {
    "nvimtools/none-ls.nvim",
    optional = true,
    config = function()
      local null_ls = require("null-ls")

      null_ls.builtins.formatting.stylua.with({
        extra_args = { "--indent-type=Spaces", "--indent-width=2" },
      })
    end,
  },
}
