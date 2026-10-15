local T = dofile(vim.env.DOT .. "/tests/lib.lua")

for name, ft in pairs({
  ["rules.mdc"] = "markdown",
  ["config.json.example"] = "json",
  ["package.json.tmpl"] = "json",
  ["a.json"] = "json",
  ["a.jsonc"] = "jsonc",
  ["x.json.d/conf"] = "",
}) do
  T.eq("filetype of " .. name, vim.filetype.match({ filename = "/p/" .. name }) or "", ft)
end

local conform = T.config("plugins/formatting.lua").opts
local args = conform.formatters.prettier.append_args
T.eq(
  "prettier gets --parser json for .json.*",
  args(nil, { filename = "/p/a.json.tmpl" }),
  { "--parser", "json" }
)
T.eq("prettier keeps its own parser for .json", args(nil, { filename = "/p/package.json" }), {})

local function formats(files, file)
  local root = T.dir(files)
  vim.cmd("edit " .. root .. "/" .. file)
  return conform.format_on_save(vim.api.nvim_get_current_buf()) ~= nil
end
T.eq("Lua without stylua.toml is left alone", formats({}, "a.lua"), false)
T.eq("Lua with stylua.toml formats on save", formats({ ["stylua.toml"] = {} }, "src/a.lua"), true)
T.eq(
  "Python with [tool.ruff] formats on save",
  formats({ ["pyproject.toml"] = { "[tool.ruff]" } }, "a.py"),
  true
)
T.eq(
  "Python with an unrelated pyproject is left alone",
  formats({ ["pyproject.toml"] = { "[project]" } }, "a.py"),
  false
)
T.eq(
  "shell with an .editorconfig [*.sh] formats",
  formats({ [".editorconfig"] = { "[*.sh]" } }, "a.sh"),
  true
)
T.eq(
  "shell with an .editorconfig for Python only is left alone",
  formats({ [".editorconfig"] = { "[*.py]" } }, "a.sh"),
  false
)
T.eq("Markdown with .rumdl.toml formats on save", formats({ [".rumdl.toml"] = {} }, "a.md"), true)
T.eq(
  "JSON with .prettierrc formats on save",
  formats({ [".prettierrc"] = { "{}" } }, "a.json.example"),
  true
)
T.eq("LaTeX never formats on save", formats({ [".latexindent.yaml"] = {} }, "a.tex"), false)
vim.g.disable_autoformat = true
T.eq("Space u f turns format on save off", formats({ ["stylua.toml"] = {} }, "b.lua"), false)
vim.g.disable_autoformat = nil

local picker = T.config("plugins/snacks.lua").opts.picker
T.eq("references always open the list", picker.sources.lsp_references.auto_confirm, false)

T.done()
