local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end
local au = vim.api.nvim_create_autocmd

au("TextYankPost", {
  group = augroup("yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

au({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

au("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(ev)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[ev.buf].filetype) or vim.b[ev.buf].last_loc_done then
      return
    end
    vim.b[ev.buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

au("BufUnload", {
  group = augroup("last_loc_reset"),
  callback = function(ev)
    vim.b[ev.buf].last_loc_done = nil
  end,
})

au("VimResized", {
  group = augroup("resize"),
  callback = function()
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      vim.api.nvim_win_call(vim.api.nvim_tabpage_get_win(tab), function()
        vim.cmd("wincmd =")
      end)
    end
  end,
})

au("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "man", "checkhealth", "vimtex-toc" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", function()
      if not pcall(vim.cmd.close) then
        vim.cmd.bdelete()
      end
    end, { buffer = ev.buf, silent = true, desc = "Close window" })
  end,
})

require("dotfiles.toggles").setup()

au("BufWritePre", {
  group = augroup("auto_mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
