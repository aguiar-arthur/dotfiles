vim.keymap.set("n", "<localleader>s", "<cmd>silent update | source %<CR>", {
  buffer = 0,
  silent = true,
  desc = "Source this file",
})
