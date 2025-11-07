return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local ok, which_key = pcall(require, "which-key")
    if not ok then
      vim.notify("which-key not found", vim.log.levels.ERROR)
      return
    end

    which_key.setup({
      plugins = {
        marks = true,
        registers = true,
      },
      win = { border = "rounded" }, -- updated option
    })

    which_key.add({
      { "<leader>f", group = "file" },
      { "<leader>g", group = "git" },
    })
  end,
}
