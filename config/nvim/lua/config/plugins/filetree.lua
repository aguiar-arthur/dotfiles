-- lua/config/plugins/filetree.lua
return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  cmd = { "NvimTreeToggle", "NvimTreeFocus" },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("nvim-tree").setup({
      sort = { sorter = "case_sensitive" },
      view = {
        width = 35,
        side = "left",
        preserve_window_proportions = true,
      },
      renderer = {
        group_empty = true,
        highlight_git = true,
        highlight_opened_files = "icon",
        icons = {
          show = { file = true, folder = true, folder_arrow = true, git = true },
        },
      },
      filters = {
        dotfiles = false,
      },
      git = {
        enable = true,
        ignore = false,
        timeout = 400,
      },
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = true,
        },
      },
    })

    vim.cmd([[
      highlight NvimTreeNormal guibg=#282A36
      highlight NvimTreeNormalNC guibg=#282A36
    ]])

    -- keymaps
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    map("n", "<leader>e", ":NvimTreeToggle<CR>", opts)
    map("n", "<leader>r", ":NvimTreeRefresh<CR>", opts)
    map("n", "<leader>f", ":NvimTreeFindFile<CR>", opts)
  end,
}
