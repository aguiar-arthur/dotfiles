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
local closed
package.loaded["codediff.ui.lifecycle"] = {
  get_session = function(tab)
    return tab == review_tab and {} or nil
  end,
  close = function(tab)
    closed = tab
  end,
}
local picker = vim.api.nvim_get_current_win()
local jump_win = git.jump_win(review_tab)
local jump_tab = vim.api.nvim_win_get_tabpage(jump_win)
T.eq("git: a jump tab opens just before its review", vim.api.nvim_tabpage_get_number(jump_tab), 2)
T.eq("git: and focus stays where it was", vim.api.nvim_get_current_win(), picker)
T.eq("git: the jump tab knows its review", git.jumps(review_tab), { jump_tab })
vim.api.nvim_set_current_tabpage(jump_tab)
vim.cmd.tabmove()
vim.api.nvim_set_current_tabpage(review_tab)
T.eq("git: a review has one jump tab", git.jump_win(review_tab), jump_win)
T.eq("git: moved back just before the review", vim.api.nvim_tabpage_get_number(jump_tab), 2)
T.eq("git: no tab is added", #vim.api.nvim_list_tabpages(), 3)

vim.api.nvim_set_current_win(jump_win)
vim.cmd("edit " .. root .. "/src/a.py")
local file = vim.api.nvim_get_current_buf()
vim.api.nvim_set_current_tabpage(review_tab)
vim.api.nvim_set_current_buf(file)
vim.api.nvim_set_current_win(jump_win)
git.close_buffer()
T.eq("git: Space b d on a review's file closes the jump tab", #vim.api.nvim_list_tabpages(), 2)
T.eq("git: and returns to the review", vim.api.nvim_get_current_tabpage(), review_tab)
T.eq("git: the file stays loaded", vim.api.nvim_buf_is_loaded(file), true)

git.back_to_review()
T.eq("git: Space g q in a review closes it", closed, review_tab)
closed = nil
git.close_buffer()
T.eq("git: so does Space b d on the review's file", closed, review_tab)

vim.api.nvim_set_current_win(git.jump_win(review_tab))
vim.cmd("enew")
local other = vim.api.nvim_get_current_buf()
local deleted
local bufdelete = Snacks.bufdelete
Snacks.bufdelete = function()
  deleted = vim.api.nvim_get_current_buf()
end
git.close_buffer()
Snacks.bufdelete = bufdelete
T.eq("git: Space b d on another file in a jump tab deletes it", deleted, other)

vim.api.nvim_set_current_tabpage(first)
git.close_jumps(review_tab)
T.eq("git: closing a review closes its jump tabs", #vim.api.nvim_list_tabpages(), 2)

vim.cmd("$tabnew")
git.mark_jump(review_tab)
vim.cmd("tabfirst | tablast")
git.back_to_review()
T.eq("git: back from a jump closes its tab", #vim.api.nvim_list_tabpages(), 2)
T.eq("git: and returns to the review", vim.api.nvim_get_current_tabpage(), review_tab)
vim.api.nvim_set_current_tabpage(first)
local warned
local notify = vim.notify
vim.notify = function(msg)
  warned = msg
end
git.back_to_review()
vim.notify = notify
T.eq("git: back outside a jump keeps the tab", #vim.api.nvim_list_tabpages(), 2)
T.eq("git: and says why", warned, "This tab was not opened from a review")
vim.cmd("tabonly")

local repo = T.dir({ ["f.lua"] = { "one", "two" } })
local function sh(...)
  return vim.trim(vim.system({ "git", "-C", repo, ... }, { text = true }):wait().stdout)
end
sh("init", "-q")
sh("add", ".")
sh("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "base")
local old = vim.api.nvim_create_buf(true, true)
vim.api.nvim_buf_set_lines(old, 0, -1, false, { "one", "two" })
vim.api.nvim_set_current_buf(old)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
local session =
  { original_bufnr = old, original = { absolute = repo .. "/f.lua" }, original_revision = "HEAD" }
package.loaded["codediff.ui.lifecycle"] = {
  get_session = function()
    return session
  end,
}
local browsed
local gitbrowse = Snacks.gitbrowse
Snacks.gitbrowse = function(opts)
  browsed = { opts = opts, file = vim.fs.basename(vim.api.nvim_buf_get_name(0)) }
end
git.browse()
T.eq("git: Space g O on a review's old side opens its commit", browsed, {
  opts = { what = "permalink", commit = sh("rev-parse", "HEAD"), line_start = 2, line_end = 2 },
  file = "f.lua",
})
session.original_revision = ":0"
git.browse()
T.eq("git: the index has no page, so the usual one opens", browsed.opts, nil)
session.original_revision = "HEAD"
vim.cmd("enew")
git.browse()
T.eq("git: so does the real side", browsed.opts, nil)
Snacks.gitbrowse = gitbrowse

package.loaded["codediff.ui.view.actions.panes"] = {}
vim.notify = function(msg)
  warned = msg
end
git.setup()
vim.notify = notify
T.eq(
  "git: a codediff without open_in_prev_tab is said, not ignored",
  warned,
  "codediff changed: gf in a review opens the previous tab, see docs/git.md"
)
package.loaded["codediff.ui.view.actions.panes"] = nil
package.loaded["codediff.ui.lifecycle"] = nil
local real = require("codediff.ui.view.actions.panes")
T.eq("git: codediff still has open_in_prev_tab", type(real.open_in_prev_tab), "function")

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
