return {
  "Mofiqul/dracula.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    italic_comment = true,
    -- Dracula's diff colors paint added lines solid green, drop syntax colors on changed
    -- lines and grey out the changed text. Tinted backgrounds keep the code readable.
    overrides = {
      DiffAdd = { bg = "#2f4f42" }, -- green 18% over the background
      DiffDelete = { bg = "#4f323c", fg = "#6c4652" }, -- red 18%; fg colors the ╱ filler
      DiffChange = { bg = "#34414e" }, -- cyan 12%: the changed line
      DiffText = { bg = "#466372", bold = true }, -- cyan 30%: the changed characters
    },
  },
  config = function(_, opts)
    require("dracula").setup(opts)
    vim.cmd.colorscheme("dracula")
  end,
}
