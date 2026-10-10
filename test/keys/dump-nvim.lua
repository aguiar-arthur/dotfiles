local h = dofile(vim.env.TEST_ROOT .. "/test/lib/harness.lua")

h.ready()
vim.cmd("edit " .. vim.fn.fnameescape(vim.env.TEST_FILE))
vim.wait(4000, function()
  return false
end)
vim.api.nvim_exec_autocmds("LspAttach", {
  buffer = vim.api.nvim_get_current_buf(),
  data = { client_id = 0 },
})

local rows = {}
for _, mode in ipairs({ "n", "x" }) do
  for _, scope in ipairs({ "global", "buffer" }) do
    local maps = scope == "global" and vim.api.nvim_get_keymap(mode)
      or vim.api.nvim_buf_get_keymap(0, mode)
    for _, map in ipairs(maps) do
      if map.lhs:sub(1, 1) == " " and #map.lhs > 1 then
        local key = map.lhs:sub(2):gsub(" ", "<Space>")
        local action = map.desc or map.rhs or "?"
        rows[#rows + 1] = table.concat({ mode, scope, key, action }, "\t")
      end
    end
  end
end
table.sort(rows)
vim.fn.writefile(rows, vim.env.TEST_OUT)
vim.cmd("qa!")
