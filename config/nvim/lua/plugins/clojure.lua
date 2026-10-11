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

local function connect_when_ready(port_file)
  local timer = assert(vim.uv.new_timer())
  local waited = 0
  timer:start(
    500,
    500,
    vim.schedule_wrap(function()
      waited = waited + 500
      if vim.uv.fs_stat(port_file) then
        timer:close()
        connect()
      elseif waited >= 180000 then
        timer:close()
        vim.notify("The REPL did not start within 3 minutes", vim.log.levels.ERROR)
      end
    end)
  )
end

local function jack_in()
  local root = vim.fs.root(0, { "deps.edn", "project.clj" })
  local cmd = root and repl_command(root)
  if not cmd then
    vim.notify("No deps.edn or project.clj above this file", vim.log.levels.ERROR)
    return
  end
  local port_file = root .. "/.nrepl-port"
  if vim.uv.fs_stat(port_file) then
    connect()
    return
  end
  Snacks.terminal(cmd, { cwd = root, win = { position = "bottom", height = 12 } })
  vim.cmd.wincmd("p")
  connect_when_ready(port_file)
end

return {
  {
    "Olical/conjure",
    ft = "clojure",
    init = function()
      vim.g["conjure#filetypes"] = { "clojure" }
      vim.g["conjure#mapping#doc_word"] = false
      vim.g["conjure#mapping#def_word"] = false
      vim.g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = false
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_clojure_repl", { clear = true }),
        pattern = "clojure",
        callback = function(ev)
          vim.keymap.set(
            "n",
            "<localleader>cj",
            jack_in,
            { buffer = ev.buf, desc = "Start the REPL and connect (jack-in)" }
          )
        end,
      })
    end,
  },
  { "julienvincent/nvim-paredit", ft = "clojure", opts = {} },
}
