local T = dofile(vim.env.DOT .. "/tests/lib.lua")

T.case("mason", function()
  local mason = require("dotfiles.mason")
  local settings = { mason_tools = { "shellcheck" }, mason_servers = { "lua_ls" } }
  T.eq(
    "mason: servers become package names",
    mason.wanted(settings),
    { "shellcheck", "lua-language-server" }
  )
  T.stub(package.loaded, "mason-registry", {
    get_installed_package_names = function()
      return { "shellcheck" }
    end,
  })
  local packages = T.dir({
    ["shellcheck/venv/bin/activate"] = {},
    ["ruff/venv/bin/python"] = {},
    ["taplo/bin/taplo"] = {},
  })
  vim.fn.setfperm(packages .. "/ruff/venv/bin/python", "rwxr-xr-x")
  T.eq(
    "mason: lists what is not installed",
    mason.missing(settings, T.dir()),
    { "lua-language-server" }
  )
  T.eq("mason: a venv without its Python is broken", mason.broken(packages), { shellcheck = true })
  T.eq(
    "mason: a broken package counts as missing, so install reinstalls it",
    mason.missing(settings, packages),
    { "shellcheck", "lua-language-server" }
  )
end)

T.case("spell files", function()
  local install = require("dotfiles.install")
  local spell = T.dir()
  local files = install.spell_files({ "en_us", "pt_br" }, spell)
  T.eq("spell: only non-English files are fetched", #files, 1)
  T.eq(
    "spell: pt_br comes from the Vim mirror",
    files[1] and files[1].url:match("pt%.utf%-8%.spl$") ~= nil,
    true
  )
  vim.fn.writefile({}, spell .. "/pt.utf-8.spl")
  T.eq("spell: a file already there is skipped", install.spell_files({ "pt_br" }, spell), {})
end)

T.case("treesitter parsers", function()
  local treesitter = require("dotfiles.treesitter")
  T.stub(package.loaded, "nvim-treesitter", {
    get_installed = function()
      return { "lua", "bash" }
    end,
  })
  T.eq("treesitter: lists the parsers not installed", treesitter.missing({ "lua", "rust", "go" }), {
    "rust",
    "go",
  })
  T.eq("treesitter: none when all are there", treesitter.missing({ "bash" }), {})
end)

T.done()
