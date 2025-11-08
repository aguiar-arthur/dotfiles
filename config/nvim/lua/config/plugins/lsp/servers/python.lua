local M = {}

function M.setup(lspconfig, on_attach, capabilities)
  lspconfig.pyright.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "basic",
          autoImportCompletions = true,
          useLibraryCodeForTypes = true,
        },
      },
    },
  })
end

return M
