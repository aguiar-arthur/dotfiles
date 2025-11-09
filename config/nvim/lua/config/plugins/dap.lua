return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "williamboman/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Virtual text annotations
      require("nvim-dap-virtual-text").setup({
        commented = true,
      })

      -- DAP UI setup
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.35 },
              { id = "breakpoints", size = 0.15 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              "repl",
              "console",
            },
            size = 0.25,
            position = "bottom",
          },
        },
      })

      -- Auto open/close UI
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,
  },
}
