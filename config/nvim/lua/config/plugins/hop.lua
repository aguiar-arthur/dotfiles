return {
  "phaazon/hop.nvim",
  branch = "v2",
  event = "VeryLazy",
  config = function()
    local hop = require("hop")
    hop.setup()
  end,
}