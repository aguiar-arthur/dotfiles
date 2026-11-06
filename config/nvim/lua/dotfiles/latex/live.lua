local M = {}

local function live()
  return require("config.settings").latex_live
end

local function stamp(buf)
  local st = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  return st and (st.mtime.sec .. ":" .. st.mtime.nsec) or ""
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_vimtex", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VimtexEventInitPost",
    callback = function()
      if live() and require("dotfiles.latex.compiler").state() == "idle" then
        vim.cmd("VimtexCompile")
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "FileChangedShellPost" }, {
    group = group,
    pattern = "*.tex",
    callback = function(ev)
      vim.b[ev.buf].tex_stamp = stamp(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorHold", "InsertLeave" }, {
    group = group,
    pattern = "*.tex",
    callback = function(ev)
      if not live() or vim.bo[ev.buf].buftype ~= "" then
        return
      end
      if not vim.bo[ev.buf].modified then
        vim.schedule(function()
          vim.cmd("checktime")
        end)
      elseif not vim.bo[ev.buf].readonly and stamp(ev.buf) == vim.b[ev.buf].tex_stamp then
        vim.cmd("silent update")
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VimtexEventView",
    callback = function()
      vim.g.dotfiles_tex_viewed = true
    end,
  })
  local build_failed = false
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VimtexEventCompileSuccess",
    callback = function()
      if build_failed then
        vim.notify("Compiled successfully", vim.log.levels.INFO, { title = "LaTeX" })
      end
      build_failed = false
      if live() and vim.g.dotfiles_tex_viewed then
        vim.cmd("VimtexView")
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VimtexEventCompileFailed",
    callback = function()
      build_failed = true
      vim.notify(
        "Compilation failed — <localleader>le lists the errors",
        vim.log.levels.ERROR,
        { title = "LaTeX" }
      )
    end,
  })
end

return M
