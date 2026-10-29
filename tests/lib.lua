local T = { failed = {} }

local stubs = {}

function T.eq(name, got, want)
  if not vim.deep_equal(got, want) then
    T.failed[#T.failed + 1] = ("%s: wanted %s, got %s"):format(
      name,
      vim.inspect(want),
      vim.inspect(got)
    )
  end
end

function T.stub(tbl, key, value)
  stubs[#stubs + 1] = { tbl = tbl, key = key, value = tbl[key] }
  tbl[key] = value
end

local function restore()
  for i = #stubs, 1, -1 do
    stubs[i].tbl[stubs[i].key] = stubs[i].value
    stubs[i] = nil
  end
end

function T.case(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  restore()
  if not ok then
    T.failed[#T.failed + 1] = ("%s: crashed: %s"):format(name, tostring(err):match("^[^\n]*"))
  end
end

function T.skip(name, reason)
  io.stdout:write(("SKIP\t%s\t%s\n"):format(name, reason))
end

function T.dir(files)
  local root = vim.fn.tempname()
  for path, lines in pairs(files or {}) do
    vim.fn.mkdir(vim.fs.dirname(root .. "/" .. path), "p")
    vim.fn.writefile(lines, root .. "/" .. path)
  end
  vim.fn.mkdir(root, "p")
  return root
end

function T.config(path)
  return dofile(vim.fn.stdpath("config") .. "/lua/" .. path)
end

function T.done()
  if #T.failed > 0 then
    io.stderr:write(table.concat(T.failed, "\n") .. "\n")
    vim.cmd("cquit 1")
  end
  vim.cmd("qa!")
end

return T
