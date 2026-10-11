local function python_path()
  local venv =
    vim.fs.find(".venv", { path = vim.fn.expand("%:p:h"), upward = true, type = "directory" })[1]
  if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
    return venv .. "/bin/python"
  end
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  return vim.fn.exepath("python3")
end

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
          vim.ui.input({ prompt = "Condition: " }, function(condition)
            if condition and condition ~= "" then
              require("dap").set_breakpoint(condition)
            end
          end)
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

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = { command = "js-debug-adapter", args = { "${port}" } },
      }
      for _, language in ipairs({ "javascript", "typescript" }) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch this file (node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to a node process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end

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
