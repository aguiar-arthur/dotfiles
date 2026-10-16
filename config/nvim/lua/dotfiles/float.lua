local M = {}

function M.win(title)
  return {
    position = "float",
    width = 0.92,
    height = 0.9,
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    backdrop = 60,
  }
end

return M
