return {
  "neovim/nvim-lspconfig",
  opts = function()
    vim.lsp.config("lua_ls", {
      cmd = { "lua-language-server" },
      filetypes = { "lua" },
      root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
      settings = {
        Lua = {
          diagnostics = {
            -- Reconhece a variável global 'vim' do Neovim
            globals = { "vim" },
          },
          workspace = {
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })
    
    -- Habilita o servidor usando a API nativa
    vim.lsp.enable("lua_ls")
  end,
}
