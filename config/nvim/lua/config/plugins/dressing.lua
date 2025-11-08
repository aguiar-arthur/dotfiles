return {
  "stevearc/dressing.nvim",
  event = "VeryLazy",
  config = function()
    require("dressing").setup({
      input = { border = "rounded" },
      select = { backend = { "telescope", "builtin" } },
    })
  end,
}