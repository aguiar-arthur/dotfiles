local root = arg[1]
local files = vim.fn.globpath(root .. "/config/nvim", "**/*.lua", false, true)
vim.list_extend(files, vim.fn.globpath(root .. "/test", "**/*.lua", false, true))
for _, file in ipairs(files) do
  local text = table.concat(vim.fn.readfile(file), "\n")
  local parser = vim.treesitter.get_string_parser(text, "lua")
  local tree = parser:parse()[1]
  local query = vim.treesitter.query.parse("lua", "(comment) @c")
  for _, node in query:iter_captures(tree:root(), text) do
    local row = node:range()
    io.stdout:write(("%s:%d: comment\n"):format(file, row + 1))
  end
end
