local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end
local au = vim.api.nvim_create_autocmd

au("TextYankPost", {
  group = augroup("yank"),
  callback = function() vim.hl.on_yank() end,
})

au({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end
  end,
})

au("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(ev)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[ev.buf].filetype) or vim.b[ev.buf].last_loc_done then return end
    vim.b[ev.buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

au("VimResized", {
  group = augroup("resize"),
  callback = function()
    local tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. tab)
  end,
})

au("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "notify", "startuptime", "vimtex-toc" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true, desc = "Close window" })
  end,
})

au("FileType", {
  group = augroup("prose"),
  pattern = { "tex", "markdown", "text", "gitcommit", "plaintex", "bib" },
  callback = function(ev)
    if ev.match ~= "bib" then vim.wo.spell = true end
  end,
})

au("BufWinEnter", {
  group = augroup("wrap"),
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "" and not vim.wo.diff then vim.wo.wrap = vim.go.wrap end
  end,
})

au("BufWritePre", {
  group = augroup("auto_mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
