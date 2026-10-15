local cases = {
  { "mk", "$$" },
  { "mkx2", "$x_2$" },
  { "mka + //", "$a + \\frac{}{}$" },
  { "mk//1\t2\t\t.", "$\\frac{1}{2}$." },
  { "mka//", "$\\frac{a}{}$" },
  { "mk(a+b)//", "$\\frac{a+b}{}$" },
  { "mkxtd", "$x^{}$" },
  { "mkmk", "$mk$" },
  { "\\mk", "\\mk" },
  { "beg", "\\begin{}" },
  { "dm", "\\[" },
}

local failed, i = {}, 0
local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "t", false)
end

local function step(keys, k, done)
  if k > #keys then
    return vim.defer_fn(done, 400)
  end
  feed(keys:sub(k, k))
  vim.defer_fn(function()
    step(keys, k + 1, done)
  end, 250)
end

local function next_case()
  i = i + 1
  local case = cases[i]
  if not case then
    vim.g.test_snippets = #failed == 0 and "ok" or table.concat(failed, "; ")
    return
  end
  feed("<Esc>o")
  vim.defer_fn(function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    step(case[1], 1, function()
      local line = vim.fn.getline(row)
      if line ~= case[2] then
        failed[#failed + 1] = ("%s gave %s, wanted %s"):format(case[1], line, case[2])
      end
      feed("<Esc>")
      vim.defer_fn(function()
        pcall(require("luasnip").unlink_current)
        vim.api.nvim_buf_set_lines(
          0,
          row - 1,
          vim.fn.search("^\\end{document}", "nW") - 1,
          false,
          {}
        )
        vim.api.nvim_win_set_cursor(0, { row - 1, 0 })
        next_case()
      end, 300)
    end)
  end, 300)
end

next_case()
