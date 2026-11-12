local M = {}

local KEEP = 5

local store = {}

local function commit(rev)
  return type(rev) == "string" and rev:match("^%x+$") ~= nil
end

local function blobs(root, rev, paths, callback)
  if #paths == 0 then
    return callback({})
  end
  if rev == "WORKING" then
    local command = vim.list_extend({ "git", "-C", root, "hash-object", "--" }, paths)
    return vim.system(command, { text = true }, function(result)
      local found, i = {}, 0
      for blob in (result.code == 0 and result.stdout or ""):gmatch("%x+") do
        i = i + 1
        found[paths[i]] = blob
      end
      callback(found)
    end)
  end
  local command = vim.list_extend({ "git", "-C", root, "ls-tree", "-r", "-z", rev, "--" }, paths)
  vim.system(command, { text = true }, function(result)
    local found = {}
    for entry in (result.code == 0 and result.stdout or ""):gmatch("[^%z]+") do
      local blob, path = entry:match("^%S+ %S+ (%x+)\t(.+)$")
      if blob then
        found[path] = blob
      end
    end
    callback(found)
  end)
end

function M.fingerprints(revisions, files, callback)
  local ok = revisions
    and commit(revisions.base)
    and (revisions.target == "WORKING" or commit(revisions.target))
  if not ok or #files == 0 then
    return callback(nil)
  end
  local olds = vim.tbl_map(function(file)
    return file.old_path or file.path
  end, files)
  local news = vim.tbl_map(function(file)
    return file.path
  end, files)
  if revisions.target == "WORKING" then
    news = vim.tbl_filter(function(path)
      return vim.fn.filereadable(revisions.root .. "/" .. path) == 1
    end, news)
  end
  blobs(revisions.root, revisions.base, olds, function(before)
    blobs(revisions.root, revisions.target, news, function(after)
      local prints = {}
      for _, file in ipairs(files) do
        prints[file.path] = (before[file.old_path or file.path] or "-")
          .. ":"
          .. (after[file.path] or "-")
      end
      vim.schedule(function()
        callback(prints)
      end)
    end)
  end)
end

function M.known(root, prints)
  local read = store[root] or {}
  local seen = {}
  for path, print in pairs(prints) do
    if vim.tbl_contains(read[path] or {}, print) then
      seen[path] = true
    end
  end
  return seen
end

function M.remember(root, path, print)
  store[root] = store[root] or {}
  local prints = vim.tbl_filter(function(other)
    return other ~= print
  end, store[root][path] or {})
  table.insert(prints, 1, print)
  while #prints > KEEP do
    table.remove(prints)
  end
  store[root][path] = prints
end

return M
