local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local buffers = require("dotfiles.buffers")
local compare = require("dotfiles.git.compare")
local jump = require("dotfiles.git.jump")
local log_actions = require("dotfiles.git.log")
local pr = require("dotfiles.git.pr")
local review = require("dotfiles.git.review")
local tabline = require("dotfiles.tabline")
require("dotfiles.git").setup()

local root = T.dir({
  ["src/a.py"] = {},
  ["src/b.py"] = {},
  ["src/c.py"] = {},
  ["src/d.py"] = {},
})

local function event(pattern, tab)
  vim.api.nvim_exec_autocmds("User", { pattern = pattern, data = { tabpage = tab } })
end

local function new_review()
  vim.cmd("$tabnew")
  local tab = vim.api.nvim_get_current_tabpage()
  event("CodeDiffOpen", tab)
  return tab
end

local function settle()
  vim.wait(10, function()
    return false
  end)
end

local function reset()
  settle()
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
  T.eq("git: a tab is not a review", review.is(), false)
  local review_tab = new_review()
  T.eq("git: CodeDiffOpen marks its tab a review", review.is(review_tab), true)
  T.eq("git: other tabs are not", review.is(first), false)
  event("CodeDiffClose", review_tab)
  T.eq("git: CodeDiffClose unmarks it", review.is(review_tab), false)
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
  T.eq("git: a file from a review opens in the tab before it", jump.edit_win(review_tab), editing)
  T.eq("git: and focus stays in the review", vim.api.nvim_get_current_win(), picker)
  vim.cmd.tabmove(0)
  local made = jump.edit_win(review_tab)
  T.eq(
    "git: a review in the first tab gets a tab before it",
    vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(made)),
    1
  )
  local second = new_review()
  made = jump.edit_win(second)
  T.eq("git: never a review's window", review.is(vim.api.nvim_win_get_tabpage(made)), false)
  T.eq(
    "git: but a new tab just before it",
    vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(made)) + 1,
    vim.api.nvim_tabpage_get_number(second)
  )

  vim.api.nvim_set_current_tabpage(first)
  vim.cmd("tabonly | only | enew")
  vim.bo.buftype = "nofile"
  review_tab = new_review()
  made = jump.edit_win(review_tab)
  T.eq("git: a tab with no file window gets a new tab after it", {
    vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(made)),
    #vim.api.nvim_list_tabpages(),
  }, { 2, 3 })
  vim.cmd("silent! tabonly")
end)

T.case("git: the focused window of the editing tab", function()
  reset()
  vim.cmd("edit " .. root .. "/src/a.py")
  vim.cmd("vsplit " .. root .. "/src/b.py")
  local focused = vim.api.nvim_get_current_win()
  local review_tab = new_review()
  T.eq(
    "git: a file from a review goes to the window that had the focus",
    jump.edit_win(review_tab),
    focused
  )
  vim.cmd("silent! tabonly")
end)

T.case("git: where a picked item goes", function()
  reset()
  vim.cmd("edit " .. root .. "/src/a.py")
  local editing = vim.api.nvim_get_current_win()
  T.eq("git: outside a review a pick stays put", jump.pick_win({ main = editing }, {}), nil)
  local review_tab = new_review()
  vim.cmd("edit " .. root .. "/src/c.py")
  local side = vim.api.nvim_get_current_win()
  local other = { file = root .. "/src/d.py" }

  local same = { main = side }
  T.eq(
    "git: the file the review shows stays in the review",
    { jump.pick_win(same, { file = root .. "/src/c.py" }), same.main },
    { nil, side }
  )
  T.eq(
    "git: so does an item of that buffer",
    jump.pick_win({ main = side }, { buf = vim.api.nvim_get_current_buf() }),
    nil
  )

  local open = { main = side, shown = true }
  T.eq("git: a listed pick goes to the editing tab", jump.pick_win(open, other), editing)
  T.eq(
    "git: its picker keeps the focus until it closes",
    { open.main, vim.api.nvim_get_current_win() },
    { editing, side }
  )

  local single = { main = side, shown = false }
  T.eq("git: a pick with one result goes there too", jump.pick_win(single, other), editing)
  T.eq(
    "git: and moves the focus, since no picker window will",
    vim.api.nvim_get_current_win(),
    editing
  )
  vim.api.nvim_set_current_tabpage(review_tab)
  vim.cmd("silent! tabonly")
end)

T.case("git: one review at a time", function()
  reset()
  local older = new_review()
  settle()
  T.eq("git: a review alone stays", review.is(older), true)
  local newer = new_review()
  settle()
  T.eq("git: a new review closes the one before", vim.api.nvim_tabpage_is_valid(older), false)
  T.eq("git: and stays", review.is(newer), true)
  vim.cmd("silent! tabonly")
end)

T.case("git: nothing misaligns the two sides of a review", function()
  local first = reset()
  event("CodeDiffClose", first)
  local markdown, context = require("render-markdown"), require("treesitter-context")
  vim.lsp.codelens.enable(true)
  vim.diagnostic.config({ virtual_lines = { current_line = true } })
  markdown.enable()
  context.enable()
  local function state()
    return {
      vim.lsp.codelens.is_enabled(),
      vim.diagnostic.config().virtual_lines,
      markdown.get(),
      context.enabled(),
    }
  end
  local before = state()
  local review_tab = new_review()
  T.eq("git: lenses, virtual lines, Markdown and context go off", state(), {
    false,
    false,
    false,
    false,
  })
  event("CodeDiffClose", review_tab)
  T.eq("git: the last review to close brings them back", state(), before)
  vim.lsp.codelens.enable(false)
  local off = new_review()
  event("CodeDiffClose", off)
  T.eq("git: what was off stays off", vim.lsp.codelens.is_enabled(), false)
  local loaded
  T.stub(require("lazy"), "load", function(opts)
    loaded = opts.plugins
  end)
  event("CodeDiffClose", new_review())
  T.eq(
    "git: a review loads the servers first, so their setup cannot turn lenses back on",
    loaded,
    { "nvim-lspconfig" }
  )
  vim.lsp.codelens.enable(true)
  vim.cmd("silent! tabonly")
end)

T.case("git: a native diff stays aligned too", function()
  local first = reset()
  event("CodeDiffClose", first)
  require("dotfiles.git").watch_diff()
  vim.lsp.codelens.enable(true)
  vim.cmd("edit " .. root .. "/src/a.py")
  local function open_diff()
    vim.cmd("diffthis")
    vim.cmd("vnew")
    vim.bo.buftype = "nofile"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "proposal" })
    vim.cmd("diffthis")
  end
  local function lens_becomes(state)
    vim.wait(300, function()
      return vim.lsp.codelens.is_enabled() == state
    end)
    return vim.lsp.codelens.is_enabled()
  end
  open_diff()
  T.eq("git: lenses go off with a diff, as Claude's proposals are", lens_becomes(false), false)
  vim.cmd("diffoff!")
  T.eq("git: and come back without one", lens_becomes(true), true)
  vim.cmd("only")
  open_diff()
  lens_becomes(false)
  vim.cmd("only")
  T.eq("git: closing its windows brings them back as well", lens_becomes(true), true)
  vim.cmd("diffoff!")
end)

T.case("git: a review has no path bar", function()
  reset()
  local windows = require("dotfiles.windows")
  vim.cmd("edit " .. root .. "/src/a.py")
  windows.enter(vim.api.nvim_get_current_win())
  T.eq("git: a file window outside a review has it", vim.wo.winbar, " %f%m")
  vim.cmd("$tabnew " .. root .. "/src/b.py")
  local side = vim.api.nvim_get_current_win()
  windows.enter(side)
  T.eq("git: a window that becomes a side has it at first", vim.wo[side].winbar, " %f%m")
  event("CodeDiffOpen", vim.api.nvim_get_current_tabpage())
  T.eq("git: CodeDiffOpen takes it away, it would push that side down", vim.wo[side].winbar, "")
  windows.enter(side)
  T.eq("git: and entering the side does not bring it back", vim.wo[side].winbar, "")
  T.eq("git: the side still gets the cursor line", vim.wo[side].cursorline, true)
  vim.cmd("silent! tabonly")
end)

T.case("git: the tab line", function()
  reset()
  vim.cmd("edit " .. root .. "/src/a.py")
  local line = function()
    return vim.api.nvim_eval_statusline(tabline.render(), { use_tabline = true }).str
  end
  T.eq("git: a tab shows its file", line(), " a.py ")
  review.expect("origin/main...")
  local review_tab = new_review()
  T.eq("git: a review shows what it compares", line(), " a.py  review: origin/main... ")
  event("CodeDiffClose", review_tab)
  vim.cmd("tabclose")
  vim.fn.histadd("cmd", "CodeDiff main HEAD~2")
  new_review()
  T.eq("git: or what was typed", line(), " a.py  review: main HEAD~2 ")
  vim.cmd("silent! tabonly")
  vim.fn.histadd("cmd", "echo")
  vim.t.review = nil
  vim.cmd("enew")
  T.eq("git: an empty tab has no file", line(), " [No Name] ")
  vim.cmd("edit " .. root .. "/src/a.py")
  local tab_float = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
    relative = "editor",
    row = 1,
    col = 1,
    width = 5,
    height = 1,
  })
  T.eq("git: a float in the tab does not rename it", line(), " a.py ")
  vim.api.nvim_win_close(tab_float, true)
  local plain_review = vim.api.nvim_get_current_tabpage()
  review.mark(plain_review, "explorer")
  T.eq("git: a plain :CodeDiff is the working tree", review.label(plain_review), "working tree")
  review.unmark(plain_review)
end)

T.case("git: Space g q", function()
  local first = reset()
  new_review()
  vim.api.nvim_set_current_tabpage(first)
  review.close()
  T.eq("git: Space g q before a review closes it", #vim.api.nvim_list_tabpages(), 1)
  new_review()
  review.close()
  T.eq("git: Space g q in a review closes it", #vim.api.nvim_list_tabpages(), 1)
  capture(review.close)
  T.eq("git: Space g q without a review says so", warned, "No review is open")
  event("CodeDiffOpen", vim.api.nvim_get_current_tabpage())
  review.close()
  T.eq(
    "git: Space g q on a review alone leaves a new tab",
    { #vim.api.nvim_list_tabpages(), review.is() },
    { 1, false }
  )
end)

T.case("git: a session is saved without its reviews", function()
  local kept = reset()
  for _ = 1, 2 do
    vim.cmd("$tabnew")
    vim.t.review = true
  end
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
  buffers.close_buffer()
  T.eq("git: Space b d in a review closes it", #vim.api.nvim_list_tabpages(), 1)
  local review_tab = new_review()
  vim.api.nvim_set_current_buf(file)
  vim.api.nvim_set_current_tabpage(first)
  vim.api.nvim_set_current_win(editing)
  capture(buffers.close_buffer)
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
  buffers.close_buffer()
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
    buffers.close_buffers("other")
  end)
  T.eq(
    "git: Space b o with a review open keeps every buffer",
    { warned, #closed },
    { "A review is open: close it first (Space g q)", 0 }
  )
  vim.api.nvim_set_current_tabpage(review_tab)
  review.close()
  buffers.close_buffers("other")
  buffers.close_buffers("all")
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
  local chosen = {}
  local log_picker = {
    close = function()
      closed = true
    end,
    selected = function()
      return chosen
    end,
  }
  log_actions.commit(log_picker, { commit = head, cwd = log })
  T.eq(
    "git: Enter in a log picker reviews the commit against its parent",
    { closed, reviewed },
    { true, { root_commit, head } }
  )
  log_actions.commit(log_picker, { commit = root_commit, cwd = log })
  T.eq(
    "git: the first commit against the empty tree",
    reviewed,
    { "4b825dc642cb6eb9a060e54bf8d69288fbee4904", root_commit }
  )
  chosen = { { commit = head, idx = 1 }, { commit = root_commit, idx = 2 } }
  log_actions.commit(log_picker, { commit = head, cwd = log })
  T.eq("git: two selected commits compare, the older first", reviewed, { root_commit, head })
  chosen = {}
  log_actions.worktree(log_picker, { commit = head })
  T.eq("git: C-e in a log picker compares it with the working tree", reviewed, { head })
  for _, source in ipairs({ "git_log", "git_log_file", "git_log_line" }) do
    T.eq(
      "git: " .. source .. " never checks a commit out",
      type(require("snacks.picker.config").get({ source = source }).confirm),
      "function"
    )
  end
end)

T.case("git: comparing with a branch or a pull request", function()
  local ran, closed
  T.stub(vim.cmd, "CodeDiff", function(...)
    ran = { ... }
  end)
  local picker = {
    close = function()
      closed = true
    end,
  }
  compare.branch(picker, { branch = "main" })
  T.eq("git: Enter compares with the branch's fork point", { closed, ran }, { true, { "main..." } })
  compare.branch(picker, { commit = "abc" })
  T.eq("git: a detached item by its commit", ran, { "abc..." })
  compare.file(picker, { branch = "main" })
  T.eq("git: this file against a branch", ran, { "file", "main" })
  pr.review(picker, { number = 42 })
  T.eq("git: a picked pull request", ran, { "pr", "42" })
  ran = nil
  compare.branch(picker, nil)
  compare.file(picker, nil)
  pr.review(picker, nil)
  T.eq("git: no item compares nothing", ran, nil)
  review.expect(nil)
end)

T.case("git: the pull request picker keys", function()
  local closed = 0
  local picker = {
    close = function()
      closed = closed + 1
    end,
  }
  local opened = {}
  T.stub(Snacks.picker, "gh_diff", function(opts)
    opened.diff = opts
  end)
  T.stub(Snacks.picker, "gh_actions", function(opts)
    opened.menu = opts
  end)
  pr.hunks(picker, nil)
  pr.menu(picker, nil)
  T.eq("git: an empty list does nothing", { closed, opened.diff, opened.menu }, { 0, nil, nil })
  local item = { number = 7, repo = "o/r" }
  pr.hunks(picker, item)
  T.eq("git: C-o opens its hunks and comments", opened.diff, { pr = 7, repo = "o/r" })
  pr.menu(picker, item)
  T.eq("git: C-e opens its actions", opened.menu, { item = item })
  T.eq("git: and each closes the list", closed, 2)
end)

T.case("git: this branch's pull request", function()
  local said
  T.stub(vim, "notify", function(msg)
    said = msg
  end)
  T.stub(vim.fn, "executable", function()
    return 0
  end)
  pr.comments()
  T.eq("git: no gh says so", said, "gh is not installed")
  T.stub(vim.fn, "executable", function()
    return 1
  end)
  local answer
  T.stub(vim, "system", function(_, _, done)
    done(answer)
  end)
  local opened
  T.stub(Snacks.picker, "gh_diff", function(opts)
    opened = opts
  end)
  answer = { code = 1, stdout = "" }
  pr.comments()
  vim.wait(200, function()
    return said == "This branch has no pull request"
  end)
  T.eq("git: no pull request says so", said, "This branch has no pull request")
  answer = { code = 0, stdout = '{"number":9}' }
  pr.comments()
  vim.wait(200, function()
    return opened ~= nil
  end)
  T.eq("git: its number opens the hunks and comments", opened and opened.pr, 9)
end)

T.case("git: a review's label", function()
  reset()
  review.expect("working tree")
  vim.fn.histadd("cmd", "CodeDiff main...")
  local after_failed = new_review()
  T.eq(
    "git: a key whose review never opened leaves no label to the next one",
    review.label(after_failed),
    "main..."
  )
  vim.cmd("silent! tabonly")
end)

T.case("git: how much of a review was seen", function()
  reset()
  local explorer = require("dotfiles.git.explorer")
  local tab = new_review()
  explorer.clear(tab)
  T.eq("git: a review with no file list has no progress", explorer.progress(tab), nil)
  explorer.record({ name = "Changes", files = { { path = "a" }, { path = "b" } } })
  explorer.record({ name = "Staged Changes", files = { { path = "a" } } })
  T.eq("git: a file in two groups counts once", explorer.progress(tab), "0/2 seen")
  for _, path in ipairs({ "a", "a" }) do
    vim.api.nvim_exec_autocmds("User", {
      pattern = "CodeDiffFileSelect",
      data = { tabpage = tab, path = path },
    })
  end
  T.eq("git: a file seen twice counts once", explorer.progress(tab), "1/2 seen")
  T.eq(
    "git: the tab line shows it",
    vim.api
      .nvim_eval_statusline(tabline.render(), { use_tabline = true }).str
      :find("1/2 seen", 1, true) ~= nil,
    true
  )
  vim.cmd("$tabnew")
  local next_tab = vim.api.nvim_get_current_tabpage()
  explorer.record({ name = "Changes", files = { { path = "c" } } })
  event("CodeDiffOpen", next_tab)
  event("CodeDiffClose", tab)
  T.eq("git: closing the review forgets it", explorer.progress(tab), nil)
  T.eq(
    "git: the review that replaced it keeps its own count",
    explorer.progress(next_tab),
    "0/1 seen"
  )
  vim.cmd("silent! tabonly")
end)

T.case("git: ignoring whitespace in reviews", function()
  local function ignoring()
    return require("codediff.config").options.diff.ignore_trim_whitespace
  end
  capture(function()
    require("dotfiles.git.view").toggle_whitespace()
  end)
  T.eq("git: the key turns it on and says so", { ignoring(), warned ~= nil }, {
    true,
    true,
  })
  require("dotfiles.git.view").toggle_whitespace()
  T.eq("git: and off again", ignoring(), false)
end)

T.case("git: the picker keys reach Snacks", function()
  local function key(source, lhs)
    return require("snacks.picker.config").get({ source = source }).win.input.keys[lhs]
  end
  local both = { "n", "i" }
  T.eq("git: C-e and C-o in the pull request picker, C-e in the log pickers", {
    key("gh_pr", "<C-E>"),
    key("gh_pr", "<C-O>"),
    key("git_log_file", "<C-E>"),
  }, {
    { "pr_menu", mode = both },
    { "pr_hunks", mode = both },
    { "review_worktree", mode = both },
  })
  T.eq(
    "git: the status picker uses the tall layout",
    require("snacks.picker.config").get({ source = "git_status" }).layout.layout.height,
    0.9
  )
end)

T.case("git: a branch picker leaves the current branch out", function()
  T.eq("git: the current branch goes", compare.not_current({ current = true }), false)
  T.eq("git: the others stay", compare.not_current({ branch = "x" }), nil)
end)

T.case("git: the base branch for the compare keys", function()
  vim.cmd("enew")
  local dir = T.dir()
  vim.fn.system(
    ("cd %s && git init -q -b main origin && cd origin && git -c user.name=t -c user.email=t@t "):format(
      dir
    ) .. "commit -q --allow-empty -m x && cd .. && git clone -q origin work 2>/dev/null"
  )
  vim.fn.chdir(dir .. "/work")
  local ran
  T.stub(vim.cmd, "CodeDiff", function(...)
    ran = { ... }
  end)
  compare.commits()
  T.eq("git: the branch commit by commit", ran, { "history", "origin/main..HEAD" })
  local gitsigns = require("gitsigns")
  local base, reset_base
  T.stub(gitsigns, "change_base", function(rev, global)
    base = { rev, global }
  end)
  T.stub(gitsigns, "reset_base", function(global)
    reset_base = global
  end)
  T.stub(vim, "notify", function() end)
  compare.toggle_marks()
  local fork = vim.trim(vim.fn.system({ "git", "merge-base", "origin/main", "HEAD" }))
  T.eq("git: the marks against the fork point", base, { fork, true })
  compare.toggle_marks()
  T.eq("git: and back", reset_base, true)
  review.expect(nil)
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
    compare.origin()
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
  compare.origin()
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
