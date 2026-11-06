local function git_call(module, name)
  return function()
    require("dotfiles.git." .. module)[name]()
  end
end

local function review(command, label)
  return function()
    require("dotfiles.git.review").expect(label)
    vim.cmd(command)
  end
end

return {

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      attach_to_untracked = true,
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
        m("n", "<leader>gI", gs.preview_hunk_inline, "Preview hunk inline")
        m("n", "<leader>gw", function()
          gs.toggle_word_diff(gs.toggle_linehl())
        end, "Toggle changed lines and words in the buffer")
        m("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame line")
        m("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle line blame")
        m("n", "<leader>gA", gs.blame, "Blame the whole file")
        m(
          "n",
          "<leader>gvs",
          git_call("compare", "toggle_marks"),
          "Toggle marks against the base branch"
        )
        m({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
      end,
    },
  },

  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    build = ":CodeDiff install",
    keys = {
      { "<leader>gV", git_call("compare", "origin"), desc = "Review branch vs origin" },
      { "<leader>gD", review("CodeDiff", "working tree"), desc = "Review working tree" },
      { "<leader>gC", review("CodeDiff --staged", "staged"), desc = "Review staged changes" },
      {
        "<leader>gd",
        review("CodeDiff file HEAD", "this file vs HEAD"),
        desc = "Review this file against HEAD",
      },
      {
        "<leader>gh",
        review("CodeDiff history %", "file history"),
        desc = "File history (review)",
      },
      {
        "<leader>gL",
        review(".CodeDiff history", "line history"),
        desc = "Line history (review)",
      },
      {
        "<leader>gL",
        function()
          require("dotfiles.git.review").expect("lines history")
          return ":CodeDiff history<CR>"
        end,
        mode = "x",
        expr = true,
        desc = "Lines history (review)",
      },
      { "<leader>gP", ":CodeDiff pr ", desc = "Review a pull request (number)" },
      { "<leader>gvv", ":CodeDiff ", desc = "Compare revisions (type them)" },
      {
        "<leader>gvc",
        git_call("compare", "commits"),
        desc = "Review the branch commit by commit",
      },
      { "<leader>gvl", git_call("log", "line_commit"), desc = "Review the commit of this line" },
      { "<leader>gq", git_call("review", "close"), desc = "Close the review" },
    },
    opts = {
      diff = { cycle_hunks_across_files = true, compute_moves = true },
      explorer = { auto_open_on_cursor = true, line_stats = { enabled = true } },
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
          align_move = "<leader>gM",
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
