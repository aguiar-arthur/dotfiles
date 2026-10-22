local M = {}

function M.selection()
  local mode = vim.fn.mode()
  local from, to = vim.fn.getpos("v"), vim.fn.getpos(".")
  local region = { from, to }
  if from[2] > to[2] or (from[2] == to[2] and from[3] > to[3]) then
    from, to = to, from
  end
  local first, last = from[3], math.min(to[3], math.max(1, #vim.fn.getline(to[2])))
  if mode == "V" then
    first, last = 1, math.max(1, #vim.fn.getline(to[2]))
  elseif mode == "\22" then
    local corners = { vim.fn.virtcol("v"), vim.fn.getcurpos()[5] }
    if corners[2] >= vim.v.maxcol then
      corners[2] = 1
      for lnum = from[2], to[2] do
        corners[2] = math.max(corners[2], vim.fn.virtcol({ lnum, "$" }) - 1)
      end
    end
    first, last = math.min(unpack(corners)), math.max(unpack(corners))
  end
  local lines = vim.fn.getregion(region[1], region[2], {
    type = mode == "\22" and mode .. (last - first + 1) or mode,
  })

  local file = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(0, ".git")
  local path = root and vim.fs.relpath(root, file) or vim.fn.fnamemodify(file, ":~")
  local location = ("%s:%d:%d-%d:%d"):format(path, from[2], first, to[2], last)
  local code = table.concat(lines, "\n")
  local fence = "```"
  while code:find(fence, 1, true) do
    fence = fence .. "`"
  end

  vim.fn.setreg("+", ("%s\n\n%s%s\n%s\n%s\n"):format(location, fence, vim.bo.filetype, code, fence))
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
  vim.notify("Copied " .. location)
end

return M
