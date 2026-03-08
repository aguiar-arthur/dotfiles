return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local wk = require("which-key")
    wk.setup({})

    wk.add({
      { "<leader>?", desc = "Show Key Bindings" },
      { "<leader>b", group = "buffer" },
      { "<leader>c", group = "code" },
      { "<leader>d", group = "diagnostics" },
      { "<leader>f", group = "file/find" },
      { "<leader>g", group = "git" },
      { "<leader>l", group = "lsp" },
      { "<leader>m", group = "marks (harpoon)" },
      { "<leader>o", group = "open/toggle" },
      { "<leader>q", desc = "Quit" },
      { "<leader>s", desc = "Save" },
      { "<leader>t", group = "terminal" },
      { "<leader>w", group = "window" },
    })
  end,
}