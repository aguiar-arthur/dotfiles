-- Buffer settings for LaTeX (runs after vimtex's ftplugin).
local o = vim.opt_local

o.wrap = true
o.linebreak = true
o.breakindent = true
o.spell = true
o.conceallevel = 2 -- "rendered" symbols/accents; <leader>uc toggles; the cursor line shows the source
o.textwidth = 0
o.shiftwidth = 2
o.tabstop = 2
o.formatoptions:remove("t") -- do not hard-wrap lines automatically

-- <localleader> = "," → ,ll compiles, ,lv opens the PDF, etc.
-- (defined here, with descriptions, so they show up in which-key)
local function map(lhs, cmd, desc, mode)
  vim.keymap.set(mode or "n", "<localleader>" .. lhs, "<cmd>" .. cmd .. "<CR>", {
    buffer = true, silent = true, desc = desc,
  })
end

map("ll", "VimtexCompile", "Compile (toggle continuous latexmk)")
map("lk", "VimtexStop", "Stop compiler")
map("lK", "VimtexStopAll", "Stop all compilers")
map("lv", "VimtexView", "View PDF / forward search")
map("lc", "VimtexClean", "Clean aux files")
map("lC", "VimtexClean!", "Clean aux + output files")
map("le", "VimtexErrors", "Errors (quickfix)")
map("lo", "VimtexCompileOutput", "Compiler output")
map("lg", "VimtexStatus", "Compilation status")
map("lt", "VimtexTocOpen", "Table of contents")
map("lT", "VimtexTocToggle", "Toggle table of contents")
map("li", "VimtexInfo", "Project info")
map("lw", "VimtexCountWords", "Count words")
map("lr", "VimtexReload", "Reload vimtex")
