-- LSP using the native Neovim >= 0.11 API (vim.lsp.config / vim.lsp.enable).
--   * per-server defaults: nvim-lspconfig (the plugin's lsp/ folder)
--   * personal per-server overrides: ~/.config/nvim/after/lsp/<server>.lua
--   * binary installation: mason (servers + formatters)

-- Servers installed/managed by Mason
local mason_servers = {
  "lua_ls", -- Lua
  "basedpyright", -- Python (types)
  "ruff", -- Python (lint/format)
  "bashls", -- Bash
  "texlab", -- LaTeX / BibTeX
  "jsonls",
  "yamlls",
  "taplo", -- TOML
  "marksman", -- Markdown
  "html",
  "cssls",
  "vtsls", -- TypeScript / JavaScript
  "clangd", -- C / C++
}

-- Servers installed outside Mason (e.g. Brewfile). Only enabled if the binary exists.
local system_servers = {
  clojure_lsp = "clojure-lsp",
}

-- Formatters / tools (used by conform.nvim)
local mason_tools = {
  "stylua",
  "shfmt",
  "shellcheck", -- used by bashls
  "prettier",
}

return {
  -- Neovim API types for lua_ls
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
      },
    },
  },

  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    build = ":MasonUpdate",
    keys = { { "<leader>lM", "<cmd>Mason<CR>", desc = "Mason" } },
    opts = { ui = { border = "rounded" } },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "b0o/SchemaStore.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Capabilities for all servers (blink.cmp completion)
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Automatically install and enable the Mason servers
      require("mason-lspconfig").setup({
        ensure_installed = mason_servers,
        automatic_enable = true,
      })
      require("mason-tool-installer").setup({
        ensure_installed = mason_tools,
        run_on_start = true,
        start_delay = 2000,
      })

      for server, bin in pairs(system_servers) do
        if vim.fn.executable(bin) == 1 then vim.lsp.enable(server) end
      end

      vim.diagnostic.config({
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN] = "▲",
            [vim.diagnostic.severity.INFO] = "●",
            [vim.diagnostic.severity.HINT] = "⚑",
          },
        },
      })

      -- Buffer-local keymaps, created when a server attaches to the buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)

          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, silent = true, desc = desc })
          end

          -- Single-key shortcuts
          map("gd", function() Snacks.picker.lsp_definitions() end, "Go to definition")
          map("gr", function() Snacks.picker.lsp_references() end, "Go to references")
          map("gi", function() Snacks.picker.lsp_implementations() end, "Go to implementation")
          map("K", vim.lsp.buf.hover, "Hover documentation")

          -- <leader>l prefix
          map("<leader>ld", function() Snacks.picker.lsp_definitions() end, "Definition")
          map("<leader>lr", function() Snacks.picker.lsp_references() end, "References")
          map("<leader>li", function() Snacks.picker.lsp_implementations() end, "Implementation")
          map("<leader>lt", function() Snacks.picker.lsp_type_definitions() end, "Type definition")
          map("<leader>lD", vim.lsp.buf.declaration, "Declaration")
          map("<leader>ln", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          map("<leader>lh", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>ls", vim.lsp.buf.signature_help, "Signature help")
          map("<leader>ll", function() Snacks.picker.diagnostics_buffer() end, "Buffer diagnostics")
          map("<leader>lR", "<cmd>LspRestart<CR>", "Restart LSP")
          map("<leader>lf", function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end, "Format buffer/selection", { "n", "v" })

          -- ruff handles lint/format; hover is left to basedpyright
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
        end,
      })
    end,
  },
}
