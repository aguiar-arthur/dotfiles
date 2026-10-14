local settings = require("config.settings")
local mason_servers = settings.mason_servers
local system_servers = settings.system_servers
local mason_tools = settings.mason_tools

return {

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },

  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    build = ":MasonUpdate",
    keys = { { "<leader>lM", "<cmd>Mason<CR>", desc = "Mason" } },
    opts = {},
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
      require("mason-lspconfig").setup({ automatic_enable = mason_servers })
      require("mason-tool-installer").setup({
        ensure_installed = vim.list_extend(vim.deepcopy(mason_tools), mason_servers),
        run_on_start = false,
      })

      for server, bin in pairs(system_servers) do
        if vim.fn.executable(bin) == 1 then
          vim.lsp.enable(server)
        end
      end

      vim.diagnostic.config({
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
        float = { source = true },
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
          vim.bo[buf].formatexpr = ""

          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, silent = true, desc = desc })
          end

          map("gd", Snacks.picker.lsp_definitions, "Go to definition")
          map("gr", Snacks.picker.lsp_references, "Go to references")

          map("<leader>ld", Snacks.picker.lsp_definitions, "Definition")
          map("<leader>lr", Snacks.picker.lsp_references, "References")
          map("<leader>li", Snacks.picker.lsp_implementations, "Implementation")
          map("<leader>lt", Snacks.picker.lsp_type_definitions, "Type definition")
          map("<leader>lD", vim.lsp.buf.declaration, "Declaration")
          map("<leader>ln", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          map("<leader>ls", vim.lsp.buf.signature_help, "Signature help")
          map("<leader>lR", "<cmd>LspRestart<CR>", "Restart LSP")

          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local provider = client and client.server_capabilities.codeActionProvider
          local kinds = type(provider) == "table" and provider.codeActionKinds or {}
          local taken = vim.api.nvim_buf_call(buf, function()
            return vim.fn.maparg("<localleader>o", "n") ~= ""
          end)
          if vim.tbl_contains(kinds, "source.organizeImports") and not taken then
            map("<localleader>o", function()
              vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" }, diagnostics = {} },
                apply = true,
              })
            end, "Organize imports")
          end
        end,
      })
    end,
  },
}
