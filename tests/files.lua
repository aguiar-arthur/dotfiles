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
local function formats(files, file, quiet_ft)
  local root = T.dir(files)
  if quiet_ft then
    vim.cmd("noautocmd edit " .. root .. "/" .. file)
    vim.cmd("noautocmd setlocal filetype=" .. quiet_ft)
  else
    vim.cmd("edit " .. root .. "/" .. file)
  end
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
  T.eq(
    "zsh with an .editorconfig [*.zsh] formats",
    formats({ [".editorconfig"] = { "[*.zsh]" } }, "a.zsh"),
    true
  )
  T.eq(
    "zsh with only [*.sh] is left alone",
    formats({ [".editorconfig"] = { "[*.sh]" } }, "a.zsh"),
    false
  )
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
    "Markdown with a .markdownlint.yaml formats on save",
    formats({ [".markdownlint.yaml"] = {} }, "a.md"),
    true
  )
  T.eq("Python with ruff.toml formats on save", formats({ ["ruff.toml"] = {} }, "a.py"), true)
  T.eq(
    "bash with an .editorconfig [*.{sh,bash}] formats",
    formats({ [".editorconfig"] = { "[*.{sh,bash}]" } }, "a.bash"),
    true
  )
  T.eq("TOML with taplo.toml formats on save", formats({ ["taplo.toml"] = {} }, "a.toml"), true)
  T.eq("TOML with .taplo.toml formats on save", formats({ [".taplo.toml"] = {} }, "a.toml"), true)
  T.eq("TOML without a taplo config is left alone", formats({}, "a.toml"), false)
  -- why: a Clojure buffer with its FileType autocmds would start a real clojure-lsp.
  T.eq(
    "Clojure with cljfmt.edn formats on save",
    formats({ ["cljfmt.edn"] = {} }, "src/a.clj", "clojure"),
    true
  )
  T.eq(
    "Clojure with :cljfmt in .lsp/config.edn formats on save",
    formats({ [".lsp/config.edn"] = { "{:cljfmt {:indents {}}}" } }, "src/a.clj", "clojure"),
    true
  )
  T.eq(
    "Clojure with a .lsp/config.edn but no :cljfmt is left alone",
    formats({ [".lsp/config.edn"] = { "{:linters {}}" } }, "src/a.clj", "clojure"),
    false
  )
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
