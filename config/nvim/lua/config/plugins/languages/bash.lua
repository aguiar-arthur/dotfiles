return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    config = function()
      local lspconfig = require("lspconfig")

      if not lspconfig.bashls.manager then
        lspconfig.bashls.setup({
          settings = {
            bashIde = {
              globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
            },
          },
        })
      end
    end,
  },

  {
    "nvimtools/none-ls.nvim",
    optional = true,
    config = function()
      local null_ls = require("null-ls")

      null_ls.builtins.formatting.shfmt.with({
        extra_args = { "-i", "2", "-bn" }, -- 2 spaces, binary operators at start
      })

      null_ls.builtins.diagnostics.shellcheck.with({
        extra_args = { "--severity=warning" },
      })
    end,
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    config = function()
      local dap = require("dap")

      if dap.adapters.bash == nil then
        dap.adapters.bash = {
          type = "executable",
          command = "bash-debug-adapter",
        }

        dap.configurations.bash = {
          {
            type = "bash",
            request = "launch",
            name = "Launch Bash Script",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "bash",
            request = "launch",
            name = "Run with Arguments",
            program = "${file}",
            args = function()
              return vim.fn.input("Arguments: "):gmatch("%S+") or {}
            end,
            cwd = "${workspaceFolder}",
          },
        }
      end
    end,
  },
}
