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

T.case("Claude: the plugin still offers what we call", function()
  require("lazy").load({ plugins = { "claudecode.nvim" } })
  local terminal = require("claudecode.terminal")
  T.eq("claude: the terminal functions in_last_session uses exist", {
    type(terminal.get_active_terminal_bufnr),
    type(terminal.toggle_open_no_focus),
    debug.getinfo(terminal.toggle_open_no_focus, "u").nparams >= 2,
  }, { "function", "function", true })
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
