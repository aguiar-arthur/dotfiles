local function neotest(lhs, method, arg, desc)
  return {
    "<localleader>" .. lhs,
    function()
      vim.cmd("silent! update")
      require("neotest")[method[1]][method[2]](type(arg) == "function" and arg() or arg)
    end,
    desc = desc,
    ft = "python",
  }
end

return {
  {
    "nvim-neotest/neotest",
    keys = {
      neotest("tt", { "run", "run" }, nil, "Run the nearest test"),
      neotest("tf", { "run", "run" }, function()
        return vim.fn.expand("%:p")
      end, "Test this file"),
      neotest("tp", { "run", "run" }, { suite = true }, "Test the project"),
      neotest("tl", { "run", "run_last" }, nil, "Run the last test"),
      neotest("tS", { "run", "stop" }, nil, "Stop the tests"),
      neotest("ts", { "summary", "toggle" }, nil, "Toggle the test summary"),
      neotest("to", { "output", "open" }, { enter = true, auto_close = true }, "Test output"),
      neotest("tO", { "output_panel", "toggle" }, nil, "Toggle the output panel"),
      neotest("td", { "run", "run" }, { strategy = "dap" }, "Debug the nearest test"),
      {
        "]T",
        function()
          require("neotest").jump.next({ status = "failed" })
        end,
        ft = "python",
        desc = "Next failed test",
      },
      {
        "[T",
        function()
          require("neotest").jump.prev({ status = "failed" })
        end,
        ft = "python",
        desc = "Previous failed test",
      },
    },
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({ runner = "pytest" }),
        },
        output = { open_on_run = false },
        quickfix = { open = false },
      })
    end,
  },
}
