local M = {}

local versions = { nrepl = "1.8.0", cider_nrepl = "0.63.1" }

local function repl_command(root)
  if vim.uv.fs_stat(root .. "/deps.edn") then
    return {
      "clojure",
      "-Sdeps",
      ('{:deps {nrepl/nrepl {:mvn/version "%s"} cider/cider-nrepl {:mvn/version "%s"}}}'):format(
        versions.nrepl,
        versions.cider_nrepl
      ),
      "-M",
      "-m",
      "nrepl.cmdline",
      "--middleware",
      "[cider.nrepl/cider-middleware]",
    }
  end
  if vim.uv.fs_stat(root .. "/project.clj") then
    return {
      "lein",
      "update-in",
      ":plugins",
      "conj",
      ('[cider/cider-nrepl "%s"]'):format(versions.cider_nrepl),
      "--",
      "repl",
      ":headless",
    }
  end
end

local function connect()
  require("conjure.client.clojure.nrepl.action")["connect-port-file"]()
end

local starting = {}

local function job_running(buf)
  local job = vim.api.nvim_buf_is_valid(buf) and vim.b[buf].terminal_job_id
  return job and vim.fn.jobwait({ job }, 0)[1] == -1
end

local function connect_when_ready(port_file, buf)
  local timer = assert(vim.uv.new_timer())
  local waited = 0
  starting[port_file] = true
  timer:start(
    500,
    500,
    vim.schedule_wrap(function()
      waited = waited + 500
      if vim.uv.fs_stat(port_file) then
        timer:close()
        starting[port_file] = nil
        connect()
      elseif not job_running(buf) then
        timer:close()
        starting[port_file] = nil
        vim.notify("The REPL stopped before it was ready", vim.log.levels.ERROR)
      elseif waited >= 180000 then
        timer:close()
        starting[port_file] = nil
        vim.notify("The REPL did not start within 3 minutes", vim.log.levels.ERROR)
      end
    end)
  )
end

local function when_port_answers(port_file, callback)
  local port = tonumber(vim.fn.readfile(port_file)[1] or "")
  if not port then
    return callback(false)
  end
  local tcp = assert(vim.uv.new_tcp())
  local ok = tcp:connect("127.0.0.1", port, function(err)
    tcp:close()
    vim.schedule(function()
      callback(err == nil)
    end)
  end)
  if not ok then
    tcp:close()
    callback(false)
  end
end

function M.jack_in()
  local root = vim.fs.root(0, { "deps.edn", "project.clj" })
  local cmd = root and repl_command(root)
  if not cmd then
    vim.notify("No deps.edn or project.clj above this file", vim.log.levels.ERROR)
    return
  end
  local port_file = root .. "/.nrepl-port"
  if starting[port_file] then
    vim.notify("The REPL is still starting; it connects when ready", vim.log.levels.WARN)
    return
  end
  local function start()
    local opts = { cwd = root, win = { position = "bottom", height = 12 } }
    local old = Snacks.terminal.get(cmd, vim.tbl_extend("force", opts, { create = false }))
    if old then
      old:close()
    end
    local term = Snacks.terminal.open(cmd, opts)
    vim.cmd.wincmd("p")
    vim.cmd.stopinsert()
    connect_when_ready(port_file, term.buf)
  end
  if not vim.uv.fs_stat(port_file) then
    return start()
  end
  when_port_answers(port_file, function(alive)
    if alive then
      connect()
    else
      os.remove(port_file)
      start()
    end
  end)
end

return M
