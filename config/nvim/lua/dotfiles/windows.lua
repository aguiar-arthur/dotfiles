local M = {}

local path_bar = " %f%m"

local function plain(win)
  return vim.api.nvim_win_get_config(win).relative == ""
    and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end

local function floating(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

function M.enter(win)
  if not plain(win) then
    if vim.wo[win].winbar == path_bar then
      vim.wo[win].winbar = ""
    end
    return
  end
  vim.wo[win].cursorline = true
  if vim.wo[win].winbar == "" then
    vim.wo[win].winbar = path_bar
  end
end

function M.leave(win)
  if plain(win) then
    vim.wo[win].cursorline = false
  end
end

function M.blank()
  local buf = vim.api.nvim_get_current_buf()
  if
    vim.bo[buf].buftype ~= ""
    or vim.bo[buf].filetype == "snacks_dashboard"
    or vim.api.nvim_buf_get_name(buf) ~= ""
    or vim.bo[buf].modified
  then
    return false
  end
  for _, other in ipairs(vim.api.nvim_list_bufs()) do
    if other ~= buf and vim.bo[other].buflisted and vim.api.nvim_buf_is_loaded(other) then
      return false
    end
  end
  return true
end

function M.welcome()
  if M.blank() then
    Snacks.dashboard()
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_windows", { clear = true })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "TermOpen" }, {
    group = group,
    callback = function()
      M.enter(vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "SnacksDashboardUpdatePost",
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "snacks_dashboard" and floating(win) then
          vim.keymap.set("n", "q", "<cmd>bd<CR>", { buffer = buf, silent = true, nowait = true })
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function()
      vim.schedule(M.welcome)
    end,
  })
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    callback = function()
      M.leave(vim.api.nvim_get_current_win())
    end,
  })
end

return M
