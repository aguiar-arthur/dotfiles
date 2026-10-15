local T = { failed = {} }

function T.eq(name, got, want)
  if not vim.deep_equal(got, want) then
    T.failed[#T.failed + 1] = ("%s: wanted %s, got %s"):format(
      name,
      vim.inspect(want),
      vim.inspect(got)
    )
  end
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
