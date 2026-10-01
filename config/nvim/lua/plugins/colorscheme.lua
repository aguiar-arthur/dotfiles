return {
  "Mofiqul/dracula.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    italic_comment = true,
  },
  config = function(_, opts)
    require("dracula").setup(opts)
    vim.cmd.colorscheme("dracula")
  end,
}
