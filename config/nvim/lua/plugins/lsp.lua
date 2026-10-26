local settings = require("config.settings")
local mason_servers = settings.mason_servers
local system_servers = settings.system_servers

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
      "b0o/SchemaStore.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("mason-lspconfig").setup({ automatic_enable = mason_servers })

      for server, bin in pairs(system_servers) do
        if vim.fn.executable(bin) == 1 then
          vim.lsp.enable(server)
        end
      end

      vim.lsp.linked_editing_range.enable(true)
      vim.lsp.codelens.enable(true)
      require("dotfiles.progress").setup()

      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = { spacing = 4, prefix = "●", source = "if_many", current_line = false },
        virtual_lines = { current_line = true },
        float = { source = true, max_width = 80, header = "" },
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
          map("grr", Snacks.picker.lsp_references, "Go to references")
          map("gri", Snacks.picker.lsp_implementations, "Go to implementation")
          map("grt", Snacks.picker.lsp_type_definitions, "Go to type definition")

          map("<leader>lD", vim.lsp.buf.declaration, "Declaration")
          map("<leader>ls", vim.lsp.buf.signature_help, "Signature help")
          map("<leader>lR", "<cmd>lsp restart<CR>", "Restart LSP")
          map("<leader>lc", Snacks.picker.lsp_incoming_calls, "Incoming calls (who calls this)")
          map("<leader>lC", Snacks.picker.lsp_outgoing_calls, "Outgoing calls (what this calls)")

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
