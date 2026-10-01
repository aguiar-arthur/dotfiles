-- LSP com a API nativa do Neovim >= 0.11 (vim.lsp.config / vim.lsp.enable).
--   * defaults de cada servidor: nvim-lspconfig (pasta lsp/ do plugin)
--   * ajustes pessoais por servidor: ~/.config/nvim/after/lsp/<servidor>.lua
--   * instalação dos binários: mason (servidores + formatters)

-- Servidores instalados/gerenciados pelo Mason
local mason_servers = {
  "lua_ls", -- Lua
  "basedpyright", -- Python (tipos)
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

-- Servidores instalados fora do Mason (ex.: Brewfile). Só habilita se o binário existir.
local system_servers = {
  clojure_lsp = "clojure-lsp",
}

-- Formatters / ferramentas (usados pelo conform.nvim)
local mason_tools = {
  "stylua",
  "shfmt",
  "shellcheck", -- usado pelo bashls
  "prettier",
}

return {
  -- Tipos da API do Neovim para o lua_ls
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
      -- Capabilities de todos os servidores (completion do blink.cmp)
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Instala e habilita automaticamente os servidores do Mason
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

      -- Atalhos buffer-locais, criados quando um servidor anexa ao buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)

          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, silent = true, desc = desc })
          end

          -- Atalhos de uma tecla
          map("gd", function() Snacks.picker.lsp_definitions() end, "Go to definition")
          map("gr", function() Snacks.picker.lsp_references() end, "Go to references")
          map("gi", function() Snacks.picker.lsp_implementations() end, "Go to implementation")
          map("K", vim.lsp.buf.hover, "Hover documentation")

          -- Prefixo <leader>l
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

          -- ruff cuida de lint/format; hover fica com o basedpyright
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
        end,
      })
    end,
  },
}
