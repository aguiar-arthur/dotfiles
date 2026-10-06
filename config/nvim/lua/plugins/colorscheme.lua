return {
  "Mofiqul/dracula.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    italic_comment = true,

    overrides = {
      DiffAdd = { bg = "#2f4f42" },
      DiffDelete = { bg = "#4f323c", fg = "#6c4652" },
      DiffChange = { bg = "#34414e" },
      DiffText = { bg = "#466372", bold = true },
    },
  },
  config = function(_, opts)
    require("dracula").setup(opts)
    vim.cmd.colorscheme("dracula")
  end,
}
