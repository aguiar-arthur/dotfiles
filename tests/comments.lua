local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local function tracked(pattern)
  local files = vim.fn.systemlist({
    "git",
    "-C",
    vim.env.DOT,
    "ls-files",
    "--cached",
    "--others",
    "--exclude-standard",
    pattern,
  })
  return vim.tbl_filter(function(file)
    return vim.fn.filereadable(vim.env.DOT .. "/" .. file) == 1
  end, files)
end

local function comments(lang, relative)
  local source = table.concat(vim.fn.readfile(vim.env.DOT .. "/" .. relative), "\n")
  local tree = vim.treesitter.get_string_parser(source, lang):parse()[1]
  local found = {}
  for _, node in vim.treesitter.query.parse(lang, "(comment) @c"):iter_captures(tree:root(), source) do
    local text = vim.treesitter.get_node_text(node, source)
    if not text:match("^#!") then
      found[#found + 1] = ("%s:%d: %s"):format(relative, node:start() + 1, text)
    end
  end
  return found
end

local function powershell_comment(line)
  if line:find("<#", 1, true) then
    return true
  end
  local quote
  local i = 1
  while i <= #line do
    local c = line:sub(i, i)
    if quote then
      if c == "`" and quote == '"' then
        i = i + 1
      elseif c == quote then
        if line:sub(i + 1, i + 1) == quote then
          i = i + 1
        else
          quote = nil
        end
      end
    elseif c == "'" or c == '"' then
      quote = c
    elseif c == "#" then
      return true
    end
    i = i + 1
  end
  return false
end

T.case("no comments in Lua", function()
  local found = {}
  for _, file in ipairs(tracked("*.lua")) do
    vim.list_extend(found, comments("lua", file))
  end
  T.eq("Lua has no comments, trailing ones included", found, {})
end)

T.case("no comments in shell", function()
  if not pcall(vim.treesitter.language.add, "bash") then
    T.skip("no trailing comments in shell", "the bash parser is not installed")
    return
  end
  local files = tracked("*.sh")
  table.insert(files, "config/zsh/dotfiles.zsh")
  local found = {}
  for _, file in ipairs(files) do
    vim.list_extend(found, comments("bash", file))
  end
  T.eq("shell has no comments, trailing ones included", found, {})
end)

T.case("no comments in PowerShell", function()
  local found = {}
  for _, file in ipairs(tracked("*.ps1")) do
    for number, line in ipairs(vim.fn.readfile(vim.env.DOT .. "/" .. file)) do
      if powershell_comment(line) then
        found[#found + 1] = ("%s:%d: %s"):format(file, number, line)
      end
    end
  end
  T.eq("PowerShell has no comments, trailing ones included", found, {})
  T.eq("PowerShell: a # inside a string is not a comment", {
    powershell_comment([[$a = "x # y"; $b = 'it''s # fine']]),
    powershell_comment([[$c = "say `"#`" here"]]),
    powershell_comment([[$d = 1  # why]]),
  }, { false, false, true })
end)

T.done()
