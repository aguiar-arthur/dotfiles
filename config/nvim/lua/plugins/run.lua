local commands = {
  python = function()
    return { "cd $dir &&", vim.fn.shellescape(require("dotfiles.python").path()), "-u $fileName" }
  end,
  lua = "cd $dir && nvim -l $fileName",
  sh = "cd $dir && bash $fileName",
}

return {
  {
    "CRAG666/code_runner.nvim",
    cmd = { "RunFile", "RunClose" },
    keys = {
      {
        "<localleader>r",
        "<cmd>RunFile<CR>",
        ft = vim.list_extend(
          vim.tbl_keys(commands),
          { "javascript", "java", "c", "cpp", "ruby", "rust" }
        ),
        desc = "Run file",
      },
    },
    opts = {
      mode = "term",
      focus = false,
      term = { position = "bot", size = 12 },
      before_run_filetype = function()
        vim.cmd("silent update")
      end,
      filetype = commands,
    },
  },
}
