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
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function m(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buf, silent = true, desc = desc })
        end
        local function hunk(lhs, direction)
          return function()
            if vim.wo.diff then
              vim.cmd.normal({ lhs, bang = true })
            elseif
              not (package.loaded.codediff and require("codediff")[direction .. "_hunk"]())
            then
              gs.nav_hunk(direction)
            end
          end
        end
        m("n", "]c", hunk("]c", "next"), "Next git hunk")
        m("n", "[c", hunk("[c", "prev"), "Previous git hunk")
        m("n", "<leader>gs", gs.stage_hunk, "Stage/unstage hunk")
        m("v", "<leader>gs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage hunk")
        m("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        m("v", "<leader>gr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset hunk")
        m("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
        m("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
        m("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        m("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame line")
        m("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle line blame")
        m({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
      end,
    },
  },

  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    build = ":CodeDiff install",
    keys = {
      {
        "<leader>gV",
        function()
          require("dotfiles.git").review_vs_origin()
        end,
        desc = "Review branch vs origin",
      },
      { "<leader>gD", "<cmd>CodeDiff<CR>", desc = "Review working tree" },
      { "<leader>gC", "<cmd>CodeDiff --staged<CR>", desc = "Review staged changes" },
      { "<leader>gd", "<cmd>CodeDiff file HEAD<CR>", desc = "Review this file against HEAD" },
      { "<leader>gh", "<cmd>CodeDiff history %<CR>", desc = "File history (review)" },
      { "<leader>gL", "<cmd>.CodeDiff history<CR>", desc = "Line history (review)" },
      { "<leader>gL", ":CodeDiff history<CR>", mode = "x", desc = "Lines history (review)" },
      { "<leader>gP", ":CodeDiff pr ", desc = "Review a pull request (number)" },
      {
        "<leader>gq",
        function()
          require("dotfiles.git").close_review()
        end,
        desc = "Close the review",
      },
    },
    opts = {
      keymaps = {
        view = {
          toggle_explorer = { "<leader>ge", "<leader>op" },
          focus_explorer = "<leader>gE",
          open_in_prev_tab = { "gf", "<leader>gf" },
          toggle_stage = "<leader>ga",
          stage_hunk = false,
          unstage_hunk = "<leader>gu",
          discard_hunk = false,
          toggle_layout = "<leader>gi",
          toggle_compact = "<leader>gz",
        },
        conflict = {
          accept_incoming = "<leader>gmt",
          accept_current = "<leader>gmo",
          accept_both = "<leader>gmb",
          discard = "<leader>gmx",
          accept_all_incoming = "<leader>gmT",
          accept_all_current = "<leader>gmO",
          accept_all_both = "<leader>gmB",
          discard_all = "<leader>gmX",
        },
      },
    },
    config = function(_, opts)
      require("codediff").setup(opts)
      require("dotfiles.git").setup()
    end,
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote flash",
      },
      {
        "<c-s>",
        mode = "c",
        function()
          require("flash").toggle()
        end,
        desc = "Toggle flash search",
      },
    },
  },

  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" } },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          u = ai.gen_spec.function_call(),
        },
      }
    end,
  },

  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
    keys = {
      {
        "<leader>r",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Replace in project",
      },
      { "<leader>r", ":GrugFar<CR>", mode = "x", desc = "Replace selection in project" },
    },
  },

  {
    "nvim-mini/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    },
  },

  {
    "nvim-mini/mini.pairs",
    event = "VeryLazy",
    opts = {
      modes = { insert = true, command = true, terminal = false },

      mappings = { ["`"] = false },
    },
  },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next todo",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous todo",
      },
      {
        "<leader>dt",
        function()
          Snacks.picker.todo_comments()
        end,
        desc = "Todos (project)",
      },
    },
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      {
        "<leader>Sr",
        function()
          require("persistence").load()
        end,
        desc = "Restore session (cwd)",
      },
      {
        "<leader>Sl",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore last session",
      },
      {
        "<leader>Ss",
        function()
          require("persistence").select()
        end,
        desc = "Select session",
      },
      {
        "<leader>Sd",
        function()
          require("persistence").stop()
        end,
        desc = "Don't save this session",
      },
    },
  },
}
