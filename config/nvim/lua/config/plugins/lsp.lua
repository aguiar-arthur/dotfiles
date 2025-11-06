-- lua/config/plugins/lsp.lua
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },

  config = function()
    -- ================================
    -- 💡 Basic LSP Keymaps
    -- ================================
    local on_attach = function(_, bufnr)
      local map = function(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true })
      end

      map("n", "K", vim.lsp.buf.hover)
      map("n", "gd", vim.lsp.buf.definition)
      map("n", "gr", vim.lsp.buf.references)
      map("n", "gi", vim.lsp.buf.implementation)
      map("n", "<leader>rn", vim.lsp.buf.rename)
      map("n", "<leader>ca", vim.lsp.buf.code_action)
      map("n", "[d", vim.diagnostic.goto_prev)
      map("n", "]d", vim.diagnostic.goto_next)
      map("n", "<leader>e", vim.diagnostic.open_float)
    end

    -- ================================
    -- 🧩 Capabilities (for nvim-cmp)
    -- ================================
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local cmp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if cmp_ok then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    -- ================================
    -- ⚙️ Define servers (modern style)
    -- ================================
    local servers = {
      lua_ls = {
        cmd = { "lua-language-server" },
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      },

      pyright = { cmd = { "pyright-langserver", "--stdio" } },
    }

    -- ================================
    -- 🚀 Register and start each server
    -- ================================
    for name, config in pairs(servers) do
      local merged = vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = vim.fs.dirname(vim.fs.find({ ".git", "lua" }, { upward = true })[1]),
      }, config)

      -- Define configuration in the new API
      vim.lsp.config[name] = merged

      -- Start server manually
      vim.lsp.start(vim.lsp.config[name])
    end

    -- ================================
    -- 🪶 Diagnostics look
    -- ================================
    vim.diagnostic.config({
      underline = true,
      virtual_text = { spacing = 4, prefix = "●" },
      severity_sort = true,
      update_in_insert = false,
    })
  end,
}
