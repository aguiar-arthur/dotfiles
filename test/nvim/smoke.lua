local h = dofile(vim.env.TEST_ROOT .. "/test/lib/harness.lua")

h.ready()

h.run("startup prints no errors", function()
  local out = h.messages()
  local bad = {}
  for _, row in ipairs(vim.split(out, "\n", { plain = true })) do
    if row:match("^E%d+:") or row:match("Error executing") or row:match("Failed to") then
      bad[#bad + 1] = row
    end
  end
  assert(#bad == 0, table.concat(bad, "\n"))
end)

h.run("every plugin is installed", function()
  local missing = {}
  for _, plugin in pairs(require("lazy").plugins()) do
    if not plugin._.installed then
      missing[#missing + 1] = plugin.name
    end
  end
  assert(#missing == 0, "not installed: " .. table.concat(missing, ", "))
end)

h.run("every plugin matches lazy-lock.json", function()
  local lock = vim.json.decode(
    table.concat(vim.fn.readfile(vim.fn.stdpath("config") .. "/lazy-lock.json"), "\n")
  )
  local drift = {}
  for _, plugin in pairs(require("lazy").plugins()) do
    local entry = lock[plugin.name]
    if entry and plugin._.installed then
      local head = vim.trim(vim.fn.system({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }))
      if head ~= entry.commit then
        drift[#drift + 1] = plugin.name
      end
    end
  end
  assert(#drift == 0, "differs from the lock: " .. table.concat(drift, ", "))
end)

h.run("colorscheme is dracula", function()
  assert(vim.g.colors_name == "dracula", tostring(vim.g.colors_name))
end)

h.run("long lines wrap by default", function()
  assert(vim.o.wrap and vim.o.linebreak)
end)

h.run("every after/lsp server resolves to a command", function()
  vim.cmd("edit " .. vim.fn.fnameescape(vim.env.TEST_ROOT .. "/config/nvim/init.lua"))
  vim.wait(3000, function()
    return false
  end)
  local problems = {}
  local files = vim.fn.glob(vim.fn.stdpath("config") .. "/after/lsp/*.lua", false, true)
  assert(#files > 0, "no server definitions found")
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local config = vim.lsp.config[name]
    if not config or not config.cmd then
      problems[#problems + 1] = name .. ": no cmd"
    end
  end
  assert(#problems == 0, table.concat(problems, "\n"))
end)

h.run("checkhealth reports no errors for core modules", function()
  vim.cmd("checkhealth vim.lsp vim.treesitter lazy")
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  local bad = {}
  for _, row in ipairs(vim.split(text, "\n", { plain = true })) do
    if row:match("ERROR") then
      bad[#bad + 1] = vim.trim(row)
    end
  end
  assert(#bad == 0, table.concat(bad, "\n"))
end)

h.finish()
