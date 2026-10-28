local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local python = require("dotfiles.python")
local root = T.dir({ ["src/a.py"] = {}, [".venv/bin/python"] = { "#!/bin/sh" } })
vim.fn.setfperm(root .. "/.venv/bin/python", "rwxr-xr-x")
T.case("python path", function()
  vim.cmd("edit " .. root .. "/src/a.py")
  T.stub(vim.env, "VIRTUAL_ENV", "/elsewhere")
  T.eq("python: the project's .venv comes first", python.path(), root .. "/.venv/bin/python")
  vim.cmd("edit " .. T.dir({ ["b.py"] = {} }) .. "/b.py")
  T.eq("python: then $VIRTUAL_ENV", python.path(), "/elsewhere/bin/python")
  vim.env.VIRTUAL_ENV = nil
  T.eq("python: then python3", python.path(), vim.fn.exepath("python3"))
  T.stub(vim.env, "PATH", "/nonexistent")
  T.eq(
    "python: without python3 on PATH, the bare name (never an empty command)",
    python.path(),
    "python3"
  )
end)

T.case("mason", function()
  local mason = require("dotfiles.mason")
  local settings = { mason_tools = { "shellcheck" }, mason_servers = { "lua_ls" } }
  T.eq(
    "mason: servers become package names",
    mason.wanted(settings),
    { "shellcheck", "lua-language-server" }
  )
  T.stub(package.loaded, "mason-registry", {
    get_installed_package_names = function()
      return { "shellcheck" }
    end,
  })
  local packages = T.dir({
    ["shellcheck/venv/bin/activate"] = {},
    ["ruff/venv/bin/python"] = {},
    ["taplo/bin/taplo"] = {},
  })
  vim.fn.setfperm(packages .. "/ruff/venv/bin/python", "rwxr-xr-x")
  T.eq(
    "mason: lists what is not installed",
    mason.missing(settings, T.dir()),
    { "lua-language-server" }
  )
  T.eq("mason: a venv without its Python is broken", mason.broken(packages), { shellcheck = true })
  T.eq(
    "mason: a broken package counts as missing, so install reinstalls it",
    mason.missing(settings, packages),
    { "shellcheck", "lua-language-server" }
  )
end)

T.case("clojure-lsp", function()
  local clojure_lsp = dofile(vim.fn.stdpath("config") .. "/after/lsp/clojure_lsp.lua")
  local clojure = T.dir({ ["deps.edn"] = {}, ["src/a.clj"] = { "(ns a)" } })
  local function clojure_root(file)
    local root = "not started"
    vim.cmd("edit " .. file)
    clojure_lsp.root_dir(vim.api.nvim_get_current_buf(), function(dir)
      root = dir
    end)
    return root
  end
  T.eq(
    "clojure-lsp: a Clojure file gets its project root",
    vim.uv.fs_realpath(clojure_root(clojure .. "/src/a.clj")),
    vim.uv.fs_realpath(clojure)
  )
  T.eq("clojure-lsp: Conjure's log buffers start no server", {
    clojure_root(clojure .. "/conjure-log-123.cljc"),
    clojure_root(clojure .. "/conjure-log-dev.cljc"),
  }, { "not started", "not started" })

  local function range(line, from, to)
    return { start = { line = line, character = from }, ["end"] = { line = line, character = to } }
  end
  local function clojure_calls(method, calls)
    local client = {
      request = function(_, _, _, handler)
        handler(nil, calls, {})
      end,
    }
    clojure_lsp.on_init(client)
    local got
    client:request(method, {}, function(_, result)
      got = result
    end)
    return got[1]
  end
  local outgoing = clojure_calls("callHierarchy/outgoingCalls", {
    {
      fromRanges = {},
      to = {
        uri = "zipfile:///c.jar::clojure/string.clj",
        range = range(206, 14, 24),
        selectionRange = range(4, 3, 17),
      },
    },
  })
  local incoming = clojure_calls("callHierarchy/incomingCalls", {
    {
      fromRanges = {},
      from = { uri = "file:///a.clj", range = range(6, 6, 12), selectionRange = range(7, 3, 9) },
    },
  })
  T.eq("clojure-lsp: an outgoing call opens the callee, an incoming call its call site", {
    outgoing.to.selectionRange,
    outgoing.fromRanges,
    incoming.from.selectionRange,
    incoming.fromRanges,
  }, { range(206, 14, 24), { range(4, 3, 17) }, range(6, 6, 12), { range(7, 3, 9) } })
  local spec = {
    fromRanges = { range(1, 0, 3) },
    to = { range = range(9, 0, 3), selectionRange = range(9, 0, 3) },
  }
  T.eq(
    "clojure-lsp: a reply that already follows the spec is kept",
    clojure_calls("callHierarchy/outgoingCalls", { vim.deepcopy(spec) }),
    spec
  )
end)

T.case("Clojure jack-in", function()
  local jack_in = require("dotfiles.clojure")
  local function repl(files)
    local cmd = jack_in.repl_command(T.dir(files))
    return cmd and cmd[1]
  end
  T.eq("clojure: deps.edn starts clojure", repl({ ["deps.edn"] = {}, ["bb.edn"] = {} }), "clojure")
  T.eq("clojure: project.clj starts lein", repl({ ["project.clj"] = {}, ["bb.edn"] = {} }), "lein")
  T.eq(
    "clojure: bb.edn alone starts Babashka on a free port",
    jack_in.repl_command(T.dir({ ["bb.edn"] = {} })),
    { "bb", "nrepl-server", "0" }
  )
  T.eq("clojure: no project file, no command", repl({}), nil)
end)

T.case("spell files", function()
  local install = require("dotfiles.install")
  local spell = T.dir()
  local files = install.spell_files({ "en_us", "pt_br" }, spell)
  T.eq("spell: only non-English files are fetched", #files, 1)
  T.eq(
    "spell: pt_br comes from the Vim mirror",
    files[1] and files[1].url:match("pt%.utf%-8%.spl$") ~= nil,
    true
  )
  vim.fn.writefile({}, spell .. "/pt.utf-8.spl")
  T.eq("spell: a file already there is skipped", install.spell_files({ "pt_br" }, spell), {})
end)

local git = require("dotfiles.git")
git.setup()
T.case("git: reviews, Space g q and Space b d", function()
  local function event(pattern, tab)
    vim.api.nvim_exec_autocmds("User", { pattern = pattern, data = { tabpage = tab } })
  end
  local function new_review()
    vim.cmd("$tabnew")
    local tab = vim.api.nvim_get_current_tabpage()
    event("CodeDiffOpen", tab)
    return tab
  end
  local warned
  local function capture(fn)
    warned = nil
    T.stub(vim, "notify", function(msg)
      warned = msg
    end)
    fn()
  end

  local first = vim.api.nvim_get_current_tabpage()
  T.eq("git: a tab is not a review", git.review(), false)
  local review_tab = new_review()
  T.eq("git: CodeDiffOpen marks its tab a review", git.review(review_tab), true)
  T.eq("git: other tabs are not", git.review(first), false)
  event("CodeDiffClose", review_tab)
  T.eq("git: CodeDiffClose unmarks it", git.review(review_tab), false)
  event("CodeDiffOpen", review_tab)

  vim.api.nvim_set_current_tabpage(first)
  vim.cmd("edit " .. root .. "/src/a.py")
  local file, editing = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.cmd("vsplit | enew")
  vim.bo.buftype = "nofile"
  vim.api.nvim_set_current_tabpage(review_tab)
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
  vim.api.nvim_set_current_tabpage(first)
  vim.cmd("tabonly")
  review_tab = new_review()
  vim.api.nvim_set_current_tabpage(first)
  git.close_review()
  T.eq("git: Space g q before a review closes it", #vim.api.nvim_list_tabpages(), 1)
  new_review()
  git.close_review()
  T.eq("git: Space g q in a review closes it", #vim.api.nvim_list_tabpages(), 1)
  capture(git.close_review)
  T.eq("git: Space g q without a review says so", warned, "No review is open")
  local kept = vim.api.nvim_get_current_tabpage()
  new_review()
  new_review()
  require("lazy").load({ plugins = { "persistence.nvim" } })
  vim.api.nvim_exec_autocmds("User", { pattern = "PersistenceSavePre" })
  T.eq("git: saving a session closes every review first", vim.api.nvim_list_tabpages(), { kept })
  vim.api.nvim_set_current_tabpage(kept)
  vim.cmd("silent! tabonly")
  event("CodeDiffOpen", vim.api.nvim_get_current_tabpage())
  git.close_review()
  T.eq(
    "git: Space g q on a review alone leaves a new tab",
    { #vim.api.nvim_list_tabpages(), git.review() },
    { 1, false }
  )
  first = vim.api.nvim_get_current_tabpage()
  editing = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_buf(file)

  review_tab = new_review()
  vim.api.nvim_set_current_buf(file)
  git.close_buffer()
  T.eq("git: Space b d in a review closes it", #vim.api.nvim_list_tabpages(), 1)
  review_tab = new_review()
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
  vim.cmd("tabonly")
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

T.case("treesitter parsers", function()
  local treesitter = require("dotfiles.treesitter")
  T.stub(package.loaded, "nvim-treesitter", {
    get_installed = function()
      return { "lua", "bash" }
    end,
  })
  T.eq("treesitter: lists the parsers not installed", treesitter.missing({ "lua", "rust", "go" }), {
    "rust",
    "go",
  })
  T.eq("treesitter: none when all are there", treesitter.missing({ "bash" }), {})
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

T.case("the float style", function()
  local float = require("dotfiles.float").win("Claude")
  T.eq("float: the same style everywhere", {
    float.position,
    float.border,
    float.title,
    float.backdrop,
  }, { "float", "rounded", " Claude ", 60 })
end)

T.case("Claude: the last session", function()
  local sent, opened = {}, {}
  local active = nil
  T.stub(package.loaded, "claudecode.terminal", {
    get_active_terminal_bufnr = function()
      return active
    end,
    toggle_open_no_focus = function(_, args)
      opened[#opened + 1] = args
      active = 1
    end,
  })
  vim.api.nvim_create_user_command("ClaudeCodeSend", function()
    sent[#sent + 1] = "send"
  end, {})
  vim.api.nvim_create_user_command("ClaudeCodeAdd", function(o)
    sent[#sent + 1] = "add " .. o.args
  end, { nargs = "*" })
  require("dotfiles.claude").in_last_session("ClaudeCodeSend")
  T.eq(
    "claude: no session opens the last one, then runs the command",
    { opened, sent },
    { { "--continue" }, { "send" } }
  )
  require("dotfiles.claude").in_last_session("ClaudeCodeAdd foo")
  T.eq(
    "claude: a running session is only given the command",
    { opened, sent },
    { { "--continue" }, { "send", "add foo" } }
  )
end)

T.case("Claude: notices out of sight", function()
  local claude = require("dotfiles.claude")
  claude.watch()
  local term_buf = vim.api.nvim_create_buf(false, true)
  local chan = vim.api.nvim_open_term(term_buf, {})
  T.stub(package.loaded, "claudecode.terminal", {
    get_active_terminal_bufnr = function()
      return term_buf
    end,
  })
  local notes = {}
  T.stub(vim, "notify", function(msg, level, opts)
    notes[#notes + 1] = { msg, level, opts.title }
  end)
  vim.api.nvim_chan_send(chan, "\27]9;needs you\7")
  vim.wait(300)
  T.eq(
    "claude: a message from the terminal that is out of sight is notified",
    notes,
    { { "needs you", vim.log.levels.INFO, "Claude" } }
  )
  vim.api.nvim_chan_send(chan, "\27]9;4;1;50\7")
  vim.wait(300)
  T.eq("claude: progress sequences are ignored", #notes, 1)
  vim.api.nvim_exec_autocmds("TermClose", { buffer = term_buf, data = { pos = 0 } })
  T.eq(
    "claude: an exit out of sight is notified",
    notes[2],
    { "Claude exited", vim.log.levels.WARN, "Claude" }
  )
  vim.api.nvim_set_current_buf(term_buf)
  vim.api.nvim_chan_send(chan, "\27]9;seen\7")
  vim.api.nvim_exec_autocmds("TermClose", { buffer = term_buf, data = { pos = 0 } })
  vim.wait(300)
  T.eq("claude: nothing is notified while the terminal is in view", #notes, 2)
  vim.cmd("enew")
end)

T.case("the dashboard's q", function()
  local function qmap(buf)
    return vim.api.nvim_buf_call(buf, function()
      return vim.fn.maparg("q", "n", false, true).rhs
    end)
  end
  local dash = vim.api.nvim_create_buf(false, true)
  vim.bo[dash].filetype = "snacks_dashboard"
  local dash_win = vim.api.nvim_open_win(
    dash,
    false,
    { relative = "editor", row = 1, col = 1, width = 20, height = 5 }
  )
  vim.keymap.set("n", "q", "<cmd>qa<CR>", { buffer = dash })
  vim.api.nvim_exec_autocmds("User", { pattern = "SnacksDashboardUpdatePost" })
  T.eq("dashboard: q closes a floating dashboard instead of quitting", qmap(dash), "<cmd>bd<CR>")
  vim.api.nvim_win_close(dash_win, true)
  local main = vim.api.nvim_create_buf(false, true)
  vim.bo[main].filetype = "snacks_dashboard"
  vim.api.nvim_set_current_buf(main)
  vim.keymap.set("n", "q", "<cmd>qa<CR>", { buffer = main })
  vim.api.nvim_exec_autocmds("User", { pattern = "SnacksDashboardUpdatePost" })
  T.eq("dashboard: q still quits the start dashboard", qmap(main), "<cmd>qa<CR>")
end)

T.case("LSP progress", function()
  require("dotfiles.progress").setup()
  local shown = {}
  vim.api.nvim_create_autocmd("Progress", {
    callback = function(ev)
      if ev.data.id == "dotfiles.lsp.-1.index" then
        shown[#shown + 1] = { ev.data.title, ev.data.status, ev.data.percent }
      end
    end,
  })
  local function lsp_progress(value)
    vim.api.nvim_exec_autocmds("LspProgress", {
      group = "user_lsp_progress",
      pattern = value.kind,
      data = { client_id = -1, params = { token = "index", value = value } },
    })
  end
  lsp_progress({ kind = "begin", title = "Indexing" })
  lsp_progress({ kind = "report", title = "Indexing", percentage = 40 })
  lsp_progress({ kind = "end", title = "Indexing" })
  T.eq("progress: a server's task becomes one native progress message", shown, {
    { "LSP: Indexing", "running", 0 },
    { "LSP: Indexing", "running", 40 },
    { "LSP: Indexing", "success", 100 },
  })
end)

T.case("debugpy", function()
  require("lazy").load({ plugins = { "nvim-dap" } })
  local adapter = require("dap").adapters.python
  local bin = T.dir({ ["debugpy-adapter"] = { "#!/bin/sh" } })
  vim.fn.setfperm(bin .. "/debugpy-adapter", "rwxr-xr-x")
  local got, told
  T.stub(vim, "notify", function(msg, level)
    told = { msg, level }
  end)
  T.stub(vim.env, "PATH", bin)
  adapter(function(found)
    got = found
  end)
  T.eq(
    "debugpy: the adapter is looked up when a session starts",
    got,
    { type = "executable", command = bin .. "/debugpy-adapter" }
  )
  got = nil
  vim.env.PATH = T.dir()
  adapter(function(found)
    got = found
  end)
  T.eq(
    "debugpy: without it no session starts, and the message says how to install it",
    { got == nil, told },
    { true, { "debugpy is not installed: :MasonInstall debugpy", vim.log.levels.ERROR } }
  )
end)

T.case("ui2", function()
  local module = "vim._core.ui2"
  local warning
  T.stub(package.loaded, module, nil)
  T.stub(package.preload, module, function()
    error("module '" .. module .. "' not found")
  end)
  T.stub(vim, "notify", function(msg, level)
    warning = { msg:match("^[^:]*"), level }
  end)
  vim.o.grepprg = ""
  local ok = pcall(T.config, "config/options.lua")
  vim.wait(1000, function()
    return warning ~= nil
  end)
  T.eq(
    "ui2: a Neovim without it still runs the rest of options.lua, and says so",
    { ok, vim.o.grepprg, warning },
    {
      true,
      "rg --vimgrep --smart-case",
      { "ui2 is off, delete its line in options.lua", vim.log.levels.WARN },
    }
  )
end)

T.done()
