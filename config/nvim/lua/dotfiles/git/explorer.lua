local M = {}

local reviews = {}

local function state(tab)
  reviews[tab] = reviews[tab] or { files = {}, seen = {} }
  return reviews[tab]
end

function M.record(ctx)
  state(vim.api.nvim_get_current_tabpage()).files[ctx.name] = vim.tbl_map(function(file)
    return file.path
  end, ctx.files)
end

function M.group(ctx)
  M.record(ctx)
  return require("codediff.ui.explorer.formatters").group(ctx)
end

function M.select(tab, path)
  state(tab).seen[path] = true
end

function M.clear(tab)
  reviews[tab] = nil
end

function M.progress(tab)
  local review = reviews[tab]
  if not review then
    return nil
  end
  local all, viewed = {}, 0
  for _, paths in pairs(review.files) do
    for _, path in ipairs(paths) do
      all[path] = true
    end
  end
  local total = vim.tbl_count(all)
  for path in pairs(all) do
    viewed = viewed + (review.seen[path] and 1 or 0)
  end
  return total > 0 and viewed .. "/" .. total .. " seen" or nil
end

return M
