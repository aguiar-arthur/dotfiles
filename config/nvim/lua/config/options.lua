local opt = vim.opt
local g = vim.g

-- Leaders --------------------------------------------------------------
g.mapleader = " "
g.maplocalleader = "," -- vimtex: <localleader>ll compila, lv visualiza, ...

-- UI -------------------------------------------------------------------
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false -- prosa (tex/markdown) liga wrap via autocmd/ftplugin
opt.showmode = false -- o mode já aparece na statusline
opt.laststatus = 3 -- statusline global
opt.pumheight = 12
opt.winborder = "rounded"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " " }
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- Edição ---------------------------------------------------------------
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
opt.confirm = true -- pergunta em vez de falhar ao sair com alterações
opt.formatoptions = "jcroqlnt"
opt.completeopt = { "menu", "menuone", "noselect" }
opt.jumpoptions = "view"
opt.mouse = "a"
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

-- Persistência / performance -------------------------------------------
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 250
opt.timeoutlen = 400

-- Folds via treesitter (sem dobrar nada ao abrir) ----------------------
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldtext = ""

-- Spell: en + pt_br (ativado apenas em tex/markdown/text via autocmd) ---
opt.spelllang = { "en_us", "pt_br" }
opt.spelloptions = "camel"

-- Clipboard do sistema (adiado para não atrasar o startup) -------------
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

-- Arquivos .tex são LaTeX (não plaintex) --------------------------------
g.tex_flavor = "latex"

-- Providers desnecessários ---------------------------------------------
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
