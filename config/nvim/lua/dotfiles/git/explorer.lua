local read = require("dotfiles.git.read")
local session = require("dotfiles.git.session")

local M = {}

local reviews = {}
local completed = function() end

local function state(tab)
  reviews[tab] = reviews[tab] or { seen = {}, hidden = {} }
  return reviews[tab]
end

function M.on_complete(callback)
  completed = callback
end

function M.clear(tab)
  if reviews[tab] and reviews[tab].hiding then
    session.hide(tab, {})
  end
  reviews[tab] = nil
end

local function count(tab)
  local files = session.files(tab)
  local review = reviews[tab] or { seen = {}, hidden = {} }
  local seen = review.seen
  local listed, viewed, total = {}, 0, 0
  for _, file in ipairs(vim.list_extend(vim.list_extend({}, files), vim.tbl_values(review.hidden))) do
    if not listed[file.path] then
      listed[file.path] = true
      total = total + 1
      viewed = viewed + (seen[file.path] and 1 or 0)
    end
  end
  return viewed, total, files
end

function M.progress(tab)
  local viewed, total = count(tab)
  return total > 0 and viewed .. "/" .. total .. " seen" or nil
end

local CELLS = 5

function M.summary(tab)
  local viewed, total, files = count(tab)
  if total == 0 then
    return nil
  end
  local added, removed = 0, 0
  for _, file in
    ipairs(vim.list_extend(vim.list_extend({}, files), vim.tbl_values(state(tab).hidden)))
  do
    local stats = file.line_stats
    if stats and not stats.binary then
      added = added + (stats.insertions or 0)
      removed = removed + (stats.deletions or 0)
    end
  end
  local full = math.floor(viewed / total * CELLS + 0.5)
  return ("+%d −%d  %s%s %d/%d seen"):format(
    added,
    removed,
    ("▰"):rep(full),
    ("▱"):rep(CELLS - full),
    viewed,
    total
  )
end

local function hide_read(tab)
  local review = state(tab)
  for _, file in ipairs(session.files(tab)) do
    if review.seen[file.path] and file.path ~= review.current then
      review.hidden[file.path] = file
    end
  end
  session.hide(tab, vim.tbl_keys(review.hidden))
end

function M.toggle_read()
  local tab = vim.api.nvim_get_current_tabpage()
  local _, total = count(tab)
  if total == 0 then
    vim.notify("Not in a review with a file list", vim.log.levels.WARN)
    return
  end
  local review = state(tab)
  review.hiding = not review.hiding
  if review.hiding then
    hide_read(tab)
    vim.notify(("Hiding the %d files read"):format(vim.tbl_count(review.hidden)))
  else
    review.hidden = {}
    session.hide(tab, {})
    vim.notify("Showing every file")
  end
  vim.cmd.redrawtabline()
end

local function remember(tab, path)
  local revisions = session.revisions(tab)
  local file = vim.iter(session.files(tab)):find(function(file)
    return file.path == path
  end)
  if revisions and file then
    read.fingerprints(revisions, { file }, function(prints)
      if prints then
        read.remember(revisions.root, path, prints[path])
      end
    end)
  end
end

local function see(tab, path)
  local review = state(tab)
  if path and not review.seen[path] then
    review.seen[path] = true
    remember(tab, path)
    if review.hiding then
      hide_read(tab)
    else
      session.redraw(tab)
    end
  end
  local viewed, total = count(tab)
  if not review.complete and total > 0 and viewed == total then
    review.complete = true
    completed(tab)
  end
end

function M.restore(tab)
  local revisions = session.revisions(tab)
  read.fingerprints(revisions, session.files(tab), function(prints)
    if not (prints and session.revisions(tab)) then
      return
    end
    local review = state(tab)
    for path in pairs(read.known(revisions.root, prints)) do
      review.seen[path] = true
    end
    local viewed, total = count(tab)
    review.complete = total > 0 and viewed == total
    session.redraw(tab)
    vim.cmd.redrawtabline()
  end)
end

local function errors(tab, path)
  local revisions = session.revisions(tab)
  local buf = revisions and vim.fn.bufnr(revisions.root .. "/" .. path)
  if not (buf and buf > 0 and vim.api.nvim_buf_is_loaded(buf)) then
    return 0
  end
  return #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
end

function M.file_row(ctx)
  local row = require("codediff.ui.explorer.formatters").file(ctx)
  local tab = vim.api.nvim_get_current_tabpage()
  if not reviews[tab] then
    tab = require("dotfiles.git.review").all()[1]
  end
  if not tab then
    return row
  end
  local marks = {}
  local count_errors = errors(tab, ctx.path)
  if count_errors > 0 then
    marks[#marks + 1] = { text = "✗" .. count_errors .. " ", hl = "DiagnosticError" }
  end
  if reviews[tab] and reviews[tab].seen[ctx.path] then
    row.left[2].segments[1].hl = "Comment"
    marks[#marks + 1] = { text = "✓ ", hl = "DiagnosticOk" }
  end
  if #marks > 0 then
    table.insert(row.right, 1, { segments = marks })
  end
  return row
end

function M.select(tab, path)
  local review = state(tab)
  if review.current and review.current ~= path then
    see(tab, review.current)
  end
  review.current = path
end

function M.next_unseen()
  local tab = vim.api.nvim_get_current_tabpage()
  local _, total, files = count(tab)
  if total == 0 then
    vim.notify("Not in a review with a file list", vim.log.levels.WARN)
    return
  end
  local review = state(tab)
  local was_complete = review.complete
  see(tab, review.current)
  if review.complete then
    if was_complete then
      vim.notify("Every file of this review was seen")
    end
    return
  end
  local current, start = session.current(tab) or {}, 0
  for i, file in ipairs(files) do
    if file.path == current.path and file.group == current.group then
      start = i
      break
    end
  end
  for step = 1, #files do
    local file = files[(start + step - 1) % #files + 1]
    if not review.seen[file.path] then
      return session.select(tab, file)
    end
  end
end

return M
