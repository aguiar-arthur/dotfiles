return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    config = function()
      local lspconfig = require("lspconfig")

      if not lspconfig.pyright.manager then
        lspconfig.pyright.setup({
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "basic",
                stubPath = "./typings",
              },
              pythonPath = os.getenv("VIRTUAL_ENV") and os.getenv("VIRTUAL_ENV") .. "/bin/python" or "python3",
            },
          },
        })
      end
    end,
  },
}
