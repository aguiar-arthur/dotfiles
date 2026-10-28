local T = dofile(vim.env.DOT .. "/tests/lib.lua")

T.case("filetypes", function()
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
end)

local conform = T.config("plugins/formatting.lua").opts
local function formats(files, file)
  local root = T.dir(files)
  vim.cmd("edit " .. root .. "/" .. file)
  return conform.format_on_save(vim.api.nvim_get_current_buf()) ~= nil
end

T.case("prettier's parser", function()
  local args = conform.formatters.prettier.append_args
  T.eq(
    "prettier gets --parser json for .json.*",
    args(nil, { filename = "/p/a.json.tmpl" }),
    { "--parser", "json" }
  )
  T.eq("prettier keeps its own parser for .json", args(nil, { filename = "/p/package.json" }), {})
end)

T.case("style markers", function()
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
end)

T.case("prettier and a trusted .nvim.lua", function()
  local state = T.dir()
  local stdpath = vim.fn.stdpath
  T.stub(vim.fn, "stdpath", function(what)
    return what == "state" and state or stdpath(what)
  end)
  local function trust(root)
    assert(vim.secure.trust({ action = "allow", path = root .. "/.nvim.lua" }))
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
    "prettier comes from PATH, never node_modules'",
    prettier.command():match("prettier$") ~= nil
      and not prettier.command():find("node_modules", 1, true),
    true
  )
end)

T.case("no format on save", function()
  T.eq("SCSS has no style marker, so it never formats on save", formats({}, "a.scss"), false)
  T.eq("LaTeX never formats on save", formats({ [".latexindent.yaml"] = {} }, "a.tex"), false)
  T.stub(vim.g, "disable_autoformat", true)
  T.eq("Space u f turns format on save off", formats({ ["stylua.toml"] = {} }, "b.lua"), false)
end)

T.case("the references list", function()
  local picker = T.config("plugins/snacks.lua").opts.picker
  T.eq("references always open the list", picker.sources.lsp_references.auto_confirm, false)
end)

T.done()
