return {
  "jay-babu/mason-nvim-dap.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "mfussenegger/nvim-dap",
  },
  event = "VeryLazy",
  config = function()
    require("mason-nvim-dap").setup({
      ensure_installed = { },
      automatic_installation = true,
      handlers = {},
    })
  end,
}

