local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local git = require("dotfiles.git")
git.setup()

local root = T.dir({ ["src/a.py"] = {} })

local function event(pattern, tab)
  vim.api.nvim_exec_autocmds("User", { pattern = pattern, data = { tabpage = tab } })
end

local function new_review()
  vim.cmd("$tabnew")
  local tab = vim.api.nvim_get_current_tabpage()
  event("CodeDiffOpen", tab)
  return tab
end

local function reset()
  vim.cmd("silent! tabonly")
  vim.cmd("silent! only")
  vim.cmd("enew")
  vim.t.review = nil
  return vim.api.nvim_get_current_tabpage()
end

local warned
local function capture(fn)
  warned = nil
  T.stub(vim, "notify", function(msg)
    warned = msg
  end)
  fn()
end

T.case("git: the review variable", function()
  local first = reset()
  T.eq("git: a tab is not a review", git.review(), false)
  local review_tab = new_review()
  T.eq("git: CodeDiffOpen marks its tab a review", git.review(review_tab), true)
  T.eq("git: other tabs are not", git.review(first), false)
  event("CodeDiffClose", review_tab)
  T.eq("git: CodeDiffClose unmarks it", git.review(review_tab), false)
  vim.cmd("silent! tabonly")
end)

T.case("git: the editing tab", function()
  local first = reset()
  vim.cmd("edit " .. root .. "/src/a.py")
  local editing = vim.api.nvim_get_current_win()
  vim.cmd("vsplit | enew")
  vim.bo.buftype = "nofile"
  local review_tab = new_review()
  local picker = vim.api.nvim_get_current_win()
  T.eq("git: a file from a review opens in the tab before it", git.edit_win(review_tab), editing)
  T.eq("git: and focus stays in the review", vim.api.nvim_get_current_win(), picker)
  vim.cmd.tabmove(0)
  local made = git.edit_win(review_tab)
  T.eq(
    "git: a review in the first tab gets a tab before it",
    vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(made)),
    1
  )
  local second = new_review()
  made = git.edit_win(second)
  T.eq("git: never a review's window", git.review(vim.api.nvim_win_get_tabpage(made)), false)
  T.eq(
    "git: but a new tab just before it",
    vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(made)) + 1,
    vim.api.nvim_tabpage_get_number(second)
  )

  vim.api.nvim_set_current_tabpage(first)
  vim.cmd("tabonly | only | enew")
  vim.bo.buftype = "nofile"
  review_tab = new_review()
  made = git.edit_win(review_tab)
  T.eq("git: a tab with no file window gets a new tab after it", {
    vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(made)),
    #vim.api.nvim_list_tabpages(),
  }, { 2, 3 })
  vim.cmd("silent! tabonly")
end)

T.case("git: Space g q", function()
  local first = reset()
  new_review()
  vim.api.nvim_set_current_tabpage(first)
  git.close_review()
  T.eq("git: Space g q before a review closes it", #vim.api.nvim_list_tabpages(), 1)
  new_review()
  git.close_review()
  T.eq("git: Space g q in a review closes it", #vim.api.nvim_list_tabpages(), 1)
  capture(git.close_review)
  T.eq("git: Space g q without a review says so", warned, "No review is open")
  event("CodeDiffOpen", vim.api.nvim_get_current_tabpage())
  git.close_review()
  T.eq(
    "git: Space g q on a review alone leaves a new tab",
    { #vim.api.nvim_list_tabpages(), git.review() },
    { 1, false }
  )
end)

T.case("git: a session is saved without its reviews", function()
  local kept = reset()
  new_review()
  new_review()
  require("lazy").load({ plugins = { "persistence.nvim" } })
  vim.api.nvim_exec_autocmds("User", { pattern = "PersistenceSavePre" })
  T.eq("git: saving a session closes every review first", vim.api.nvim_list_tabpages(), { kept })
end)

T.case("git: Space b d, Space b o and Space b D", function()
  local first = reset()
  vim.cmd("edit " .. root .. "/src/a.py")
  local file, editing = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()

  new_review()
  vim.api.nvim_set_current_buf(file)
  git.close_buffer()
  T.eq("git: Space b d in a review closes it", #vim.api.nvim_list_tabpages(), 1)
  local review_tab = new_review()
  vim.api.nvim_set_current_buf(file)
  vim.api.nvim_set_current_tabpage(first)
  vim.api.nvim_set_current_win(editing)
  capture(git.close_buffer)
  T.eq(
    "git: Space b d on a file a review shows keeps it",
    { warned, vim.api.nvim_win_get_buf(editing) },
    { "A review shows this file: close the review first (Space g q)", file }
  )
  vim.cmd("enew")
  local other = vim.api.nvim_get_current_buf()
  local deleted
  T.stub(Snacks, "bufdelete", function()
    deleted = vim.api.nvim_get_current_buf()
  end)
  git.close_buffer()
  T.eq("git: Space b d on another file deletes it", deleted, other)
  local closed = {}
  T.stub(Snacks, "bufdelete", {
    other = function()
      table.insert(closed, "other")
    end,
    all = function()
      table.insert(closed, "all")
    end,
  })
  capture(function()
    git.close_buffers("other")
  end)
  T.eq(
    "git: Space b o with a review open keeps every buffer",
    { warned, #closed },
    { "A review is open: close it first (Space g q)", 0 }
  )
  vim.api.nvim_set_current_tabpage(review_tab)
  git.close_review()
  git.close_buffers("other")
  git.close_buffers("all")
  T.eq("git: Space b o / Space b D close the other / all buffers", closed, { "other", "all" })
  vim.cmd("silent! tabonly")
end)

T.case("git: Enter in the log pickers", function()
  local log = T.dir()
  local function lg(...)
    return vim.trim(vim.system({ "git", "-C", log, ... }, { text = true }):wait().stdout)
  end
  lg("init", "-q")
  lg("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "one")
  local root_commit = lg("rev-parse", "HEAD")
  lg("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "two")
  local head = lg("rev-parse", "HEAD")
  local closed, reviewed
  T.stub(vim.cmd, "CodeDiff", function(...)
    reviewed = { ... }
  end)
  local log_picker = {
    close = function()
      closed = true
    end,
  }
  git.review_commit(log_picker, { commit = head, cwd = log })
  T.eq(
    "git: Enter in a log picker reviews the commit against its parent",
    { closed, reviewed },
    { true, { root_commit, head } }
  )
  git.review_commit(log_picker, { commit = root_commit, cwd = log })
  T.eq(
    "git: the first commit against the empty tree",
    reviewed,
    { "4b825dc642cb6eb9a060e54bf8d69288fbee4904", root_commit }
  )
  for _, source in ipairs({ "git_log", "git_log_file", "git_log_line" }) do
    T.eq(
      "git: " .. source .. " never checks a commit out",
      type(require("snacks.picker.config").get({ source = source }).confirm),
      "function"
    )
  end
end)

T.case("git: the review base branch", function()
  vim.cmd("enew")
  local base
  T.stub(vim.cmd, "CodeDiff", function(arg)
    base = arg
  end)
  local function repo(branch, keep_head)
    local dir = T.dir()
    local sh = (
      "cd %s && git init -q -b %s origin && cd origin && git -c user.name=t -c user.email=t@t "
      .. "commit -q --allow-empty -m x && cd .. && git clone -q origin work 2>/dev/null"
    ):format(dir, branch)
    vim.fn.system(sh)
    if not keep_head then
      vim.fn.system({ "git", "-C", dir .. "/work", "remote", "set-head", "origin", "-d" })
    end
    vim.fn.chdir(dir .. "/work")
    base = nil
    git.review_vs_origin()
  end
  repo("trunk", true)
  T.eq("git: origin/HEAD comes first", base, "origin/trunk...")
  repo("main", false)
  T.eq("git: then origin/main", base, "origin/main...")
  repo("master", false)
  T.eq("git: then origin/master", base, "origin/master...")
  repo("main", false)
  vim.cmd("edit " .. vim.fn.getcwd() .. "/f.txt")
  vim.fn.chdir(T.dir())
  base = nil
  git.review_vs_origin()
  T.eq("git: the base comes from the file's repository", base, "origin/main...")
  vim.cmd("enew")
  local said
  T.stub(vim, "notify", function(msg)
    said = msg
  end)
  repo("trunk", false)
  T.eq(
    "git: no base branch says so",
    base == nil and said,
    "No origin/HEAD, origin/main or origin/master"
  )
end)

T.done()
