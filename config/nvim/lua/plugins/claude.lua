return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = { "ClaudeCode", "ClaudeCodeAdd", "ClaudeCodeSend", "ClaudeCodeStatus" },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<CR>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<CR>", desc = "Resume a Claude session" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<CR>", desc = "Continue the last Claude session" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<CR>", desc = "Select the Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>", desc = "Add this file to Claude" },
      {
        "<leader>aB",
        function()
          require("dotfiles.claude").in_last_session("ClaudeCodeAdd %")
        end,
        desc = "Add this file to the last Claude session",
      },
      {
        "<leader>as",
        "<cmd>ClaudeCodeSend<CR>",
        mode = "x",
        desc = "Send the selection to Claude",
      },
      {
        "<leader>aS",
        function()
          require("dotfiles.claude").in_last_session("ClaudeCodeSend")
        end,
        mode = "x",
        desc = "Send the selection to the last Claude session",
      },
      {
        "<leader>ab",
        "<cmd>ClaudeCodeTreeAdd<CR>",
        desc = "Add the file under the cursor to Claude",
        ft = "snacks_picker_list",
      },
      {
        "<leader>aB",
        function()
          require("dotfiles.claude").in_last_session("ClaudeCodeTreeAdd")
        end,
        desc = "Add the file under the cursor to the last Claude session",
        ft = "snacks_picker_list",
      },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<CR>", desc = "Accept Claude's diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<CR>", desc = "Reject Claude's diff" },
      { "<leader>aq", "<cmd>ClaudeCodeStop<CR>", desc = "Stop the Claude connection" },
    },
    config = function(_, opts)
      require("claudecode").setup(opts)
      require("dotfiles.claude").watch()
    end,
    opts = {
      focus_after_send = true,
      terminal = {
        snacks_win_opts = require("dotfiles.float").win("Claude"),
      },
    },
  },
}
