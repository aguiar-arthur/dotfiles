local function git_call(module, name)
  return function()
    require("dotfiles.git." .. module)[name]()
  end
end

local function git_action(module, name)
  return function(...)
    return require("dotfiles.git." .. module)[name](...)
  end
end

local function picker(name, opts)
  return function()
    Snacks.picker[name](opts)
  end
end

local function compare_branches(name)
  return {
    all = true,
    confirm = git_action("compare", name),
    transform = git_action("compare", "not_current"),
  }
end

local git_layout = {
  layout = {
    backdrop = 60,
    width = 0.92,
    height = 0.9,
    box = "vertical",
    border = true,
    title = "{title} {live} {flags}",
    title_pos = "center",
    { win = "input", height = 1, border = "bottom" },
    { win = "list", height = 0.3, border = "none" },
    { win = "preview", title = "{preview}", border = "top" },
  },
}

local git_log = {
  confirm = git_action("log", "commit"),
  layout = git_layout,
  actions = { review_worktree = git_action("log", "worktree") },
  win = { input = { keys = { ["<c-e>"] = { "review_worktree", mode = { "n", "i" } } } } },
}

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
      { "<leader>gc", picker("git_diff"), desc = "Changes (hunks)" },
      {
        "<leader>gO",
        function()
          Snacks.gitbrowse()
        end,
        mode = { "n", "v" },
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
      { "<leader>gvh", git_action("compare", "hunks"), desc = "Hunks of the whole branch" },
      { "<leader>gvp", picker("gh_pr"), desc = "Pick a pull request" },
      {
        "<leader>gvo",
        git_action("pr", "comments"),
        desc = "Comments on this branch's pull request",
      },
      { "<leader>gvk", git_action("pr", "checks"), desc = "Checks of this branch's pull request" },
      { "<leader>gvz", picker("git_stash"), desc = "Review a stash" },
    },
    opts = {
      lazygit = { enabled = true, win = require("dotfiles.float").win("Lazygit") },
      picker = {
        previewers = { diff = { wo = { wrap = false } } },
        sources = {
          git_diff = { layout = git_layout },
          git_status = { layout = git_layout },
          git_log = git_log,
          git_log_file = git_log,
          git_log_line = git_log,
          git_stash = {
            confirm = git_action("log", "stash"),
            win = { input = { keys = { ["<c-e>"] = { "git_stash_apply", mode = { "n", "i" } } } } },
          },
          gh_pr = {
            confirm = git_action("pr", "review"),
            actions = { pr_menu = git_action("pr", "menu"), pr_hunks = git_action("pr", "hunks") },
            win = {
              input = {
                keys = {
                  ["<c-e>"] = { "pr_menu", mode = { "n", "i" } },
                  ["<c-o>"] = { "pr_hunks", mode = { "n", "i" } },
                },
              },
            },
          },
        },
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
    init = function()
      require("dotfiles.git").watch_diff()
    end,
    build = ":CodeDiff install",
    keys = {
      { "<leader>gV", git_call("compare", "origin"), desc = "Review branch vs origin" },
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
