local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local root = T.dir({
  ["a.lua"] = { "local a = 1", "local b = 2", "local c = 3", "local d = 4", "local e = 5" },
  ["a.tex"] = { "\\documentclass{article}" },
  ["a.md"] = {
    "# Title",
    "",
    "Math $x^2$.",
    "",
    "| a | b |",
    "|---|---|",
    "| 1 | 2 |",
    "",
    "<kbd>Ctrl</kbd>",
  },
  [".rumdl.toml"] = {},
})

T.case("]d and ]e", function()
  vim.cmd("edit " .. root .. "/a.lua")
  local ns = vim.api.nvim_create_namespace("test")
  vim.diagnostic.set(ns, 0, {
    { lnum = 1, col = 0, message = "warning", severity = vim.diagnostic.severity.WARN },
    { lnum = 3, col = 0, message = "error", severity = vim.diagnostic.severity.ERROR },
  })
  local function jump(lhs)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.fn.maparg(lhs, "n", false, true).callback()
    return vim.api.nvim_win_get_cursor(0)[1]
  end
  T.eq("]d goes to the next diagnostic", jump("]d"), 2)
  T.eq("]e skips warnings and goes to the error", jump("]e"), 4)
end)

local copied
local function copy(lines)
  copied = table.concat(lines, "\n")
end
vim.g.clipboard = {
  name = "test",
  copy = { ["+"] = copy, ["*"] = copy },
  paste = {
    ["+"] = function()
      return {}
    end,
    ["*"] = function()
      return {}
    end,
  },
}
T.case("Space c s", function()
  vim.cmd("edit " .. root .. "/a.lua")
  T.stub(vim, "notify", function() end)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.api.nvim_feedkeys(vim.keycode("<leader>cs"), "mx", false)
  local want = "a.lua:2:1-2:11\n\n```lua\nlocal b = 2\n```\n"
  T.eq("Space c s in normal mode shares the line", copied and copied:sub(-#want), want)
  T.eq("Space c s returns to normal mode", vim.api.nvim_get_mode().mode, "n")
end)

T.case("TeX keys", function()
  vim.cmd("edit " .. root .. "/a.tex")
  T.eq("TeX: ,lw counts words", vim.fn.maparg(",lw", "n", false, true).desc, "Count words")
  T.eq("TeX: lines are not hard-wrapped", vim.bo.textwidth, 0)
end)

T.case("Markdown keys", function()
  vim.cmd("edit " .. root .. "/a.md")
  T.eq(
    "Markdown: ,p is the preview",
    vim.fn.maparg(",p", "n", false, true).desc,
    "Markdown preview (browser)"
  )
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.api.nvim_feedkeys("i`", "tx", false)
  T.eq("Markdown: a backtick gets its pair", vim.fn.getline(2), "``")
  vim.cmd("silent undo")
end)

T.case("the Markdown preview", function()
  vim.cmd("edit " .. root .. "/a.md")
  if vim.fn.executable("pandoc") == 1 then
    local opened
    T.stub(vim.ui, "open", function(path)
      opened = path
    end)
    vim.fn.maparg(",p", "n", false, true).callback()
    vim.wait(15000, function()
      return opened ~= nil
    end)
    local html = opened and table.concat(vim.fn.readfile(opened), "\n") or ""
    T.eq(",p opens an HTML page with MathML", html:find("<math", 1, true) ~= nil, true)
    T.eq(",p keeps tables", html:find("<table", 1, true) ~= nil, true)
    T.eq(",p renders the HTML in the Markdown", html:find("<kbd>Ctrl</kbd>", 1, true) ~= nil, true)
    local before = opened and vim.uv.fs_stat(opened).mtime
    vim.cmd("silent write")
    vim.wait(15000, function()
      local now = vim.uv.fs_stat(opened).mtime
      return now.sec ~= before.sec or now.nsec ~= before.nsec
    end)
    local after = opened and vim.uv.fs_stat(opened).mtime
    T.eq(
      "saving rebuilds the preview",
      after and (after.sec ~= before.sec or after.nsec ~= before.nsec),
      true
    )
  else
    T.skip("the Markdown preview", "pandoc not installed")
  end
end)

T.case("rumdl and every <Cmd> key", function()
  vim.cmd("edit " .. root .. "/a.md")
  require("lazy").load({ plugins = { "which-key.nvim" } })
  if vim.fn.executable("rumdl") == 1 then
    vim.wait(15000, function()
      return #vim.lsp.get_clients({ bufnr = 0, name = "rumdl" }) > 0 and vim.bo.formatexpr == ""
    end)
    T.eq("rumdl attaches to Markdown", #vim.lsp.get_clients({ bufnr = 0, name = "rumdl" }), 1)
    T.eq("gq keeps wrapping: formatexpr is cleared", vim.bo.formatexpr, "")
  else
    T.skip("rumdl attaches to Markdown", "rumdl not installed")
  end
  local unknown = {}
  for _, mode in ipairs({ "n", "x" }) do
    local maps =
      vim.list_extend(vim.api.nvim_get_keymap(mode), vim.api.nvim_buf_get_keymap(0, mode))
    for _, m in ipairs(maps) do
      local command = (m.rhs or ""):match("^<[Cc][Mm][Dd]>[%s%.%%']*(%a+)")
      if command and vim.fn.exists(":" .. command) == 0 then
        unknown[#unknown + 1] = m.lhs:gsub(" ", "<Space>") .. " runs :" .. command
      end
    end
  end
  T.eq("every <Cmd> key runs a command that exists (LSP keys included)", unknown, {})
end)

T.case("Claude keys in the file tree", function()
  vim.cmd("enew")
  vim.bo.filetype = "snacks_picker_list"
  T.eq(
    "Claude: Space a b in the file tree adds the item under the cursor",
    vim.fn.maparg("<leader>ab", "n", false, true).desc,
    "Add the file under the cursor to Claude"
  )
  T.eq(
    "Claude: Space a B in the file tree adds it to the last session",
    vim.fn.maparg("<leader>aB", "n", false, true).desc,
    "Add the file under the cursor to the last Claude session"
  )
end)

T.case("Space d t", function()
  local todo = vim.iter(T.config("plugins/editor.lua")):find(function(spec)
    return spec[1] == "folke/todo-comments.nvim"
  end)
  T.eq(
    "Space d t loads todo-comments, which adds the picker",
    vim.iter(todo.keys):any(function(key)
      return key[1] == "<leader>dt"
    end),
    true
  )
end)

local function rhs(spec, lhs)
  return vim.iter(spec.keys):find(function(key)
    return key[1] == lhs and key.mode ~= "x"
  end)[2]
end
local function spec_of(file, name)
  return vim.iter(T.config(file)):find(function(spec)
    return spec[1] == name and spec.keys
  end)
end

T.case("]f and ]a", function()
  local textobjects = spec_of("plugins/editor.lua", "nvim-treesitter/nvim-treesitter-textobjects")
  local funcs = T.dir({
    ["f.lua"] = { "local function a(x, y)", "  return x", "end", "", "local function b()", "end" },
  })
  vim.cmd("edit " .. funcs .. "/f.lua")
  require("lazy").load({ plugins = { "nvim-treesitter-textobjects" } })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  rhs(textobjects, "]f")()
  T.eq("]f goes to the next function", vim.api.nvim_win_get_cursor(0)[1], 5)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  rhs(textobjects, "]a")()
  T.eq("]a goes to the next argument", vim.api.nvim_win_get_cursor(0), { 1, 17 })
end)

T.case(",dp", function()
  local dap_keys = T.config("plugins/debug.lua")[1]
  local logged
  T.stub(package.loaded, "dap", {
    set_breakpoint = function(condition, hit, message)
      logged = { condition or false, hit or false, message }
    end,
  })
  local answer
  T.stub(vim.ui, "input", function(_, callback)
    callback(answer)
  end)
  answer = "x is {x}"
  rhs(dap_keys, "<localleader>dp")()
  T.eq(",dp sets a log point with the message", logged, { false, false, "x is {x}" })
  logged, answer = nil, ""
  rhs(dap_keys, "<localleader>dp")()
  T.eq(",dp with no message sets nothing", logged, nil)
end)

T.case("]T and [T", function()
  local jumped
  T.stub(package.loaded, "neotest", {
    jump = {
      next = function(opts)
        jumped = { "next", opts.status }
      end,
      prev = function(opts)
        jumped = { "prev", opts.status }
      end,
    },
  })
  local tests = vim.iter(T.config("plugins/test.lua")):find(function(spec)
    return spec[1] == "nvim-neotest/neotest"
  end)
  rhs(tests, "]T")()
  T.eq("]T goes to the next failed test", jumped, { "next", "failed" })
  rhs(tests, "[T")()
  T.eq("[T goes to the previous failed test", jumped, { "prev", "failed" })
end)

T.case("Space R", function()
  local grug
  T.stub(package.loaded, "grug-far", {
    open = function(opts)
      grug = opts
    end,
  })
  rhs(spec_of("plugins/editor.lua", "MagicDuck/grug-far.nvim"), "<leader>R")()
  T.eq("Space R replaces with ast-grep", grug and grug.engine, "astgrep")
end)

T.case("Space c l", function()
  local browsed
  T.stub(Snacks, "gitbrowse", function(opts)
    browsed = opts.what
    opts.open("https://example.com/blob/abc/a.lua#L1-L1")
  end)
  copied = nil
  vim.fn.maparg("<leader>cl", "n", false, true).callback()
  T.eq(
    "Space c l copies a permalink",
    { browsed, copied },
    { "permalink", "https://example.com/blob/abc/a.lua#L1-L1" }
  )
end)

T.case("the LSP keys", function()
  T.eq(
    "Neovim's own grn / gra / grx stay",
    vim.tbl_map(function(lhs)
      return vim.fn.maparg(lhs, "n") ~= ""
    end, { "grn", "gra", "grx" }),
    { true, true, true }
  )
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  local lsp_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(lsp_buf)
  vim.api.nvim_exec_autocmds("LspAttach", {
    group = "user_lsp_attach",
    buffer = lsp_buf,
    data = { client_id = -1 },
  })
  local function buffer_map(lhs)
    local m = vim.fn.maparg(lhs, "n", false, true)
    return m.buffer == 1 and m.callback or nil
  end
  local opened, warned, offered = {}, {}, {}
  T.stub(
    Snacks,
    "picker",
    setmetatable({}, {
      __index = function(_, source)
        return function()
          opened[#opened + 1] = source
        end
      end,
    })
  )
  T.stub(vim.lsp, "get_clients", function(filter)
    return vim.tbl_contains(offered, filter.method) and { {} } or {}
  end)
  T.stub(vim, "notify", function(msg)
    warned[#warned + 1] = msg
  end)
  local function press(lhs)
    opened = {}
    buffer_map(lhs)()
    return opened[1] or false
  end
  offered = {
    "textDocument/definition",
    "textDocument/references",
    "textDocument/implementation",
    "textDocument/typeDefinition",
    "textDocument/declaration",
    "textDocument/prepareCallHierarchy",
    "textDocument/documentSymbol",
    "workspace/symbol",
  }
  T.eq(
    "gd / gr* and Space l open their Snacks pickers when a server offers them",
    vim.tbl_map(press, {
      "gd",
      "grr",
      "gri",
      "grt",
      "<leader>ld",
      "<leader>lD",
      "<leader>li",
      "<leader>lt",
      "<leader>lr",
      "<leader>lc",
      "<leader>lC",
      "<leader>ls",
      "<leader>lS",
    }),
    {
      "lsp_definitions",
      "lsp_references",
      "lsp_implementations",
      "lsp_type_definitions",
      "lsp_definitions",
      "lsp_declarations",
      "lsp_implementations",
      "lsp_type_definitions",
      "lsp_references",
      "lsp_incoming_calls",
      "lsp_outgoing_calls",
      "lsp_symbols",
      "lsp_workspace_symbols",
    }
  )
  offered = {}
  T.eq(
    "Space l c / l C warn instead of an empty picker where no server has a call hierarchy",
    { press("<leader>lc"), press("<leader>lC"), warned },
    {
      false,
      false,
      {
        "No language server here offers a call hierarchy",
        "No language server here offers a call hierarchy",
      },
    }
  )
  T.eq(
    "Space l a / A / n / l / k / I / R are mapped on attach",
    vim.tbl_map(function(lhs)
      return buffer_map(lhs) ~= nil or vim.fn.maparg(lhs, "n") ~= ""
    end, {
      "<leader>la",
      "<leader>lA",
      "<leader>ln",
      "<leader>ll",
      "<leader>lk",
      "<leader>lI",
      "<leader>lR",
    }),
    { true, true, true, true, true, true, true }
  )
  T.eq("Space l a works on a selection", vim.fn.maparg("<leader>la", "x", false, true).buffer, 1)
  T.eq("gr has no key of its own, so grn / gra / grx still work", buffer_map("gr"), nil)

  T.stub(vim.lsp, "get_client_by_id", function()
    return {
      server_capabilities = {
        codeActionProvider = { codeActionKinds = { "source.organizeImports" } },
      },
    }
  end)
  local function organize_imports_desc(own_key)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    if own_key then
      vim.keymap.set("n", "<localleader>o", "<Nop>", { buffer = buf, desc = "Raise form" })
    end
    vim.api.nvim_exec_autocmds("LspAttach", {
      group = "user_lsp_attach",
      buffer = buf,
      data = { client_id = 1 },
    })
    return vim.fn.maparg("<localleader>o", "n", false, true).desc
  end
  T.eq(
    ",o organizes imports when the server offers it and the file type has no ,o",
    organize_imports_desc(false),
    "Organize imports"
  )
  T.eq(
    ",o stays the file type's own key when it has one, whatever loads first",
    organize_imports_desc(true),
    "Raise form"
  )
end)

T.case("moving lines", function()
  local function move(keys, cursor)
    vim.cmd("enew!")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c", "d" })
    vim.api.nvim_win_set_cursor(0, { cursor, 0 })
    vim.cmd("messages clear")
    vim.api.nvim_feedkeys(vim.keycode(keys), "tx", false)
    return {
      table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false)),
      vim.trim(vim.fn.execute("messages")),
    }
  end
  T.eq("Alt-j moves the line down", move("<A-j>", 1), { "bacd", "" })
  T.eq("Alt-k moves the line up", move("<A-k>", 2), { "bacd", "" })
  T.eq("a count moves the line further down", move("2<A-j>", 1), { "bcad", "" })
  T.eq("a count moves the line further up", move("2<A-k>", 4), { "adbc", "" })
  T.eq("Alt-j on the last line stays quiet", move("<A-j>", 4), { "abcd", "" })
  T.eq("Alt-k on the first line stays quiet", move("<A-k>", 1), { "abcd", "" })
  T.eq("Alt-j moves the selection", move("Vj<A-j><Esc>", 1), { "cabd", "" })
  T.eq("Alt-k moves the selection", move("Vj<A-k><Esc>", 2), { "bcad", "" })
  T.eq("a count moves the selection further", move("Vj2<A-j><Esc>", 1), { "cdab", "" })
  T.eq("Alt-j on a selection at the end stays quiet", move("Vj<A-j><Esc>", 3), { "abcd", "" })
  T.eq("Alt-k on a selection at the top stays quiet", move("Vj<A-k><Esc>", 1), { "abcd", "" })

  local function untouched(keys, cursor, lines)
    vim.cmd("enew!")
    vim.bo.indentexpr = "0"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { cursor, 0 })
    local tick = vim.b.changedtick
    vim.api.nvim_feedkeys(vim.keycode(keys), "tx", false)
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), lines)
      and vim.b.changedtick == tick
  end
  T.eq(
    "Alt-j on the last line leaves its indent alone",
    untouched("<A-j>", 2, { "a", "    b" }),
    true
  )
  T.eq(
    "Alt-k on the first line leaves its indent alone",
    untouched("<A-k>", 1, { "    a", "b" }),
    true
  )
  T.eq(
    "Alt-j on a selection at the end leaves its indent alone",
    untouched("Vj<A-j><Esc>", 1, { "    a", "    b" }),
    true
  )
  T.eq(
    "Alt-k on a selection at the top leaves its indent alone",
    untouched("Vj<A-k><Esc>", 1, { "    a", "    b" }),
    true
  )
end)

T.case("notes through a link", function()
  local real = vim.uv.fs_realpath(T.dir())
  local link = vim.fn.tempname()
  vim.uv.fs_symlink(real, link)
  T.stub(require("config.settings").notes, "dir", link)
  local obsidian = vim.iter(T.config("plugins/markdown.lua")):find(function(spec)
    return spec[1] == "obsidian-nvim/obsidian.nvim"
  end)
  local patterns = obsidian.event[1].pattern
  patterns = type(patterns) == "table" and patterns or { patterns }
  T.eq("notes: obsidian loads for a note opened through the link", patterns[1], link .. "/*")
  T.eq(
    "notes: obsidian loads for a note named by the folder's real path (cd ~/notes && nvim a.md)",
    vim.tbl_contains(patterns, real .. "/*"),
    true
  )
end)

T.case("visual keys leave select mode alone", function()
  local function modes(lhs)
    return { vim.fn.maparg(lhs, "x") ~= "", vim.fn.maparg(lhs, "s") ~= "" }
  end
  vim.cmd("edit " .. root .. "/a.lua")
  local gitsigns = vim.iter(T.config("plugins/git.lua")):find(function(spec)
    return spec[1] == "lewis6991/gitsigns.nvim"
  end)
  gitsigns.opts.on_attach(vim.api.nvim_get_current_buf())
  T.eq("Space g s stages a selection, never a snippet's placeholder", modes(" gs"), { true, false })
  T.eq("Space g r resets a selection, never a snippet's placeholder", modes(" gr"), { true, false })
  T.eq("Space g O opens a selection, never a snippet's placeholder", modes(" gO"), { true, false })
end)

T.done()
