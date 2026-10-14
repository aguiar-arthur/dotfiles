local notes = require("config.settings").notes

local function render_options()
  local level = vim.go.conceallevel
  return {
    file_types = { "markdown" },
    latex = { enabled = false },
    win_options = { conceallevel = { default = level, rendered = level } },
  }
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    opts = render_options,
    config = function(_, opts)
      local render = require("render-markdown")
      render.setup(opts)
      vim.api.nvim_create_autocmd("OptionSet", {
        group = vim.api.nvim_create_augroup("user_render_markdown_conceal", { clear = true }),
        pattern = "conceallevel",
        callback = function()
          if vim.v.option_type == "global" then
            render.setup(render_options())
            render.set(render.get())
          end
        end,
      })
    end,
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
