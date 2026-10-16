local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local python = require("dotfiles.python")
local root = T.dir({ ["src/a.py"] = {}, [".venv/bin/python"] = { "#!/bin/sh" } })
vim.fn.setfperm(root .. "/.venv/bin/python", "rwxr-xr-x")
vim.cmd("edit " .. root .. "/src/a.py")
vim.env.VIRTUAL_ENV = "/elsewhere"
T.eq("python: the project's .venv comes first", python.path(), root .. "/.venv/bin/python")
vim.cmd("edit " .. T.dir({ ["b.py"] = {} }) .. "/b.py")
T.eq("python: then $VIRTUAL_ENV", python.path(), "/elsewhere/bin/python")
vim.env.VIRTUAL_ENV = nil
T.eq("python: then python3", python.path(), vim.fn.exepath("python3"))

local mason = require("dotfiles.mason")
local settings = { mason_tools = { "shellcheck" }, mason_servers = { "lua_ls" } }
T.eq(
  "mason: servers become package names",
  mason.wanted(settings),
  { "shellcheck", "lua-language-server" }
)
package.loaded["mason-registry"] = {
  get_installed_package_names = function()
    return { "shellcheck" }
  end,
}
T.eq("mason: lists what is not installed", mason.missing(settings), { "lua-language-server" })

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

local git = require("dotfiles.git")
T.eq("git: no review without codediff", not git.review(), true)
package.loaded["codediff.ui.lifecycle"] = {
  get_session = function(tab)
    return tab == 2 and {} or nil
  end,
}
T.eq("git: the review tab is a review", git.review(2), true)
T.eq("git: another tab is not", git.review(1), false)

local first = vim.api.nvim_get_current_tabpage()
vim.cmd("tabnew")
local review_tab = vim.api.nvim_get_current_tabpage()
vim.cmd("tabnew")
git.mark_jump(review_tab)
vim.cmd("tabfirst | tablast")
git.back_to_review()
T.eq("git: back from a jump closes its tab", #vim.api.nvim_list_tabpages(), 2)
T.eq("git: and returns to the review", vim.api.nvim_get_current_tabpage(), review_tab)
local warned
local notify = vim.notify
vim.notify = function(msg)
  warned = msg
end
git.back_to_review()
vim.notify = notify
T.eq("git: back outside a jump keeps the tab", #vim.api.nvim_list_tabpages(), 2)
T.eq("git: and says why", warned, "This tab was not opened from a review")
vim.api.nvim_set_current_tabpage(first)
vim.cmd("tabonly")

local treesitter = require("dotfiles.treesitter")
local ts = package.loaded["nvim-treesitter"]
package.loaded["nvim-treesitter"] = {
  get_installed = function()
    return { "lua", "bash" }
  end,
}
T.eq("treesitter: lists the parsers not installed", treesitter.missing({ "lua", "rust", "go" }), {
  "rust",
  "go",
})
T.eq("treesitter: none when all are there", treesitter.missing({ "bash" }), {})
package.loaded["nvim-treesitter"] = ts

local base
rawset(vim.cmd, "CodeDiff", function(arg)
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
local said
vim.notify = function(msg)
  said = msg
end
repo("trunk", false)
T.eq(
  "git: no base branch says so",
  base == nil and said,
  "No origin/HEAD, origin/main or origin/master"
)

local float = require("dotfiles.float").win("Claude")
T.eq("float: the same style everywhere", {
  float.position,
  float.border,
  float.title,
  float.backdrop,
}, { "float", "rounded", " Claude ", 60 })

local sent, opened = {}, {}
local active = nil
package.loaded["claudecode.terminal"] = {
  get_active_terminal_bufnr = function()
    return active
  end,
  toggle_open_no_focus = function(_, args)
    opened[#opened + 1] = args
    active = 1
  end,
}
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
package.loaded["claudecode.terminal"] = nil

local claude = require("dotfiles.claude")
claude.watch()
local term_buf = vim.api.nvim_create_buf(false, true)
local chan = vim.api.nvim_open_term(term_buf, {})
package.loaded["claudecode.terminal"] = {
  get_active_terminal_bufnr = function()
    return term_buf
  end,
}
local notes = {}
local real_notify = vim.notify
vim.notify = function(msg, level, opts)
  notes[#notes + 1] = { msg, level, opts.title }
end
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
vim.notify = real_notify
package.loaded["claudecode.terminal"] = nil

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

T.done()
