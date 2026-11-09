local M = {}

function M.open(name, opts)
  return function()
    Snacks.picker[name](opts)
  end
end

return M
