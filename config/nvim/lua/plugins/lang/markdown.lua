return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    opts = {
      file_types = { "markdown" },
      code = { sign = false },
      heading = { sign = false },
    },
  },
}
