return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "mason-org/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
    },
    keys = {
      {
        "<leader>Db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>DB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Condition: "))
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>Dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue / start",
      },
      {
        "<leader>Di",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>Do",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
      {
        "<leader>DO",
        function()
          require("dap").step_out()
        end,
        desc = "Step out",
      },
      {
        "<leader>Dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>Dl",
        function()
          require("dap").run_last()
        end,
        desc = "Run last",
      },
      {
        "<leader>Dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>Du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle DAP UI",
      },
      {
        "<leader>De",
        function()
          require("dapui").eval()
        end,
        desc = "Eval expression",
        mode = { "n", "v" },
      },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      require("nvim-dap-virtual-text").setup({ commented = true })
      require("mason-nvim-dap").setup({
        ensure_installed = { "python" },
        automatic_installation = true,
        handlers = {},
      })

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
          { elements = { "repl", "console" }, size = 0.25, position = "bottom" },
        },
      })

      dap.listeners.before.attach.dapui_config = dapui.open
      dap.listeners.before.launch.dapui_config = dapui.open
      dap.listeners.before.event_terminated.dapui_config = dapui.close
      dap.listeners.before.event_exited.dapui_config = dapui.close
    end,
  },
}
