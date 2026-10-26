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
      "igorlfs/nvim-dap-view",
      "mason-org/mason.nvim",
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
        require("dap-view").toggle(true)
      end, "Toggle the debug panels"),
      key("de", function()
        require("dap-view").hover()
      end, "Eval expression"),
      key("de", function()
        local lines =
          vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
        require("dap-view").hover(table.concat(lines, "\n"))
      end, "Eval selection", "x"),
    },
    config = function()
      local dap = require("dap")

      dap.adapters.python = { type = "executable", command = vim.fn.exepath("debugpy-adapter") }

      require("dap-view").setup({
        auto_toggle = "open",
        winbar = { default_section = "scopes" },
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
    end,
  },
}
