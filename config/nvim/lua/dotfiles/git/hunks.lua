local session = require("dotfiles.git.session")

local M = {}

local function command(revisions)
  local diff = { "git", "-C", revisions.root, "diff", "--no-color", "--no-ext-diff" }
  local base, target = revisions.base, revisions.target
  if not base then
    return vim.list_extend(diff, { "HEAD" })
  end
  if target == ":0" then
    return vim.list_extend(diff, { "--cached", base })
  end
  if target == "WORKING" or not target then
    return vim.list_extend(diff, { base })
  end
  return vim.list_extend(diff, { base, target })
end

function M.parse(text)
  local hunks, path, hunk, old, new = {}, nil, nil, 0, 0
  for line in (text .. "\n"):gmatch("(.-)\n") do
    if line:match("^diff %-%-git ") then
      path, hunk = line:match(" b/(.+)$"), nil
    elseif line:match("^%+%+%+ b/") then
      path = line:sub(7)
    elseif line:match("^@@") then
      local a, c, scope = line:match("^@@ %-(%d+)[,%d]* %+(%d+)[,%d]* @@ ?(.*)$")
      old, new = tonumber(a), tonumber(c)
      hunk = { path = path, scope = scope or "", lines = { line } }
      hunks[#hunks + 1] = hunk
    elseif hunk and not line:match("^\\") then
      hunk.lines[#hunk.lines + 1] = line
      local sign = line:sub(1, 1)
      if not hunk.line and (sign == "+" or sign == "-") then
        hunk.side = sign == "+" and "modified" or "original"
        hunk.line = sign == "+" and new or old
        hunk.first = vim.trim(line:sub(2))
      end
      if sign ~= "+" then
        old = old + 1
      end
      if sign ~= "-" then
        new = new + 1
      end
    end
  end
  return vim.tbl_filter(function(found)
    return found.line ~= nil
  end, hunks)
end

local function entry(tab, path)
  return vim.iter(session.files(tab)):find(function(file)
    return file.path == path
  end)
end

function M.jump(tab, hunk)
  local file = entry(tab, hunk.path)
  if not file then
    return
  end
  local current = session.current(tab)
  if not (current and current.path == hunk.path) then
    session.select(tab, file)
  end
  local original, modified = session.windows(tab)
  local win = hunk.side == "original" and original or modified
  vim.wait(3000, function()
    local side = vim.api.nvim_win_is_valid(win) and session.side(vim.api.nvim_win_get_buf(win), tab)
    return side and side.path == hunk.path
  end)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    pcall(vim.api.nvim_win_set_cursor, win, { hunk.line, 0 })
    vim.cmd("normal! zvzz")
  end
end

function M.list(tab, callback)
  local revisions = session.revisions(tab)
  if not revisions then
    return callback(nil)
  end
  vim.system(
    command(revisions),
    { text = true },
    vim.schedule_wrap(function(result)
      local listed = {}
      for _, file in ipairs(session.files(tab)) do
        listed[file.path] = true
      end
      callback(vim.tbl_filter(function(hunk)
        return listed[hunk.path]
      end, result.code == 0 and M.parse(result.stdout) or {}))
    end)
  )
end

function M.pick()
  local tab = vim.api.nvim_get_current_tabpage()
  M.list(tab, function(hunks)
    if not hunks then
      vim.notify("Not in a review with a file list", vim.log.levels.WARN)
      return
    end
    if #hunks == 0 then
      vim.notify("No hunks in the files listed")
      return
    end
    Snacks.picker.pick({
      title = "Hunks of this review",
      items = vim.tbl_map(function(hunk)
        return vim.tbl_extend("force", hunk, {
          text = table.concat({ hunk.path, hunk.scope, hunk.first }, " "),
          preview = { text = table.concat(hunk.lines, "\n"), ft = "diff" },
        })
      end, hunks),
      format = function(item)
        return {
          { item.path, "SnacksPickerFile" },
          { ":" .. item.line, "SnacksPickerRow" },
          { "  " .. item.scope, "Function" },
          { "  " .. item.first, "Comment" },
        }
      end,
      preview = "preview",
      confirm = function(picker, item)
        picker:close()
        if item then
          M.jump(tab, item)
        end
      end,
    })
  end)
end

return M
