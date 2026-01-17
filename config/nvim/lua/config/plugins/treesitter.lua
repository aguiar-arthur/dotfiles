return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    highlight = { enable = true },
    indent = { enable = true },
    ensure_installed = { "lua" },
  },
  config = function(_, opts)
    require("nvim-treesitter").setup(opts)
  end,
}
