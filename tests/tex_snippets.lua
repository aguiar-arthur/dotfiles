local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local ls = require("luasnip")
local snippets, autosnippets = dofile(vim.fn.stdpath("config") .. "/snippets/tex.lua")

local function expand(snippet)
  vim.cmd("enew")
  ls.snip_expand(snippet, { expand_params = { captures = { "a", "1", "2" } } })
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  ls.unlink_current()
  return text
end

local function find(list, trigger)
  return vim.iter(list):find(function(snippet)
    return snippet.trigger == trigger
  end)
end

T.case("every LaTeX snippet expands", function()
  local broken = {}
  for kind, list in pairs({ snippet = snippets, autosnippet = autosnippets }) do
    for _, snippet in ipairs(list) do
      local ok, err = pcall(expand, snippet)
      if not ok then
        broken[#broken + 1] = ("%s %s: %s"):format(
          kind,
          snippet.trigger,
          tostring(err):match("^[^\n]*")
        )
      end
    end
  end
  T.eq("snippets: none fails to expand", broken, {})
end)

T.case("no trigger is defined twice", function()
  local twice = {}
  for kind, list in pairs({ snippet = snippets, autosnippet = autosnippets }) do
    local seen = {}
    for _, snippet in ipairs(list) do
      if seen[snippet.trigger] then
        twice[#twice + 1] = kind .. " " .. snippet.trigger
      end
      seen[snippet.trigger] = true
    end
  end
  table.sort(twice)
  T.eq("snippets: a trigger of one kind is defined once", twice, {})
end)

T.case("what the common snippets type", function()
  local cases = {
    { autosnippets, "mk", "$$" },
    { autosnippets, ";a", "\\alpha" },
    { autosnippets, ";O", "\\Omega" },
    { autosnippets, "->", "\\to" },
    { autosnippets, "RR", "\\mathbb{R}" },
    { autosnippets, "xx", "\\times" },
    { autosnippets, "sum", "\\sum_{i=1}^{n} " },
    { autosnippets, "sq", "\\sqrt{}" },
    { autosnippets, "//", "\\frac{}{}" },
    { autosnippets, "%f[%a\\]sin", "\\sin" },
    { snippets, "cit", "\\cite{}" },
    { snippets, "ref", "\\ref{}" },
    { snippets, "pau", "\\pause" },
  }
  for _, case in ipairs(cases) do
    local snippet = find(case[1], case[2])
    T.eq("snippets: " .. case[2] .. " exists", snippet ~= nil, true)
    if snippet then
      T.eq("snippets: " .. case[2] .. " types " .. case[3], expand(snippet), case[3])
    end
  end
  local contains = {
    { "eqn", { "\\begin{equation*}", "\\end{equation*}" } },
    { "ite", { "\\begin{itemize}", "\\item " } },
    { "fig", { "\\begin{figure}[htbp]", "\\includegraphics[width=0.8\\linewidth]" } },
    { "doc", { "\\documentclass[12pt,a4paper]{article}", "\\end{document}" } },
    { "abnt", { "\\documentclass[12pt, openright", "\\imprimircapa" } },
  }
  for _, case in ipairs(contains) do
    local snippet = find(snippets, case[1])
    local text = snippet and expand(snippet) or ""
    for _, part in ipairs(case[2]) do
      T.eq("snippets: " .. case[1] .. " has " .. part, text:find(part, 1, true) ~= nil, true)
    end
  end
end)

T.done()
