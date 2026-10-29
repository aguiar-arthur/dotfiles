local function neotest(lhs, run, desc)
  return {
    "<localleader>" .. lhs,
    function()
      vim.cmd("silent! update")
      run(require("neotest"))
    end,
    desc = desc,
    ft = "python",
  }
end

return {
  {
    "nvim-neotest/neotest",
    keys = {
      neotest("tt", function(nt)
        nt.run.run()
      end, "Run the nearest test"),
      neotest("tf", function(nt)
        nt.run.run(vim.fn.expand("%:p"))
      end, "Test this file"),
      neotest("tp", function(nt)
        nt.run.run({ suite = true })
      end, "Test the project"),
      neotest("tl", function(nt)
        nt.run.run_last()
      end, "Run the last test"),
      neotest("tS", function(nt)
        nt.run.stop()
      end, "Stop the tests"),
      neotest("ts", function(nt)
        nt.summary.toggle()
      end, "Toggle the test summary"),
      neotest("to", function(nt)
        nt.output.open({ enter = true, auto_close = true })
      end, "Test output"),
      neotest("tO", function(nt)
        nt.output_panel.toggle()
      end, "Toggle the output panel"),
      neotest("td", function(nt)
        nt.run.run({ strategy = "dap" })
      end, "Debug the nearest test"),
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
