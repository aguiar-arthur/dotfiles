local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local buffers = require("dotfiles.buffers")
local compare = require("dotfiles.git.compare")
local jump = require("dotfiles.git.jump")
local log_actions = require("dotfiles.git.log")
local pr = require("dotfiles.git.pr")
local review = require("dotfiles.git.review")
local reviewed = require("dotfiles.git.reviewed")
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
  review.close_all()
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

local session = require("dotfiles.git.session")

local function git_repo(dir)
  vim.fn.system({ "git", "init", "-q", "-b", "main", dir })
  return function(...)
    local command = { "git", "-C", dir, "-c", "user.name=t", "-c", "user.email=t@t", ... }
    return vim.trim(vim.system(command, { text = true }):wait().stdout)
  end
end

local function write(dir, files)
  for path, line in pairs(files) do
    vim.fn.mkdir(vim.fs.dirname(dir .. "/" .. path), "p")
    vim.fn.writefile({ line }, dir .. "/" .. path)
  end
end

local function real_review(dir, ...)
  local cwd = vim.fn.getcwd()
  local before = vim.api.nvim_get_current_tabpage()
  vim.cmd.cd(dir)
  vim.cmd({ cmd = "CodeDiff", args = { ... } })
  vim.wait(5000, function()
    local tab = vim.api.nvim_get_current_tabpage()
    return tab ~= before and session.current(tab) ~= nil
  end)
  vim.cmd.cd(cwd)
  return vim.api.nvim_get_current_tabpage()
end

local function collapse_folders(tab)
  local tree = require("codediff.ui.lifecycle").get_panel(tab).view.tree
  local function walk(ids)
    for _, id in ipairs(ids) do
      local node = tree:get_node(id)
      walk(node:get_child_ids() or {})
      if node.data and node.data.type == "directory" then
        node:collapse()
      end
    end
  end
  walk(vim.tbl_map(function(node)
    return node:get_id()
  end, tree:get_nodes()))
  tree:render()
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
  local picked
  T.stub(require("dotfiles.git.reviewed"), "review", function(number)
    picked = number
  end)
  pr.review(picker, { number = 42 })
  T.eq("git: a picked pull request", picked, 42)
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
  local since
  T.stub(require("dotfiles.git.reviewed"), "since", function(number)
    since = number
  end)
  pr.since(picker, nil)
  T.eq("git: C-l on an empty list does nothing", { since, closed }, { nil, 2 })
  pr.since(picker, item)
  T.eq("git: C-l reviews what changed since the last review", since, 7)
  T.eq("git: and each closes the list", closed, 3)
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
  T.eq("git: a review that is not of a pull request has none", review.pr(after_failed), nil)
  vim.fn.histadd("cmd", "CodeDiff pr 7")
  T.eq("git: a typed :CodeDiff pr is one", review.pr(new_review()), { number = 7 })
  vim.cmd("silent! tabonly")
end)

T.case("git: how much of a review was seen", function()
  reset()
  local explorer = require("dotfiles.git.explorer")
  T.eq(
    "git: a tab with no file list has no progress",
    explorer.progress(vim.api.nvim_get_current_tabpage()),
    nil
  )
  local dir = T.dir()
  local git = git_repo(dir)
  write(dir, { a = "a", b = "b", ["d/c"] = "c" })
  git("add", ".")
  git("commit", "-qm", "one")
  write(dir, { a = "a2", b = "b2", ["d/c"] = "c2" })
  git("commit", "-qam", "two")
  local tab = real_review(dir, "HEAD~1", "HEAD")
  T.eq("git: the file a review opens on is not seen until left", explorer.progress(tab), "0/3 seen")
  local opened = session.current(tab).path
  local other = vim.iter(session.files(tab)):find(function(file)
    return file.path ~= opened
  end)
  session.select(tab, other)
  session.select(tab, other)
  T.eq("git: leaving it counts it, once", explorer.progress(tab), "1/3 seen")
  T.eq(
    "git: the tab line shows it",
    vim.api
      .nvim_eval_statusline(tabline.render(), { use_tabline = true }).str
      :find("1/3 seen", 1, true) ~= nil,
    true
  )
  local next_tab = real_review(dir, "HEAD~1", "HEAD")
  vim.wait(2000, function()
    return explorer.progress(next_tab) == "1/3 seen"
  end)
  T.eq("git: closing the review forgets its tab", explorer.progress(tab), nil)
  T.eq(
    "git: the same review opened again remembers the file read",
    explorer.progress(next_tab),
    "1/3 seen"
  )
  vim.cmd("silent! tabonly")
end)

T.case("git: what a review of your branch shows", function()
  reset()
  local explorer = require("dotfiles.git.explorer")
  local dir = T.dir()
  local git = git_repo(dir)
  write(dir, { a = "a", b = "b" })
  git("add", ".")
  git("commit", "-qm", "one")
  git("update-ref", "refs/remotes/origin/main", "HEAD")
  write(dir, { a = "a2", b = "b2" })
  local fork = git("rev-parse", "HEAD")
  local function open()
    review.expect("origin/main...")
    local tab = real_review(dir, "origin/main...")
    vim.wait(5000, function()
      return #session.hunks(tab) > 0
    end)
    settle()
    return tab
  end
  local tab = open()
  local original, modified = session.windows(tab)
  local bars = require("dotfiles.git.bars")
  T.eq(
    "git: both sides have the bar",
    { vim.wo[original].winbar, vim.wo[modified].winbar },
    { bars.bar, bars.bar }
  )
  local function bar(win)
    local options = { winid = win, use_winbar = true, maxwidth = 200 }
    return vim.api.nvim_eval_statusline(vim.wo[win].winbar, options).str
  end
  T.eq(
    "git: the old side says it is the fork point, and which hunk",
    bar(original),
    " old fork point of origin/main @ " .. fork:sub(1, 7) .. "  hunk 1/1"
  )
  T.eq(
    "git: the new side says it is the working tree",
    bar(modified),
    " new working tree  hunk 1/1"
  )
  local first = session.current(tab).path
  local second = first == "a" and "b" or "a"
  local function row(path)
    local buf = require("codediff.ui.lifecycle").get_panel(tab).view.bufnr
    return vim.iter(vim.api.nvim_buf_get_lines(buf, 0, -1, false)):find(function(line)
      return line:find(" " .. path .. " ", 1, true) ~= nil
    end) or ""
  end
  T.eq("git: a file not read has no mark", row(first):find("✓", 1, true), nil)
  session.select(
    tab,
    vim.iter(session.files(tab)):find(function(file)
      return file.path == second
    end)
  )
  T.eq("git: a file read is checked in the list", row(first):find("✓", 1, true) ~= nil, true)
  local buf = vim.fn.bufadd(session.revisions(tab).root .. "/" .. second)
  vim.fn.bufload(buf)
  local ns = vim.api.nvim_create_namespace("test_review_errors")
  vim.diagnostic.set(ns, buf, {
    { lnum = 0, col = 0, message = "x", severity = vim.diagnostic.severity.ERROR },
  })
  vim.wait(1000, function()
    return row(second):find("✗1", 1, true) ~= nil
  end)
  T.eq("git: a file with errors shows how many", row(second):find("✗1", 1, true) ~= nil, true)
  vim.diagnostic.reset(ns, buf)

  review.close_all()
  settle()
  tab = open()
  vim.wait(2000, function()
    return explorer.progress(tab) == "1/2 seen"
  end)
  T.eq("git: reopened, the file read is still read", explorer.progress(tab), "1/2 seen")
  review.close_all()
  settle()
  write(dir, { [first] = "changed again" })
  tab = open()
  settle()
  vim.wait(500, function()
    return false
  end)
  T.eq("git: until its diff changes", explorer.progress(tab), "0/2 seen")
  review.close_all()
  settle()
end)

T.case("git: folds, scope, totals, hiding and the hunk picker", function()
  reset()
  local explorer = require("dotfiles.git.explorer")
  local hunks = require("dotfiles.git.hunks")
  local dir = T.dir()
  local git = git_repo(dir)
  local lines = { "local function parse()" }
  for i = 2, 29 do
    lines[i] = ("  local v%d = %d"):format(i, i)
  end
  lines[30] = "end"
  vim.fn.writefile(lines, dir .. "/r.lua")
  write(dir, { b = "b" })
  git("add", ".")
  git("commit", "-qm", "one")
  git("update-ref", "refs/remotes/origin/main", "HEAD")
  lines[15] = "  local v15 = 150"
  vim.fn.writefile(lines, dir .. "/r.lua")
  write(dir, { b = "b2" })
  review.expect("origin/main...")
  local tab = real_review(dir, "origin/main...")
  local file = function(path)
    return vim.iter(session.files(tab)):find(function(found)
      return found.path == path
    end)
  end
  T.eq(
    "git: the tab line totals the review",
    explorer.summary(tab),
    "+2 −2  ▱▱▱▱▱ 0/2 seen"
  )
  if session.current(tab).path ~= "r.lua" then
    session.select(tab, file("r.lua"))
  end
  local _, modified = session.windows(tab)
  vim.wait(5000, function()
    local side = session.side(vim.api.nvim_win_get_buf(modified), tab)
    return side
      and side.path == "r.lua"
      and vim.api.nvim_win_call(modified, function()
          return vim.fn.foldclosed(1)
        end)
        ~= -1
  end)
  T.eq(
    "git: unchanged code is folded into one quiet line",
    vim.api.nvim_win_call(modified, function()
      return vim.fn.foldtextresult(1)
    end),
    "  ··· 11 unchanged lines ···"
  )
  vim.api.nvim_set_current_win(modified)
  vim.api.nvim_win_set_cursor(modified, { 15, 0 })
  settle()
  T.eq(
    "git: the bar names the function around the cursor",
    vim.api.nvim_eval_statusline(vim.wo[modified].winbar, {
      winid = modified,
      use_winbar = true,
      maxwidth = 200,
    }).str,
    " new working tree · parse  hunk 1/1"
  )

  local listed
  hunks.list(tab, function(found)
    listed = found
  end)
  vim.wait(5000, function()
    return listed ~= nil
  end)
  T.eq(
    "git: every hunk of the review, where it starts and in which function",
    vim.tbl_map(function(hunk)
      return { hunk.path, hunk.line, hunk.side, hunk.scope, hunk.first }
    end, listed),
    {
      { "b", 1, "original", "", "b" },
      { "r.lua", 15, "original", "local function parse()", "local v15 = 15" },
    }
  )
  local opened
  T.stub(Snacks.picker, "pick", function(opts)
    opened = opts
  end)
  hunks.pick()
  vim.wait(5000, function()
    return opened ~= nil
  end)
  T.eq("git: Space g H lists them with a diff preview", {
    #opened.items,
    opened.items[2].preview.ft,
  }, { 2, "diff" })
  opened.confirm({ close = function() end }, opened.items[1])
  T.eq(
    "git: and Enter opens the file at the hunk",
    { session.current(tab).path, vim.api.nvim_win_get_cursor(0)[1] },
    { "b", 1 }
  )

  session.select(tab, file("r.lua"))
  T.eq("git: both files were left, so read", explorer.progress(tab), "2/2 seen")
  capture(function()
    explorer.toggle_read()
  end)
  T.eq("git: Space g x hides the files read and says so", {
    warned,
    vim.tbl_map(function(found)
      return found.path
    end, session.files(tab)),
  }, { "Hiding the 1 files read", { "r.lua" } })
  T.eq("git: hidden files still count", explorer.summary(tab), "+2 −2  ▰▰▰▰▰ 2/2 seen")
  capture(function()
    explorer.toggle_read()
  end)
  T.eq("git: and shows them again", { warned, #session.files(tab) }, { "Showing every file", 2 })
  explorer.toggle_read()
  review.close_all()
  settle()
  T.eq(
    "git: closing a review that hid files gives codediff its filter back",
    require("codediff.config").options.explorer.file_filter.ignore[1],
    ".git/**"
  )
  T.eq("git: a hunk after a file without a final newline is still read", #hunks.parse(table.concat({
    "diff --git a/x b/x",
    "--- a/x",
    "+++ b/x",
    "@@ -1 +1 @@",
    "-a",
    "\\ No newline at end of file",
    "+b",
  }, "\n")), 1)
end)

T.case("git: Space g V fetches its base", function()
  local dir = T.dir()
  local origin, work = dir .. "/origin", dir .. "/work"
  local upstream = git_repo(origin)
  write(origin, { a = "a" })
  upstream("add", ".")
  upstream("commit", "-qm", "one")
  vim.fn.system({ "git", "clone", "-q", origin, work })
  local mine = git_repo(work)
  local old = mine("rev-parse", "origin/main")
  write(origin, { b = "b" })
  upstream("add", ".")
  upstream("commit", "-qm", "two")
  local new = upstream("rev-parse", "HEAD")
  mine("pull", "-q", "--ff-only")
  mine("update-ref", "refs/remotes/origin/main", old)
  local said
  T.stub(vim, "notify", function(msg)
    said = msg
  end)
  compare.refresh_base("origin/main", work)
  vim.wait(5000, function()
    return said ~= nil
  end)
  T.eq(
    "git: a fork point that moved with the fetch says so",
    said,
    ("origin/main moved: this branch now forks from %s, not %s; Space g V again reviews against it"):format(
      new:sub(1, 7),
      old:sub(1, 7)
    )
  )
  said = nil
  compare.refresh_base("origin/main", work)
  vim.wait(1000, function()
    return said ~= nil
  end)
  T.eq("git: an up to date base says nothing", said, nil)
end)

T.case("git: what of a pull request was reviewed", function()
  reset()
  local dir = T.dir()
  local origin, work = dir .. "/o/r", dir .. "/work"
  local function at(repo_dir, ...)
    return vim.trim(vim.system({ "git", "-C", repo_dir, ... }, { text = true }):wait().stdout)
  end
  local function commit(branch, file, line)
    at(origin, "switch", "-q", branch)
    vim.fn.writefile({ line }, origin .. "/" .. file)
    at(origin, "add", file)
    at(origin, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", line)
    return at(origin, "rev-parse", "HEAD")
  end
  local function merge_ref()
    local tree = at(origin, "merge-tree", "--write-tree", "main", "pr"):match("^%x+")
    local merge = at(origin, "commit-tree", tree, "-p", "main", "-p", "pr", "-m", "merge")
    at(origin, "update-ref", "refs/pull/7/merge", merge)
  end
  local function publish(with_merge)
    at(origin, "update-ref", "refs/pull/7/head", "pr")
    if with_merge then
      merge_ref()
    else
      at(origin, "update-ref", "-d", "refs/pull/7/merge")
    end
    at(origin, "switch", "-q", "main")
    return at(origin, "rev-parse", "pr")
  end
  local function rebase_pr(...)
    at(origin, "switch", "-q", "pr")
    local args = { "-c", "user.name=t", "-c", "user.email=t@t", "rebase", "-q", ... }
    at(origin, unpack(vim.list_extend(args, { "main" })))
  end
  vim.fn.system({ "git", "init", "-q", "-b", "main", origin })
  vim.fn.writefile({ "c" }, origin .. "/c")
  commit("main", "a", "a")
  at(origin, "switch", "-q", "-c", "pr")
  local first = commit("pr", "a", "a reviewed")
  publish()
  vim.fn.system({ "git", "clone", "-q", origin, work })
  local github
  T.stub(reviewed, "target", function(_, _, _, done)
    done(github)
  end)
  local ran, said
  local warnings = {}
  T.stub(vim.cmd, "CodeDiff", function(...)
    ran = { ... }
  end)
  T.stub(vim, "notify", function(msg, level)
    said = msg
    if level == vim.log.levels.WARN then
      warnings[#warnings + 1] = msg
    end
  end)
  local function run(fn, ...)
    ran, said, warnings = nil, nil, {}
    fn(...)
    vim.wait(5000, function()
      return ran ~= nil or (said ~= nil and not said:find("caught up", 1, true))
    end)
  end
  local function sha(name)
    return at(work, "rev-parse", "refs/pr-review/7/" .. name)
  end
  local function head()
    return at(origin, "rev-parse", "pr")
  end
  local function changed(from)
    return at(work, "diff", "--name-only", from, head())
  end
  local function open(fn, ...)
    run(fn, ...)
    return real_review(work, unpack(ran))
  end
  local function finish(tab)
    said = nil
    reviewed.mark(tab)
    vim.wait(5000, function()
      return said ~= nil
    end)
    vim.cmd("silent! tabonly")
  end

  local plain = new_review()
  reviewed.mark(plain)
  settle()
  T.eq(
    "git: a review that is not of a pull request records nothing",
    at(work, "for-each-ref", "refs/pr-review/*/reviewed"),
    ""
  )
  vim.cmd("silent! tabonly")
  github = { baseRefName = "main", headRefOid = first }
  local tab = open(reviewed.review, 7, work .. "/")
  T.eq(
    "git: Enter reviews the head against its fork point on the target branch, by commit",
    ran,
    { at(origin, "rev-parse", "main") .. "..." .. first }
  )
  T.eq(
    "git: codediff's fetch keeps its refs in its own namespace",
    at(work, "rev-parse", "refs/codediff/pull-requests/origin/7/head"),
    first
  )
  commit("pr", "b", "b")
  publish()
  run(reviewed.fetch, 7, work, nil, function() end)
  finish(tab)
  T.eq(
    "git: a complete review records the head it showed, not one fetched since",
    { sha("reviewed"), said },
    { first, "PR #7 reviewed up to " .. first:sub(1, 7) }
  )

  github = nil
  tab = open(reviewed.since, 7, work)
  T.eq(
    "git: without gh and with no merge ref, the base is the remote's default branch",
    ran,
    { first, head() }
  )
  T.eq("git: and shows only the push", changed(first), "b")
  finish(tab)

  commit("main", "c", "c from main")
  rebase_pr()
  commit("pr", "b", "b again")
  publish(true)
  github = { headRefOid = head() }
  tab = open(reviewed.since, 7, work)
  T.eq(
    "git: with a merge ref, after a rebase what was reviewed is replayed on the new base",
    ran,
    { sha("replayed"), head() }
  )
  T.eq("git: so the base's changes stay out", changed("refs/pr-review/7/replayed"), "b")
  T.eq("git: the naive diff would have shown them", changed("refs/pr-review/7/reviewed"), "b\nc")
  T.eq("git: a fresh merge ref warns of nothing", warnings, {})
  finish(tab)

  local shown = head()
  commit("pr", "e", "e")
  at(origin, "update-ref", "refs/pull/7/head", "pr")
  github = { baseRefName = "main", headRefOid = head() }
  run(reviewed.review, 7, work)
  T.eq(
    "git: a merge ref GitHub has not updated yet shows its own head, consistently",
    ran,
    { at(origin, "rev-parse", "main") .. "..." .. shown }
  )
  T.eq(
    "git: and says the last push is missing",
    warnings,
    { "PR #7: GitHub has not caught up with its last push, this shows " .. shown:sub(1, 7) }
  )
  at(origin, "reset", "-q", "--hard", "pr~1")
  publish(true)

  local before = head()
  commit("main", "d", "d from main")
  rebase_pr()
  local rebased = publish()
  github = { baseRefName = "main" }
  run(reviewed.since, 7, work)
  vim.wait(5000, function()
    return sha("reviewed") == rebased
  end)
  T.eq(
    "git: a rebase with no edit opens nothing and moves the record to the new head",
    { ran, said, sha("reviewed") },
    { nil, "Nothing new in PR #7 since " .. before:sub(1, 7), rebased }
  )
  run(reviewed.since, 7, work)
  T.eq("git: so the next C-l has nothing new", ran, nil)

  commit("main", "b", "b from main")
  rebase_pr("-X", "theirs")
  commit("pr", "a", "a last")
  publish()
  run(reviewed.since, 7, work)
  T.eq("git: a replay that conflicts falls back to the two heads", ran, { sha("reviewed"), head() })
  T.eq(
    "git: and says so",
    warnings,
    { "PR #7: what you reviewed does not apply to the new base, so the base's changes show too" }
  )

  at(origin, "branch", "release", "main~1")
  github = { baseRefName = "release" }
  run(reviewed.review, 7, work)
  T.eq(
    "git: a pull request into another branch forks from it",
    ran,
    { at(origin, "merge-base", "release", "pr") .. "..." .. head() }
  )
  github = { baseRefName = "main" }
  at(work, "remote", "rename", "origin", "upstream")
  at(work, "remote", "add", "origin", dir .. "/fork")
  run(reviewed.review, 7, work, "O/R")
  T.eq("git: it is fetched from the remote of its repository", { ran ~= nil, said }, { true, nil })
  run(reviewed.review, 7, work)
  T.eq(
    "git: else from origin, and says why it failed",
    said:find("^Could not fetch PR #7: .*'origin'") ~= nil,
    true
  )

  run(reviewed.since, 8, work)
  T.eq(
    "git: a pull request never reviewed has no since",
    { ran, said },
    { nil, "PR #8 was never reviewed to the end here" }
  )
  run(reviewed.review, 9, work, "o/r")
  T.eq(
    "git: a pull request that is not on the remote opens nothing",
    { ran, said },
    { nil, "Could not fetch PR #9: Pull request #9 was not found on remote 'upstream'" }
  )
  run(reviewed.review, 7, dir)
  T.eq(
    "git: nor does one asked outside a repository",
    { ran, said },
    { nil, "Could not fetch PR #7" }
  )
  T.stub(reviewed, "NETWORK_TIMEOUT_MS", 50)
  T.stub(require("codediff.core.pull_request"), "fetch", function() end)
  local late
  run(reviewed.fetch, 7, work, "o/r", function(pr)
    late = pr
  end)
  T.eq(
    "git: a fetch that never answers gives up",
    { late, said },
    { nil, "Could not fetch PR #7: no answer in 0.05 s" }
  )
  review.expect(nil)
  vim.cmd("silent! tabonly")
end)

T.case("git: what we read of codediff's own modules", function()
  reset()
  T.eq(
    "git: codediff's pull request fetch is still there",
    type(require("codediff.core.pull_request").fetch),
    "function"
  )
  local dir = T.dir()
  local git = git_repo(dir)
  write(dir, { a = "a", ["d/c"] = "c" })
  git("add", ".")
  git("commit", "-qm", "one")
  write(dir, { a = "a2", ["d/c"] = "c2" })
  git("commit", "-qam", "two")
  git("remote", "add", "origin", "git@github.com:o/r.git")
  local tab = real_review(dir, "HEAD~1", "HEAD")
  local old, new = git("rev-parse", "HEAD~1"), git("rev-parse", "HEAD")
  local revisions = session.revisions(tab)
  T.eq(
    "git: the revisions and repository a review shows",
    { revisions.root, revisions.base, revisions.target },
    { git("rev-parse", "--show-toplevel"), old, new }
  )
  collapse_folders(tab)
  local paths = vim.tbl_map(function(file)
    return file.path
  end, session.files(tab))
  table.sort(paths)
  T.eq("git: every file of the list, also in a collapsed folder", paths, { "a", "d/c" })
  local other = vim.iter(session.files(tab)):find(function(file)
    return file.path ~= session.current(tab).path
  end)
  session.select(tab, other)
  T.eq("git: selecting a file", session.current(tab).path, other.path)
  local original_win = require("codediff.ui.lifecycle").get_windows(tab)
  vim.wait(5000, function()
    local side = session.side(vim.api.nvim_win_get_buf(original_win))
    return side and side.path == other.path
  end)
  vim.api.nvim_set_current_win(original_win)
  T.eq("git: the side under the cursor", session.side(vim.api.nvim_get_current_buf()), {
    root = revisions.root,
    path = other.path,
    revision = old,
  })
  local url
  T.stub(vim.ui, "open", function(opened)
    url = opened
  end)
  require("dotfiles.git.view").browse()
  T.eq(
    "git: Space g O on a side opens that commit's file at the line",
    url,
    ("https://github.com/o/r/blob/%s/%s#L1-L1"):format(old, other.path)
  )
  vim.cmd("silent! tabonly")
end)

T.case("git: the next file not seen and a complete review", function()
  reset()
  local explorer = require("dotfiles.git.explorer")
  local dir = T.dir()
  local git = git_repo(dir)
  write(dir, { a = "a", b = "b", ["d/c"] = "c" })
  git("add", ".")
  git("commit", "-qm", "one")
  write(dir, { a = "a2", b = "b2" })
  git("add", ".")
  write(dir, { a = "a3", b = "b3", ["d/c"] = "c2" })
  local tab = real_review(dir)
  collapse_folders(tab)
  local marked
  T.stub(reviewed, "mark", function(t)
    marked = t
  end)
  local visited = { session.current(tab).path }
  for _, seen in ipairs({ "1/3 seen", "2/3 seen" }) do
    explorer.next_unseen()
    visited[#visited + 1] = session.current(tab).path
    T.eq("git: ]u counts the file it leaves", explorer.progress(tab), seen)
  end
  table.sort(visited)
  T.eq(
    "git: and lands on files not seen, past the second group and into a collapsed folder",
    visited,
    { "a", "b", "d/c" }
  )
  T.eq("git: the review is not complete while its last file is open", marked, nil)
  capture(function()
    explorer.next_unseen()
  end)
  T.eq("git: ]u on the last file completes the review", warned, "Review complete: 3/3 seen")
  T.eq("git: and records the review's tab", marked, tab)
  capture(function()
    explorer.next_unseen()
  end)
  T.eq("git: with every file seen ]u says so", warned, "Every file of this review was seen")
  review.close_all()
  settle()
  capture(function()
    explorer.next_unseen()
  end)
  T.eq("git: outside a review ]u says so", warned, "Not in a review with a file list")
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
  T.eq("git: C-e, C-o and C-l in the pull request picker, C-e in the log pickers", {
    key("gh_pr", "<C-E>"),
    key("gh_pr", "<C-O>"),
    key("gh_pr", "<C-L>"),
    key("git_log_file", "<C-E>"),
  }, {
    { "pr_menu", mode = both },
    { "pr_hunks", mode = both },
    { "pr_since", mode = both },
    { "review_worktree", mode = both },
  })
  local queue = vim.iter(T.config("plugins/git.lua")[1].keys):find(function(k)
    return k[1] == "<leader>gn"
  end)
  local opened
  T.stub(Snacks.picker, "gh_pr", function(opts)
    opened = opts
  end)
  queue[2]()
  T.eq(
    "git: Space g n lists the pull requests waiting on my review",
    opened.search,
    "review-requested:@me"
  )
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
