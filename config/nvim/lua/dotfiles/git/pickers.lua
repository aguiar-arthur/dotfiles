local M = {}

local function action(module, name)
  return function(...)
    return require("dotfiles.git." .. module)[name](...)
  end
end

local function keys(map)
  local out = {}
  for lhs, name in pairs(map) do
    out[lhs] = { name, mode = { "n", "i" } }
  end
  return { input = { keys = out } }
end

local layout = {
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

local log = {
  confirm = action("log", "commit"),
  layout = layout,
  actions = { review_worktree = action("log", "worktree") },
  win = keys({ ["<c-e>"] = "review_worktree" }),
}

M.sources = {
  git_status = { layout = layout },
  git_log = log,
  git_log_file = log,
  git_log_line = log,
  gh_pr = {
    confirm = action("pr", "review"),
    actions = {
      pr_menu = action("pr", "menu"),
      pr_hunks = action("pr", "hunks"),
      pr_since = action("pr", "since"),
    },
    win = keys({ ["<c-e>"] = "pr_menu", ["<c-o>"] = "pr_hunks", ["<c-l>"] = "pr_since" }),
  },
}

return M
