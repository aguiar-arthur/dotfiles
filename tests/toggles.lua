local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local toggles = require("dotfiles.toggles")
toggles.map()
local function press(lhs)
  local map = vim.fn.maparg(vim.keycode(lhs), "n", false, true)
  if not map.callback then
    T.eq(lhs .. " is mapped", false, true)
    return
  end
  map.callback()
end
local function all(option)
  local values = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    values[#values + 1] = vim.wo[win][option]
  end
  return values
end

local root = T.dir({ ["a.lua"] = { "local a = 1" }, ["b.md"] = { "# B" } })
vim.cmd("edit " .. root .. "/a.lua")
vim.cmd("vsplit " .. root .. "/b.md")
local lua_win, md_win = vim.fn.bufwinid(root .. "/a.lua"), vim.fn.bufwinid(root .. "/b.md")
local wrap = vim.wo[lua_win].wrap

press("<leader>uw")
T.eq("Space u w changes every window", all("wrap"), { not wrap, not wrap })
press("<leader>uw")
T.eq("Space u w again restores them", all("wrap"), { wrap, wrap })

vim.api.nvim_set_current_win(md_win)
vim.wo[md_win].wrap = not wrap
toggles.apply(lua_win)
T.eq("a window that changes wrap with vim.wo does not leak it", vim.wo[lua_win].wrap, wrap)
press("<leader>uw")
T.eq("Space u w from that window still reads the real value", vim.wo[lua_win].wrap, not wrap)
press("<leader>uw")

vim.cmd("tabnew " .. root .. "/a.lua")
local review_win, review_tab = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_tabpage()
package.loaded["codediff.ui.lifecycle"] = {
  get_session = function(tab)
    return tab == review_tab and {} or nil
  end,
}
vim.wo[review_win].wrap = false
press("<leader>uw")
press("<leader>uw")
T.eq("a review keeps its sides unwrapped", vim.wo[review_win].wrap, false)
T.eq("while other tabs follow the toggle", vim.wo[lua_win].wrap, wrap)
vim.cmd("tabclose")

local relative = vim.wo[lua_win].relativenumber
press("<leader>uL")
T.eq("Space u L changes relative numbers", all("relativenumber"), { not relative, not relative })
press("<leader>uL")
local conceal = vim.wo[lua_win].conceallevel
press("<leader>uc")
T.eq("Space u c changes conceal", all("conceallevel"), conceal == 0 and { 2, 2 } or { 0, 0 })
press("<leader>uc")

T.eq(
  "spelling is on in prose only",
  { vim.wo[md_win].spell, vim.wo[lua_win].spell },
  { true, false }
)
press("<leader>us")
T.eq("Space u s turns prose spelling off", vim.wo[md_win].spell, false)
press("<leader>us")

vim.api.nvim_set_current_win(lua_win)
vim.b.keep_local_opts = true
vim.wo[lua_win][0].wrap = not wrap
press("<leader>uw")
press("<leader>uw")
T.eq("keep_local_opts keeps a buffer's own wrap", vim.wo[lua_win].wrap, not wrap)

local buf = vim.api.nvim_win_get_buf(lua_win)
press("<leader>uT")
T.eq("Space u T stops treesitter", vim.treesitter.highlighter.active[buf] == nil, true)
press("<leader>uT")
T.eq("Space u T starts it again", vim.treesitter.highlighter.active[buf] ~= nil, true)

vim.b[buf].keep_local_opts = nil
package.loaded["dotfiles.toggles"] = nil
local fresh = require("dotfiles.toggles")
fresh.setup()
local seeded = vim.go.conceallevel
vim.api.nvim_set_current_win(md_win)
vim.wo[md_win].conceallevel = seeded == 0 and 2 or 0
fresh.apply(lua_win)
T.eq(
  "the values come from setup, not from the window current at the first apply",
  vim.wo[lua_win].conceallevel,
  seeded
)

T.done()
