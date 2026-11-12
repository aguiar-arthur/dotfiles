local T = dofile(vim.env.DOT .. "/tests/lib.lua")

T.case("the float style", function()
  local float = require("dotfiles.float").win("Claude")
  T.eq("float: the same style everywhere", {
    float.position,
    float.border,
    float.title,
    float.backdrop,
  }, { "float", "rounded", " Claude ", 60 })
end)

T.case("picker keys open their source with its options", function()
  local opened
  T.stub(Snacks, "picker", {
    files = function(opts)
      opened = { "files", opts }
    end,
  })
  local open = require("dotfiles.picker").open("files", { hidden = true })
  T.eq("picker: nothing opens until the key", opened, nil)
  open()
  T.eq("picker: the key opens its source", opened, { "files", { hidden = true } })
end)

T.case("Claude: the plugin still offers what we call", function()
  require("lazy").load({ plugins = { "claudecode.nvim" } })
  local terminal = require("claudecode.terminal")
  T.eq("claude: the terminal functions in_last_session uses exist", {
    type(terminal.get_active_terminal_bufnr),
    type(terminal.toggle_open_no_focus),
    debug.getinfo(terminal.toggle_open_no_focus, "u").nparams >= 2,
  }, { "function", "function", true })
  local selection, claudecode = require("claudecode.selection"), require("claudecode")
  T.eq("claude: what guard and send read of the plugin exists", {
    type(selection.enable),
    type(selection.disable),
    type(selection.state.tracking_enabled),
    type(terminal.send_to_terminal),
    type(claudecode.is_claude_connected),
    type(claudecode.state.config.visual_demotion_delay_ms),
    type(claudecode.state.config.connection_wait_delay),
  }, { "function", "function", "boolean", "function", "function", "number", "number" })
end)

T.case("Claude: no selection from a file of secrets", function()
  local claude = require("dotfiles.claude")
  for name, secret in pairs({
    ["/p/.env"] = true,
    ["/p/.env.local"] = true,
    ["/p/server.pem"] = true,
    ["/home/.ssh/id_ed25519"] = true,
    ["/home/.netrc"] = true,
    ["/p/aws_credentials"] = true,
    ["/p/main.lua"] = false,
    ["/p/environment.md"] = false,
  }) do
    T.eq("claude: a secret by its name: " .. name, claude.secret(name), secret)
  end
  local calls = {}
  local selection = { state = { tracking_enabled = true } }
  function selection.disable()
    selection.state.tracking_enabled = false
    calls[#calls + 1] = "disable"
  end
  function selection.enable(server, delay)
    selection.state.tracking_enabled = true
    calls[#calls + 1] = { server, delay }
  end
  T.stub(package.loaded, "claudecode.selection", selection)
  T.stub(package.loaded, "claudecode", {
    state = { server = "server", config = { visual_demotion_delay_ms = 50 } },
  })
  local secret_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(secret_buf, "/tmp/claude-test/.env")
  local code_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(code_buf, "/tmp/claude-test/main.lua")
  claude.guard(code_buf)
  T.eq("claude: a plain file leaves tracking alone", calls, {})
  claude.guard(secret_buf)
  claude.guard(secret_buf)
  T.eq("claude: entering a secret pauses the selection, once", calls, { "disable" })
  claude.guard(code_buf)
  T.eq(
    "claude: leaving it resumes with the plugin's server and delay",
    calls,
    { "disable", { "server", 50 } }
  )
  claude.guard(code_buf)
  T.eq("claude: and only once", #calls, 2)
  vim.api.nvim_buf_delete(secret_buf, { force = true })
  vim.api.nvim_buf_delete(code_buf, { force = true })
end)

T.case("Claude: a saved session never holds Claude", function()
  local claude = require("dotfiles.claude")
  local term_buf = vim.api.nvim_create_buf(false, true)
  T.stub(package.loaded, "claudecode.terminal", {
    get_active_terminal_bufnr = function()
      return term_buf
    end,
  })
  vim.cmd("vsplit")
  local split = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(split, term_buf)
  local float = vim.api.nvim_open_win(term_buf, false, {
    relative = "editor",
    row = 1,
    col = 1,
    width = 10,
    height = 3,
  })
  claude.hide_for_session()
  T.eq(
    "claude: a split showing Claude is hidden before the session is saved, a float is not",
    { vim.api.nvim_win_is_valid(split), vim.api.nvim_win_is_valid(float) },
    { false, true }
  )
  vim.api.nvim_win_close(float, true)
end)

T.case("Claude: asking without leaving the code", function()
  local claude = require("dotfiles.claude")
  local dir = T.dir({ ["src/a.lua"] = { "one", "two", "three" } })
  vim.cmd("cd " .. dir)
  vim.cmd("edit src/a.lua")
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  T.eq("claude: the line under the cursor", claude.mention(), "@src/a.lua#L2")
  vim.cmd("normal! Vj")
  T.eq("claude: a selection, top to bottom", claude.mention(), "@src/a.lua#L2-3")
  local sent
  T.stub(claude, "send", function(prompt)
    sent = prompt
  end)
  T.stub(vim.ui, "input", function(_, done)
    done("why two?")
  end)
  vim.cmd("normal! \27")
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  claude.ask()
  T.eq("claude: the question goes with where it was asked", sent, "@src/a.lua#L2 why two?")
  sent = nil
  T.stub(vim.ui, "input", function(_, done)
    done("  ")
  end)
  claude.ask()
  T.eq("claude: an empty question sends nothing", sent, nil)
  vim.cmd("edit .env")
  local warned
  T.stub(vim, "notify", function(msg)
    warned = msg
  end)
  T.stub(vim.ui, "input", function(_, done)
    done("what is this?")
  end)
  claude.ask()
  T.eq(
    "claude: nothing is asked from a file of secrets, and it says so",
    { sent, warned },
    { nil, "Not sent to Claude: .env looks like a file of secrets" }
  )
  vim.cmd("cd -")
  vim.cmd("enew")
end)

T.case("Claude: sending a question", function()
  local claude = require("dotfiles.claude")
  local active, connected, opened = nil, false, 0
  local sent, focused = {}, 0
  T.stub(package.loaded, "claudecode.terminal", {
    get_active_terminal_bufnr = function()
      return active
    end,
    toggle_open_no_focus = function()
      opened = opened + 1
      active = 1
    end,
    send_to_terminal = function(text, opts)
      sent[#sent + 1] = { text, opts.submit }
    end,
  })
  T.stub(package.loaded, "claudecode", {
    is_claude_connected = function()
      return connected
    end,
    state = { config = { connection_wait_delay = 0 } },
  })
  vim.api.nvim_create_user_command("ClaudeCodeFocus", function()
    focused = focused + 1
  end, {})
  claude.send("first")
  T.eq("claude: no Claude opens one, without focus, and waits", { opened, sent }, { 1, {} })
  connected = true
  vim.wait(2000, function()
    return #sent > 0
  end)
  T.eq(
    "claude: once connected the question is submitted and Claude is focused",
    { sent, focused },
    { { { "first", true } }, 1 }
  )
  claude.send("second")
  T.eq(
    "claude: a connected Claude gets it at once",
    { opened, sent[2], focused },
    { 1, { "second", true }, 2 }
  )
  vim.api.nvim_del_user_command("ClaudeCodeFocus")
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

T.done()
