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
    lv = "View PDF / forward search",
    le = "Errors (quickfix)",
    lt = "Table of contents",
    lc = "Clean aux files",
    lC = "Clean aux + output files",
    lk = "Stop compiler",
    lx = "Reload vimtex",
  }
  local spec = { { "<localleader>l", group = "vimtex (LaTeX)", buffer = 0 } }
  for lhs, desc in pairs(labels) do
    spec[#spec + 1] = { "<localleader>" .. lhs, desc = desc, buffer = 0 }
  end
  wk.add(spec)
end
