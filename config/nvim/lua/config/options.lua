local opt = vim.opt
local settings = require("config.settings")
local g = vim.g

g.mapleader = " "
g.maplocalleader = ","

opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = settings.wrap
opt.linebreak = true
opt.smoothscroll = true
opt.showmode = false
opt.laststatus = 3
opt.pumheight = 12
opt.winborder = "rounded"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars =
  { eob = " ", fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " ", diff = "╱" }
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true
opt.smartindent = true
opt.breakindent = true
opt.breakindentopt = { "shift:2" }
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
opt.virtualedit = "block"
opt.confirm = true
opt.formatoptions = "jcroqlnt"
opt.completeopt = { "menu", "menuone", "noselect" }
opt.jumpoptions = "view"
opt.mouse = "a"
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

opt.diffopt:append("algorithm:histogram")

opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 250
opt.timeoutlen = 400

opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldtext = ""

opt.spelllang = settings.spelllang
opt.spelloptions = "camel"

vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

g.tex_flavor = "latex"

g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
