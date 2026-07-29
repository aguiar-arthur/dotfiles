return {
  "neovim/nvim-lspconfig",
  opts = function()
    vim.lsp.config("bashls", {
      cmd = { "bash-language-server", "start" },
      filetypes = { "sh", "bash" },
      root_markers = { ".git" },
      settings = {
        bashIde = {
          globPattern = "*@(.sh|.inc|.bash|.command)",
        },
      },
    })
    
    -- Habilita o servidor usando a API nativa
    vim.lsp.enable("bashls")
  end,
}
