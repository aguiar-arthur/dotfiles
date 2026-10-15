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
local state = T.dir()
local stdpath = vim.fn.stdpath
vim.fn.stdpath = function(what)
  return what == "state" and state or stdpath(what)
end
local function trust(root)
  local real = vim.uv.fs_realpath(root .. "/.nvim.lua")
  local file = assert(io.open(real, "rb"))
  vim.fn.writefile({ vim.fn.sha256(file:read("*a")) .. " " .. real }, state .. "/trust")
  file:close()
end
T.eq(
  "JSON with .prettierrc but no trusted .nvim.lua is left alone",
  formats({ [".prettierrc"] = { "{}" }, [".nvim.lua"] = {} }, "a.json"),
  false
)
local project = T.dir({ [".prettierrc"] = { "{}" }, [".nvim.lua"] = { "vim.o.wrap = false" } })
trust(project)
vim.cmd("edit " .. project .. "/a.json.example")
local buf = vim.api.nvim_get_current_buf()
local prettier = conform.formatters.prettier
T.eq("JSON beside a trusted .nvim.lua formats on save", conform.format_on_save(buf) ~= nil, true)
T.eq("prettier runs beside a trusted .nvim.lua", prettier.condition(nil, { buf = buf }), true)
vim.fn.writefile({ "os.execute('x')" }, project .. "/.nvim.lua")
T.eq(
  "prettier stops when .nvim.lua changes after :trust",
  prettier.condition(nil, { buf = buf }),
  false
)
T.eq(
  "prettier is Homebrew's, never node_modules'",
  prettier.command:match("/bin/prettier$") ~= nil
    and not prettier.command:find("node_modules", 1, true),
  true
)
vim.fn.stdpath = stdpath
T.eq("LaTeX never formats on save", formats({ [".latexindent.yaml"] = {} }, "a.tex"), false)
vim.g.disable_autoformat = true
T.eq("Space u f turns format on save off", formats({ ["stylua.toml"] = {} }, "b.lua"), false)
vim.g.disable_autoformat = nil

local picker = T.config("plugins/snacks.lua").opts.picker
T.eq("references always open the list", picker.sources.lsp_references.auto_confirm, false)

T.done()
