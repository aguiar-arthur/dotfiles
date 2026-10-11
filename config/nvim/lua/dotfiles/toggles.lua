local M = {}

M.prose = { "tex", "markdown", "text", "gitcommit", "plaintex" }

local function set_local(win, name, value)
  vim.api.nvim_set_option_value(name, value, { scope = "local", win = win })
end

function M.apply(win)
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then
    return
  end
  if not vim.wo[win].diff then
    set_local(win, "wrap", vim.go.wrap)
  end
  set_local(win, "relativenumber", vim.go.relativenumber)
  set_local(win, "conceallevel", vim.go.conceallevel)
  set_local(
    win,
    "spell",
    vim.g.prose_spell ~= false and vim.tbl_contains(M.prose, vim.bo[buf].filetype)
  )
end

function M.apply_all()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    M.apply(win)
  end
end

local skip_highlight = { tex = true, plaintex = true, latex = true }

function M.treesitter_enabled()
  return vim.g.treesitter_highlight ~= false
end

function M.start_treesitter(buf)
  if not M.treesitter_enabled() or skip_highlight[vim.bo[buf].filetype] then
    return
  end
  if pcall(vim.treesitter.start, buf) then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

function M.set_treesitter(state)
  vim.g.treesitter_highlight = state
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
      if state then
        M.start_treesitter(buf)
      else
        pcall(vim.treesitter.stop, buf)
      end
    end
  end
end

local function global(name, get, set)
  return Snacks.toggle({ name = name, get = get, set = set })
end

function M.option(name, option, on, off)
  return global(name, function()
    return vim.go[option] == on
  end, function(state)
    vim.go[option] = state and on or off
    M.apply_all()
  end)
end

function M.map()
  global("Spelling (prose, all windows)", function()
    return vim.g.prose_spell ~= false
  end, function(state)
    vim.g.prose_spell = state
    M.apply_all()
  end):map("<leader>us")
  M.option("Wrap (all windows)", "wrap", true, false):map("<leader>uw")
  M.option("Relative number (all windows)", "relativenumber", true, false):map("<leader>uL")
  M.option("Conceal (all windows)", "conceallevel", 2, 0):map("<leader>uc")
  global("Inlay hints (all buffers)", function()
    return vim.lsp.inlay_hint.is_enabled()
  end, function(state)
    vim.lsp.inlay_hint.enable(state)
  end):map("<leader>uh")
  global("Treesitter highlight (all buffers)", M.treesitter_enabled, M.set_treesitter):map(
    "<leader>uT"
  )
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("user_global_toggles", { clear = true }),
    callback = function(ev)
      if ev.event == "FileType" and not M.treesitter_enabled() then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            pcall(vim.treesitter.stop, ev.buf)
          end
        end)
      end
      for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
        M.apply(win)
      end
    end,
  })
end

return M
