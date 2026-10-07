local o = vim.opt_local

o.spell = true
o.conceallevel = 2
o.textwidth = 0
o.shiftwidth = 2
o.tabstop = 2
o.formatoptions:remove("t")

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
