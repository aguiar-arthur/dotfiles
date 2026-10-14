if vim.bo.buftype ~= "" then
  return
end

require("dotfiles.markdown_preview").attach(0)

local ok, mp = pcall(require, "mini.pairs")
if ok then
  mp.map_buf(0, "i", "`", {
    action = "closeopen",
    pair = "``",
    neigh_pattern = "[^\\`].",
    register = { cr = false },
  })
end
