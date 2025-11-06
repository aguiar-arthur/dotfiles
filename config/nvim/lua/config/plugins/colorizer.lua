return {
  "norcalli/nvim-colorizer.lua",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("colorizer").setup({
      "*", -- Highlight all files
      css = { css = true, css_fn = true },
      html = { names = false }, -- Disable name highlighting in HTML
    })
  end,
}