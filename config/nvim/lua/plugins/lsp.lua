local settings = require("config.settings")
local mason_servers = settings.mason_servers
local system_servers = settings.system_servers

local pickers = {
  definition = { "lsp_definitions", "textDocument/definition", "definitions" },
  declaration = { "lsp_declarations", "textDocument/declaration", "declarations" },
  references = { "lsp_references", "textDocument/references", "references" },
  implementation = { "lsp_implementations", "textDocument/implementation", "implementations" },
  type_definition = { "lsp_type_definitions", "textDocument/typeDefinition", "type definitions" },
  incoming = { "lsp_incoming_calls", "textDocument/prepareCallHierarchy", "a call hierarchy" },
  outgoing = { "lsp_outgoing_calls", "textDocument/prepareCallHierarchy", "a call hierarchy" },
  symbols = { "lsp_symbols", "textDocument/documentSymbol", "symbols" },
  workspace_symbols = { "lsp_workspace_symbols", "workspace/symbol", "workspace symbols" },
}

local picker_keys = {
  { "gd", "definition", "Go to definition" },
  { "grr", "references", "Go to references" },
  { "gri", "implementation", "Go to implementation" },
  { "grt", "type_definition", "Go to type definition" },
  { "<leader>ld", "definition", "Definition" },
  { "<leader>lD", "declaration", "Declaration" },
  { "<leader>li", "implementation", "Implementations" },
  { "<leader>lt", "type_definition", "Type definition" },
  { "<leader>lr", "references", "References" },
  { "<leader>lc", "incoming", "Incoming calls (who calls this)" },
  { "<leader>lC", "outgoing", "Outgoing calls (what this calls)" },
  { "<leader>ls", "symbols", "Symbols (this file)" },
  { "<leader>lS", "workspace_symbols", "Symbols (workspace)" },
}

local function pick(source, method, what)
  return function()
    if #vim.lsp.get_clients({ bufnr = 0, method = method }) == 0 then
      vim.notify("No language server here offers " .. what, vim.log.levels.WARN)
      return
    end
    Snacks.picker[source]()
  end
end

local action_keys = {
  { "<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "x" } },
  {
    "<leader>lA",
    function()
      vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
    end,
    "Source action (imports, fix all)",
  },
  { "<leader>ln", vim.lsp.buf.rename, "Rename" },
  { "<leader>ll", vim.lsp.codelens.run, "Run code lens" },
  { "<leader>lk", vim.lsp.buf.signature_help, "Signature help" },
  {
    "<leader>lI",
    function()
      Snacks.picker.lsp_config()
    end,
    "Servers (info)",
  },
  { "<leader>lR", "<cmd>lsp restart<CR>", "Restart LSP" },
}

local function organize_imports(buf, client_id, map)
  local client = vim.lsp.get_client_by_id(client_id)
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
end

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

          for _, key in ipairs(picker_keys) do
            map(key[1], pick(unpack(pickers[key[2]])), key[3])
          end
          for _, key in ipairs(action_keys) do
            map(key[1], key[2], key[3], key[4])
          end
          organize_imports(buf, ev.data.client_id, map)
        end,
      })
    end,
  },
}
