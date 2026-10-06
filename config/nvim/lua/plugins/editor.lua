return {

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      current_line_blame = true,
      current_line_blame_opts = { virt_text_pos = "eol", delay = 500 },
      preview_config = { border = "rounded" },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function m(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buf, silent = true, desc = desc })
        end
        m("n", "]c", function()
          if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
        end, "Next git hunk")
        m("n", "[c", function()
          if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
        end, "Previous git hunk")
        m("n", "<leader>gs", gs.stage_hunk, "Stage/unstage hunk")
        m("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk")
        m("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        m("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset hunk")
        m("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
        m("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
        m("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        m("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        m("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle line blame")
        m("n", "<leader>gd", gs.diffthis, "Diff this")
        m({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
      end,
    },
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    init = function()

      vim.api.nvim_create_autocmd("BufFilePost", {
        group = vim.api.nvim_create_augroup("user_diffview_no_lsp", { clear = true }),
        pattern = "diffview://*",
        callback = function(ev)
          if vim.bo[ev.buf].buftype == "" then vim.bo[ev.buf].buftype = "acwrite" end
        end,
      })
    end,
    keys = {
      {
        "<leader>gv",
        function()
          if next(require("diffview.lib").views) then vim.cmd("DiffviewClose") else vim.cmd("DiffviewOpen") end
        end,
        desc = "Diff view (toggle)",
      },
      { "<leader>gV", "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<CR>", desc = "Diff view: branch vs origin" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
      { "<leader>gh", ":DiffviewFileHistory<CR>", mode = "x", desc = "History of selection" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Repo history" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = { merge_tool = { layout = "diff3_mixed" } },
      keymaps = {
        view = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diff view" } } },
        file_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diff view" } } },
        file_history_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diff view" } } },
      },
    },
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
      { "<c-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle flash search" },
    },
  },

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = function()
      local function h() return require("harpoon") end
      local keys = {
        { "<leader>ma", function() h():list():add() end, desc = "Add file (harpoon)" },
        { "<leader>mm", function() h().ui:toggle_quick_menu(h():list()) end, desc = "Harpoon menu" },
        { "<leader>mn", function() h():list():next() end, desc = "Harpoon next" },
        { "<leader>mp", function() h():list():prev() end, desc = "Harpoon previous" },
      }
      for i = 1, 5 do
        keys[#keys + 1] = { "<leader>m" .. i, function() h():list():select(i) end, desc = "Harpoon file " .. i }
      end
      return keys
    end,
  },

  { "echasnovski/mini.ai", event = "VeryLazy", opts = { n_lines = 500 } },

  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "gsa", delete = "gsd", find = "gsf", find_left = "gsF",
        highlight = "gsh", replace = "gsr", update_n_lines = "gsn",
      },
    },
  },

  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    opts = {
      modes = { insert = true, command = true, terminal = false },

      mappings = { ["`"] = false },
    },
    config = function(_, opts)
      require("mini.pairs").setup(opts)
      local function md_backtick(buf)
        require("mini.pairs").map_buf(buf, "i", "`", {
          action = "closeopen", pair = "``", neigh_pattern = "[^\\`].", register = { cr = false },
        })
      end
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(ev) md_backtick(ev.buf) end,
      })
      if vim.bo.filetype == "markdown" then md_backtick(0) end
    end,
  },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo" },
      { "<leader>dt", "<cmd>Trouble todo toggle<CR>", desc = "Todos (project)" },
    },
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>dx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
      { "<leader>dd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Document diagnostics" },
      { "<leader>ds", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols (Trouble)" },
      { "<leader>dl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
      { "<leader>dq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
    },
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>Sr", function() require("persistence").load() end, desc = "Restore session (cwd)" },
      { "<leader>Sl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>Ss", function() require("persistence").select() end, desc = "Select session" },
      { "<leader>Sd", function() require("persistence").stop() end, desc = "Don't save this session" },
    },
  },
}
