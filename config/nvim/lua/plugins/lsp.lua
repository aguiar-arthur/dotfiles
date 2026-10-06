local mason_servers = {
  "lua_ls",
  "basedpyright",
  "ruff",
  "bashls",
  "texlab",
  "jsonls",
  "yamlls",
  "taplo",
  "rumdl",
  "html",
  "cssls",
  "vtsls",
  "clangd",
}

local system_servers = {
  clojure_lsp = "clojure-lsp",
}

local mason_tools = {
  "stylua",
  "shfmt",
  "shellcheck",
  "prettier",
}

local function lsp_pick(source)
  return function()
    local opts = {}
    if package.loaded["diffview.lib"] and require("diffview.lib").get_current_view() then
      local here = vim.api.nvim_buf_get_name(0)
      opts.confirm = function(picker, item)
        local other = item and Snacks.picker.util.path(item) ~= here

        require("snacks.picker.actions").jump(picker, item, { cmd = other and "tab" or nil })
      end
    end
    Snacks.picker[source](opts)
  end
end

return {

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

      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

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

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)

          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, silent = true, desc = desc })
          end

          map("gd", lsp_pick("lsp_definitions"), "Go to definition")
          map("gr", lsp_pick("lsp_references"), "Go to references")
          map("gi", lsp_pick("lsp_implementations"), "Go to implementation")
          map("K", vim.lsp.buf.hover, "Hover documentation")

          map("<leader>ld", lsp_pick("lsp_definitions"), "Definition")
          map("<leader>lr", lsp_pick("lsp_references"), "References")
          map("<leader>li", lsp_pick("lsp_implementations"), "Implementation")
          map("<leader>lt", lsp_pick("lsp_type_definitions"), "Type definition")
          map("<leader>lD", vim.lsp.buf.declaration, "Declaration")
          map("<leader>ln", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          map("<leader>lh", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>ls", vim.lsp.buf.signature_help, "Signature help")
          map("<leader>lR", "<cmd>LspRestart<CR>", "Restart LSP")
          map("<leader>lf", function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end, "Format buffer/selection", { "n", "v" })

          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
        end,
      })
    end,
  },
}
