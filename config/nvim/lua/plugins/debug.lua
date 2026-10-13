local python_path = require("dotfiles.python").path

local debuggable = { "python" }

local function dap(method)
  return function()
    require("dap")[method]()
  end
end

local function key(lhs, rhs, desc, mode)
  return { "<localleader>" .. lhs, rhs, desc = desc, mode = mode, ft = debuggable }
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mason-org/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
    },
    keys = {
      key("db", dap("toggle_breakpoint"), "Toggle breakpoint"),
      key("dB", function()
        vim.ui.input({ prompt = "Condition: " }, function(condition)
          if condition and condition ~= "" then
            require("dap").set_breakpoint(condition)
          end
        end)
      end, "Conditional breakpoint"),
      key("dc", dap("continue"), "Continue / start"),
      key("di", dap("step_into"), "Step into"),
      key("do", dap("step_over"), "Step over"),
      key("dO", dap("step_out"), "Step out"),
      key("dr", function()
        require("dap").repl.toggle()
      end, "Toggle REPL"),
      key("dl", dap("run_last"), "Run last"),
      key("dt", dap("terminate"), "Terminate"),
      key("du", function()
        require("dapui").toggle()
      end, "Toggle DAP UI"),
      key("de", function()
        require("dapui").eval()
      end, "Eval expression", { "n", "v" }),
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      require("mason-nvim-dap").setup({
        ensure_installed = {},
        automatic_installation = false,
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

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch this file",
          program = "${file}",
          pythonPath = python_path,
          console = "integratedTerminal",
        },
      }

      local signs = {
        DapBreakpoint = { text = "●", texthl = "DiagnosticError" },
        DapBreakpointCondition = { text = "◆", texthl = "DiagnosticWarn" },
        DapLogPoint = { text = "◆", texthl = "DiagnosticInfo" },
        DapBreakpointRejected = { text = "○", texthl = "DiagnosticHint" },
        DapStopped = { text = "→", texthl = "DiagnosticWarn", linehl = "DiffAdd" },
      }
      for name, sign in pairs(signs) do
        vim.fn.sign_define(name, sign)
      end

      local function open_ui()
        dapui.open()
      end
      dap.listeners.before.attach.dapui_config = open_ui
      dap.listeners.before.launch.dapui_config = open_ui
    end,
  },
}
