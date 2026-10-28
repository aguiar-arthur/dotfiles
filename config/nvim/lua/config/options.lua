local o = vim.o
local opt = vim.opt
local settings = require("config.settings")
local g = vim.g

g.mapleader = " "
g.maplocalleader = ","

local ui2_ok, ui2_err = pcall(function()
  require("vim._core.ui2").enable()
end)
if not ui2_ok then
  vim.schedule(function()
    vim.notify(
      "ui2 is off, delete its line in options.lua: " .. tostring(ui2_err),
      vim.log.levels.WARN
    )
  end)
end

o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = settings.wrap
o.linebreak = true
o.conceallevel = 2
o.smoothscroll = true
o.showmode = false
o.laststatus = 3
o.winborder = "rounded"
o.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars =
  { eob = " ", fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " ", diff = "╱" }
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
o.tabclose = "uselast"

o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.shiftround = true
o.breakindent = true
o.breakindentopt = "shift:2"
o.ignorecase = true
o.smartcase = true
o.inccommand = "split"
o.virtualedit = "block"
o.confirm = true
o.exrc = true
opt.jumpoptions:append("view")
o.grepprg = "rg --vimgrep --smart-case"
o.grepformat = "%f:%l:%c:%m"

opt.diffopt:append("algorithm:histogram")

o.undofile = true
o.undolevels = 10000
o.updatetime = 250
o.timeoutlen = 400

o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99
o.foldtext = ""

opt.spelllang = settings.spelllang
o.spelloptions = "camel"
local spell_words = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
o.spellfile = spell_words
local words_stat, compiled_stat = vim.uv.fs_stat(spell_words), vim.uv.fs_stat(spell_words .. ".spl")
if words_stat and (not compiled_stat or compiled_stat.mtime.sec < words_stat.mtime.sec) then
  pcall(vim.cmd, "silent mkspell! " .. vim.fn.fnameescape(spell_words))
end

vim.schedule(function()
  o.clipboard = "unnamedplus"
end)

g.tex_flavor = "latex"

vim.filetype.add({
  extension = { mdc = "markdown" },
  pattern = { [".*%.json%.[^/]+"] = "json" },
})

g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
