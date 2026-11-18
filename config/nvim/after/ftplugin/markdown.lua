if vim.bo.buftype ~= "" then
  return
end

require("dotfiles.markdown_preview").attach(0)

-- why: the scroll animation lands on the wrong line when render-markdown redraws a table
vim.b.snacks_scroll = false

local ok, mp = pcall(require, "mini.pairs")
if ok then
  mp.map_buf(0, "i", "`", {
    action = "closeopen",
    pair = "``",
    neigh_pattern = "[^\\`].",
    register = { cr = false },
  })
end
