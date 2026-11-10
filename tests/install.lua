local T = dofile(vim.env.DOT .. "/tests/lib.lua")

T.case("mason", function()
  local mason = require("dotfiles.install.mason")
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

T.case("a step that crashes", function()
  local ran, quit = {}, nil
  for _, step in ipairs({ "mason", "parsers", "spell" }) do
    T.stub(require("dotfiles.install." .. step), "install", function()
      ran[#ran + 1] = step
      if step == "parsers" then
        error("boom")
      end
    end)
  end
  T.stub(vim, "cmd", function(command)
    quit = command
  end)
  T.stub(io, "stdout", { write = function() end })
  require("dotfiles.install").run()
  T.eq("install: the steps after a crash still run", ran, { "mason", "parsers", "spell" })
  T.eq("install: a crash ends Neovim with an error", quit, "cquit 1")
end)

T.case("spell files", function()
  local spell_files = require("dotfiles.install.spell").files
  local spell = T.dir()
  local files = spell_files({ "en_us", "pt_br" }, spell)
  T.eq("spell: only non-English files are fetched", #files, 1)
  T.eq(
    "spell: pt_br comes from the Vim mirror",
    files[1] and files[1].url:match("pt%.utf%-8%.spl$") ~= nil,
    true
  )
  vim.fn.writefile({}, spell .. "/pt.utf-8.spl")
  T.eq("spell: a file already there is skipped", spell_files({ "pt_br" }, spell), {})
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
