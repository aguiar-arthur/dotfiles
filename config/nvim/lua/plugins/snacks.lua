-- snacks.nvim replaces, in a single plugin: telescope, nvim-tree, toggleterm,
-- indent-blankline, dressing and noice (notifications/inputs).
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    picker = {
      enabled = true,
      sources = {
        explorer = { hidden = true, ignored = false },
        files = { hidden = true },
        grep = { hidden = true },
      },
      win = {
        input = {
          keys = {
            ["<C-j>"] = { "list_down", mode = { "i", "n" } },
            ["<C-k>"] = { "list_up", mode = { "i", "n" } },
          },
        },
      },
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = false },
    terminal = { enabled = true },
    words = { enabled = true },
  },
  keys = {
    -- Open / toggle ------------------------------------------------------
    { "<leader>op", function() Snacks.explorer() end, desc = "Toggle file tree" },
    { "<leader>of", function() Snacks.explorer.reveal() end, desc = "Find file in tree" },
    { "<leader>on", function() Snacks.notifier.show_history() end, desc = "Notification history" },
    { "<leader>od", function() Snacks.dashboard() end, desc = "Dashboard" },

    -- File / find --------------------------------------------------------
    { "<leader>ff", function() Snacks.picker.smart() end, desc = "Find files (smart)" },
    { "<leader>fF", function() Snacks.picker.files() end, desc = "Find files (all)" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Live grep" },
    { "<leader>fw", function() Snacks.picker.grep_word() end, desc = "Grep word / selection", mode = { "n", "x" } },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Neovim config files" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Help pages" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>fs", function() Snacks.picker.lsp_symbols() end, desc = "LSP symbols" },
    { "<leader>fS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP workspace symbols" },
    { "<leader>fu", function() Snacks.picker.undo() end, desc = "Undo history" },
    { "<leader>fC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    { "<leader>fR", function() Snacks.picker.resume() end, desc = "Resume last picker" },
    { "<leader>f/", function() Snacks.picker.lines() end, desc = "Search in buffer" },
    { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
    { "<leader>bb", function() Snacks.picker.buffers() end, desc = "List buffers" },

    -- Git ----------------------------------------------------------------
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git log" },
    { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git log (file)" },
    { "<leader>gt", function() Snacks.picker.git_status() end, desc = "Git status" },
    { "<leader>gO", function() Snacks.gitbrowse() end, desc = "Open in browser", mode = { "n", "v" } },

    -- Terminal -----------------------------------------------------------
    { "<c-\\>", function() Snacks.terminal(nil, { win = { position = "float" } }) end, desc = "Toggle terminal", mode = { "n", "t" } },
    { "<leader>tf", function() Snacks.terminal(nil, { win = { position = "float" } }) end, desc = "Float terminal" },
    { "<leader>th", function() Snacks.terminal(nil, { win = { position = "bottom", height = 15 } }) end, desc = "Horizontal terminal" },
    { "<leader>tv", function() Snacks.terminal(nil, { win = { position = "right", width = 60 } }) end, desc = "Vertical terminal" },
    { "<leader>tg", function() Snacks.lazygit() end, desc = "Lazygit" },

    -- Words under the cursor (LSP references) -------------------------------
    { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference", mode = { "n", "t" } },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Previous reference", mode = { "n", "t" } },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Toggles de UI: <leader>u*
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative number" }):map("<leader>uL")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal" }):map("<leader>uc")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle({
          name = "Auto-format (global)",
          get = function() return not vim.g.disable_autoformat end,
          set = function(state) vim.g.disable_autoformat = not state end,
        }):map("<leader>uf")
        vim.keymap.set("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss notifications" })
      end,
    })
  end,
}
