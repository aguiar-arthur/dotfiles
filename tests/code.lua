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

T.case("python in every tool", function()
  vim.cmd("enew")
  T.eq(
    "python: a folder can be given, whatever the buffer",
    python.path(root .. "/src"),
    root .. "/.venv/bin/python"
  )
  local basedpyright = dofile(vim.fn.stdpath("config") .. "/after/lsp/basedpyright.lua")
  local config = { root_dir = root, settings = vim.deepcopy(basedpyright.settings) }
  local kept_by_client = config.settings
  basedpyright.before_init({}, config)
  T.eq(
    "python: basedpyright gets the interpreter in the settings table its client already holds",
    { kept_by_client.python.pythonPath, kept_by_client.basedpyright ~= nil },
    { root .. "/.venv/bin/python", true }
  )
  config = { root_dir = root, settings = { python = { pythonPath = "/conda/bin/python" } } }
  basedpyright.before_init({}, config)
  T.eq(
    "python: a pythonPath set for the project or machine wins",
    config.settings.python.pythonPath,
    "/conda/bin/python"
  )
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  local function root_of(files, file)
    local dir = T.dir(files)
    vim.cmd("edit " .. dir .. "/" .. file)
    local got
    basedpyright.root_dir(vim.api.nvim_get_current_buf(), function(found)
      got = found
    end)
    return got and vim.uv.fs_realpath(got), vim.uv.fs_realpath(dir)
  end
  local got, dir = root_of({ ["pyproject.toml"] = {}, ["pkg/m.py"] = {} }, "pkg/m.py")
  T.eq("python: basedpyright's root is the project's", got, dir)
  got, dir = root_of({ ["lone/m.py"] = {} }, "lone/m.py")
  T.eq(
    "python: a lone file's folder is its root, never the folder of another buffer",
    got,
    dir and dir .. "/lone"
  )
  local adapter
  T.stub(package.loaded, "neotest-python", function(opts)
    adapter = opts
    return {}
  end)
  T.stub(package.loaded, "neotest", {
    setup = function() end,
  })
  local spec = vim.iter(T.config("plugins/test.lua")):find(function(item)
    return item[1] == "nvim-neotest/neotest"
  end)
  spec.config()
  T.eq(
    "python: neotest-python keeps its own lookup (venv/, Poetry, Pipenv, uv)",
    adapter.python,
    nil
  )
end)

T.case("Clojure: waiting for the REPL", function()
  local clojure = require("dotfiles.clojure")
  T.stub(clojure, "poll", 10)
  T.stub(clojure, "limit", 200)
  local connected, told, jobs = 0, {}, {}
  T.stub(package.loaded, "conjure.client.clojure.nrepl.action", {
    ["connect-port-file"] = function()
      connected = connected + 1
    end,
  })
  T.stub(vim, "notify", function(msg, level)
    told[#told + 1] = { msg, level }
  end)
  local function terminal(running)
    local buf = vim.api.nvim_create_buf(false, true)
    if running then
      local job = vim.fn.jobstart({ "sleep", "5" })
      jobs[#jobs + 1] = job
      vim.b[buf].terminal_job_id = job
    end
    return buf
  end
  local dir = T.dir()

  clojure.connect_when_ready(dir .. "/.nrepl-port", terminal(true))
  vim.fn.writefile({ "1234" }, dir .. "/.nrepl-port")
  vim.wait(1000, function()
    return connected > 0
  end, 10)
  T.eq("clojure: a port file connects Conjure", { connected, #told }, { 1, 0 })

  clojure.connect_when_ready(dir .. "/never", terminal(false))
  vim.wait(1000, function()
    return #told > 0
  end, 10)
  T.eq(
    "clojure: a REPL that exits before it is ready says so",
    told[1],
    { "The REPL stopped before it was ready", vim.log.levels.ERROR }
  )

  clojure.connect_when_ready(dir .. "/never", terminal(true))
  vim.wait(1000, function()
    return #told > 1
  end, 10)
  T.eq(
    "clojure: a REPL that never writes its port gives up",
    { told[2] and told[2][1]:match("^The REPL did not start within") ~= nil, connected },
    { true, 1 }
  )
  for _, job in ipairs(jobs) do
    vim.fn.jobstop(job)
  end
end)

T.case("Clojure: two ticks queued at once", function()
  local clojure = require("dotfiles.clojure")
  T.stub(clojure, "poll", 10)
  local connected, errors = 0, {}
  T.stub(package.loaded, "conjure.client.clojure.nrepl.action", {
    ["connect-port-file"] = function()
      connected = connected + 1
    end,
  })
  T.stub(vim, "schedule_wrap", function(fn)
    return function(...)
      local args = { ... }
      for _ = 1, 2 do
        vim.schedule(function()
          local ok, err = pcall(fn, unpack(args))
          if not ok then
            errors[#errors + 1] = tostring(err)
          end
        end)
      end
    end
  end)
  local port = T.dir() .. "/.nrepl-port"
  vim.fn.writefile({ "1234" }, port)
  local buf = vim.api.nvim_create_buf(false, true)
  local job = vim.fn.jobstart({ "sleep", "5" })
  vim.b[buf].terminal_job_id = job
  clojure.connect_when_ready(port, buf)
  vim.wait(500, function()
    return connected > 0
  end, 10)
  vim.wait(100)
  vim.fn.jobstop(job)
  T.eq(
    "clojure: the second tick sees the closed timer: one connect, no error",
    { connected, errors },
    { 1, {} }
  )
end)

T.done()
