local notes = require("config.settings").notes

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    opts = {
      file_types = { "markdown" },
      latex = { enabled = false },
      win_options = { conceallevel = { default = 2, rendered = 2 } },
    },
  },

  {
    "obsidian-nvim/obsidian.nvim",
    cmd = "Obsidian",
    event = {
      { event = { "BufReadPre", "BufNewFile" }, pattern = vim.fn.expand(notes.dir) .. "/*" },
    },
    keys = {
      { "<leader>nf", "<cmd>Obsidian quick_switch<CR>", desc = "Find note" },
      { "<leader>ng", "<cmd>Obsidian search<CR>", desc = "Grep notes" },
      { "<leader>nn", "<cmd>Obsidian new<CR>", desc = "New note" },
      { "<leader>nd", "<cmd>Obsidian today<CR>", desc = "Daily note" },
      { "<leader>nb", "<cmd>Obsidian backlinks<CR>", desc = "Backlinks of this note" },
    },
    opts = function()
      local dir = vim.fn.expand(notes.dir)
      vim.fn.mkdir(dir, "p")
      local template = vim.fn.stdpath("config") .. "/templates/note.md"
      return {
        legacy_commands = false,
        workspaces = { { name = "notes", path = dir } },
        note_id_func = require("obsidian.builtin").title_id,
        frontmatter = { enabled = false },
        note = { template = template },
        daily_notes = { folder = notes.daily, default_tags = {}, template = template },
        picker = { name = "snacks.picker" },
        ui = { enable = false },
        footer = { enabled = false },
        checkbox = { order = { " ", "x" } },
      }
    end,
  },
}
