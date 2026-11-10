local function git_action(module, name)
  return function(...)
    return require("dotfiles.git." .. module)[name](...)
  end
end

local picker = require("dotfiles.picker").open

local function compare_branches(name)
  return {
    all = true,
    confirm = git_action("compare", name),
    transform = git_action("compare", "not_current"),
  }
end

local function review(command, label, diff)
  return function()
    require("dotfiles.git.review").expect(label, diff)
    vim.cmd(command)
  end
end

return {

  {
    "coder/claudecode.nvim",
    keys = {
      { "<leader>aD", git_action("claude", "send"), desc = "Send the changes to Claude" },
      {
        "<leader>aV",
        git_action("claude", "ask_review"),
        desc = "Ask Claude to review the changes",
      },
      {
        "<leader>aM",
        git_action("claude", "ask_message"),
        desc = "Ask Claude for a commit message",
      },
    },
  },

  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      { "<leader>gl", picker("git_log"), desc = "Git log (Enter reviews the commit)" },
      { "<leader>gt", picker("git_status"), desc = "Changed files" },
      {
        "<leader>gO",
        function()
          Snacks.gitbrowse()
        end,
        mode = { "n", "x" },
        desc = "Open in browser",
      },
      {
        "<leader>gvb",
        picker("git_branches", compare_branches("branch")),
        desc = "Compare with a branch",
      },
      {
        "<leader>gvf",
        picker("git_branches", compare_branches("file")),
        desc = "Compare this file with a branch",
      },
      { "<leader>gP", picker("gh_pr"), desc = "Review a pull request (pick it)" },
      {
        "<leader>gvo",
        git_action("pr", "comments"),
        desc = "Comments on this branch's pull request",
      },
    },
    opts = {
      lazygit = { enabled = true, win = require("dotfiles.float").win("Lazygit") },
      picker = {
        previewers = { diff = { wo = { wrap = false } } },
        sources = require("dotfiles.git.pickers").sources,
        actions = {
          confirm = function(this_picker, item, action)
            local win = require("dotfiles.git.jump").pick_win(this_picker, item)
            require("snacks.picker.actions").jump(this_picker, item, action)
            if win then
              vim.schedule(function()
                require("dotfiles.toggles").apply(win)
              end)
            end
          end,
        },
      },
    },
  },

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
        m("x", "<leader>gs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage hunk")
        m("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        m("x", "<leader>gr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset hunk")
        m("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
        m("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
        m("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        m("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame line")
        m("n", "<leader>gB", gs.blame, "Blame the whole file")
        m(
          "n",
          "<leader>gvs",
          git_action("compare", "toggle_marks"),
          "Toggle marks against the base branch"
        )
        m({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
      end,
    },
  },

  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    init = function()
      require("dotfiles.git").watch_diff()
    end,
    build = ":CodeDiff install",
    keys = {
      { "<leader>gV", git_action("compare", "origin"), desc = "Review branch vs origin" },
      {
        "<leader>gD",
        review("CodeDiff", "working tree", { "git", "diff", "HEAD" }),
        desc = "Review working tree",
      },
      {
        "<leader>gC",
        review("CodeDiff --staged", "staged", { "git", "diff", "--cached" }),
        desc = "Review staged changes",
      },
      {
        "<leader>gd",
        review("CodeDiff file HEAD", "this file vs HEAD", { "git", "diff", "HEAD", "--", "%" }),
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
      { "<leader>gvv", ":CodeDiff ", desc = "Compare revisions (type them)" },
      {
        "<leader>gvc",
        git_action("compare", "commits"),
        desc = "Review the branch commit by commit",
      },
      { "<leader>gq", git_action("review", "close"), desc = "Close the review" },
    },
    opts = {
      diff = { cycle_hunks_across_files = true, compute_moves = true },
      explorer = { auto_open_on_cursor = true, line_stats = { enabled = true } },
      keymaps = {
        view = {
          toggle_explorer = "<leader>op",
          focus_explorer = "<leader>gE",
          open_in_prev_tab = "gf",
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
          accept_all_incoming = false,
          accept_all_current = false,
          accept_all_both = false,
          discard_all = false,
        },
      },
    },
    config = function(_, opts)
      require("codediff").setup(opts)
      require("dotfiles.git").setup()
    end,
  },
}
