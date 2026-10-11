local o = vim.opt_local

o.textwidth = 0
o.formatoptions:remove("t")

vim.keymap.set(
  "n",
  "<localleader>lw",
  "<cmd>VimtexCountWords<CR>",
  { buffer = true, silent = true, desc = "Count words" }
)

local ok, wk = pcall(require, "which-key")
if ok then
  local labels = {
    ll = "Compile (toggle continuous latexmk)",
    lk = "Stop compiler",
    lK = "Stop all compilers",
    lv = "View PDF / forward search",
    lc = "Clean aux files",
    lC = "Clean aux + output files",
    le = "Errors (quickfix)",
    lo = "Compiler output",
    lg = "Compilation status",
    lt = "Table of contents",
    lT = "Toggle table of contents",
    li = "Project info",
    lx = "Reload vimtex",
    lq = "Log",
  }
  local spec = { { "<localleader>l", group = "vimtex (LaTeX)", buffer = 0 } }
  for lhs, desc in pairs(labels) do
    spec[#spec + 1] = { "<localleader>" .. lhs, desc = desc, buffer = 0 }
  end
  wk.add(spec)
end
