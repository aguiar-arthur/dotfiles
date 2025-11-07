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
      win = { border = "rounded" },
    })

    -- Group descriptions for your existing mappings
    which_key.add({
      -- General
      { "<leader>q", desc = "Quit" },
      { "<leader>w", desc = "Save" },

      -- File & Explorer
      { "<leader>e", desc = "Toggle File Tree" },
      { "<leader>r", desc = "Refresh Tree" },
      { "<leader>f", group = "File" },
      { "<leader>ff", desc = "Find Files" },
      { "<leader>fg", desc = "Live Grep" },

      -- Harpoon
      { "<leader>a", desc = "Add File (Harpoon)" },
      { "<C-e>", desc = "Harpoon Menu" },
      { "<C-h>", desc = "Harpoon File 1" },
      { "<C-j>", desc = "Harpoon File 2" },
      { "<C-k>", desc = "Harpoon File 3" },
      { "<C-l>", desc = "Harpoon File 4" },

      -- LSP / Code
      { "<leader>r", desc = "Refresh Tree" }, -- already mapped, keep for context
      { "<leader>rn", desc = "Rename Symbol" },
      { "<leader>ca", desc = "Code Action" },
      { "<leader>d", desc = "Diagnostics" },

      -- Git
      { "<leader>g", group = "Git" },
      { "<leader>hs", desc = "Stage Hunk" },
      { "<leader>hr", desc = "Reset Hunk" },
      { "<leader>hu", desc = "Undo Stage Hunk" },
      { "<leader>hp", desc = "Preview Hunk" },
      { "<leader>hb", desc = "Blame Line" },
      { "<leader>tb", desc = "Toggle Blame" },
      { "<leader>hd", desc = "Diff This" },

      -- Trouble / Diagnostics
      { "<leader>x", group = "Diagnostics" },
      { "<leader>xx", desc = "Toggle Trouble" },
      { "<leader>xw", desc = "Workspace Diagnostics" },
      { "<leader>xd", desc = "Document Diagnostics" },
      { "<leader>xl", desc = "Loclist" },
      { "<leader>xq", desc = "Quickfix" },
      { "<leader>xt", desc = "Todo Trouble" },
      { "<leader>xT", desc = "Todo Telescope" },

      -- Terminal
      { "<leader>t", group = "Terminal" },
      { "<leader>tf", desc = "Float Terminal" },
      { "<leader>th", desc = "Horizontal Terminal" },
      { "<leader>tv", desc = "Vertical Terminal" },
      { "<leader>tg", desc = "Lazygit" },

      -- Buffers
      { "<leader>b", group = "Buffers" },
      { "<leader>bd", desc = "Close Buffer" },
      { "<leader>bb", desc = "List Buffers" },

      -- Splits
      { "<leader>s", group = "Splits" },
      { "<leader>sv", desc = "Vertical Split" },
      { "<leader>sh", desc = "Horizontal Split" },
      { "<leader>sc", desc = "Close Split" },
      { "<leader>so", desc = "Close Other Splits" },
    })
  end,
}
