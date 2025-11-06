return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  config = function()
    require("lualine").setup({
      options = { theme = "dracula", section_separators = '', component_separators = '' },
    })
  end,
}
