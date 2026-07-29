return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },

  config = function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local cmp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if cmp_ok then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    -- Configuração padrão global para os servidores LSP nativos
    local servers = { "html", "cssls", "jsonls", "yamlls" }
    for _, lsp in ipairs(servers) do
      vim.lsp.config[lsp] = {
        capabilities = capabilities,
      }
      vim.lsp.enable(lsp)
    end

    vim.diagnostic.config({
      underline = true,
      virtual_text = { spacing = 4, prefix = "●" },
      severity_sort = true,
      update_in_insert = false,
    })
  end,
}
