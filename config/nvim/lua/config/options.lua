local opt = vim.opt
local g = vim.g

-- Leaders --------------------------------------------------------------
g.mapleader = " "
g.maplocalleader = "," -- vimtex: <localleader>ll compiles, lv views, ...

-- UI -------------------------------------------------------------------
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false -- prose (tex/markdown) enables wrap via autocmd/ftplugin
opt.showmode = false -- the mode is already shown in the statusline
opt.laststatus = 3 -- global statusline
opt.pumheight = 12
opt.winborder = "rounded"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " ", diff = "╱" }
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- Editing --------------------------------------------------------------
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true
opt.smartindent = true
opt.breakindent = true
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
opt.virtualedit = "block"
opt.confirm = true -- prompt instead of failing when quitting with unsaved changes
opt.formatoptions = "jcroqlnt"
opt.completeopt = { "menu", "menuone", "noselect" }
opt.jumpoptions = "view"
opt.mouse = "a"
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

-- Diff: histogram aligns moved/rewritten blocks better (the defaults already pair changed
-- lines with linematch and highlight the changed characters with inline:char)
opt.diffopt:append("algorithm:histogram")

-- Persistence / performance --------------------------------------------
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 250
opt.timeoutlen = 400

-- Treesitter folds (nothing folded on open) ----------------------------
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldtext = ""

-- Spell: en + pt_br (enabled only for tex/markdown/text via autocmd) ----
opt.spelllang = { "en_us", "pt_br" }
opt.spelloptions = "camel"

-- System clipboard (deferred to avoid slowing startup) -----------------
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

-- .tex files are LaTeX (not plaintex) -----------------------------------
g.tex_flavor = "latex"

-- Unneeded providers ---------------------------------------------------
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
