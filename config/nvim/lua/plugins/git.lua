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
      current_line_blame = false,
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
}
