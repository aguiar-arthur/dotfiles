local M = {}

local files = {}
local seen = {}

function M.record(ctx)
  files[ctx.name] = vim.tbl_map(function(file)
    return file.path
  end, ctx.files)
end

function M.group(ctx)
  M.record(ctx)
  return require("codediff.ui.explorer.formatters").group(ctx)
end

function M.select(path)
  seen[path] = true
end

function M.clear()
  files, seen = {}, {}
end

function M.progress()
  local all, viewed = {}, 0
  for _, paths in pairs(files) do
    for _, path in ipairs(paths) do
      all[path] = true
    end
  end
  local total = vim.tbl_count(all)
  for path in pairs(all) do
    viewed = viewed + (seen[path] and 1 or 0)
  end
  return total > 0 and viewed .. "/" .. total .. " seen" or nil
end

return M
