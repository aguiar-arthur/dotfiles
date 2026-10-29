local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local root = T.dir({
  ["a.lua"] = { "local a = 1" },
  ["a.py"] = { "x = 1" },
})

local function highlighted()
  return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
end

local own_indent = "v:lua.require'nvim-treesitter'.indentexpr()"

T.case("treesitter highlight and indent per file type", function()
  vim.cmd("edit " .. root .. "/a.lua")
  T.eq("treesitter: Lua is highlighted", highlighted(), true)
  T.eq(
    "treesitter: and indented by it, as settings.treesitter_indent says",
    vim.bo.indentexpr,
    own_indent
  )
  if pcall(vim.treesitter.language.add, "python") then
    vim.cmd("edit " .. root .. "/a.py")
    T.eq("treesitter: Python is highlighted", highlighted(), true)
    T.eq(
      "treesitter: but keeps the ftplugin's indent, whose own is unreliable",
      vim.bo.indentexpr:find("nvim-treesitter", 1, true),
      nil
    )
  else
    T.skip("treesitter: Python highlight and indent", "the python parser is not installed")
  end
  vim.cmd("enew")
  vim.cmd("noautocmd setlocal filetype=tex")
  require("dotfiles.treesitter").start(vim.api.nvim_get_current_buf())
  T.eq("treesitter: LaTeX is left to vimtex's syntax", highlighted(), false)
end)

T.done()
