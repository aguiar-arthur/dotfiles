local M = {}

M.prose = { "tex", "markdown", "text", "gitcommit", "plaintex" }

M.generation = 0

local function set_local(win, name, value)
  vim.api.nvim_set_option_value(name, value, { scope = "local", win = win })
end

local function managed(buf)
  return vim.bo[buf].buftype == "" and not vim.b[buf].keep_local_opts
end

local function set_spell(win, buf)
  set_local(
    win,
    "spell",
    vim.g.prose_spell ~= false and vim.tbl_contains(M.prose, vim.bo[buf].filetype)
  )
end

function M.apply(win)
  local buf = vim.api.nvim_win_get_buf(win)
  if not managed(buf) then
    return
  end
  vim.b[buf].toggles_generation = M.generation
  if not vim.wo[win].diff then
    set_local(win, "wrap", vim.go.wrap)
  end
  set_local(win, "relativenumber", vim.go.relativenumber)
  set_local(win, "conceallevel", vim.go.conceallevel)
  set_spell(win, buf)
end

function M.apply_all()
  M.generation = M.generation + 1
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
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local indent = vim.tbl_contains(require("config.settings").treesitter_indent, lang)
  if pcall(vim.treesitter.start, buf) and indent then
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
  local group = vim.api.nvim_create_augroup("user_global_toggles", { clear = true })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(ev)
      if vim.b[ev.buf].toggles_generation == M.generation then
        return
      end
      for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
        M.apply(win)
      end
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(ev)
      if not M.treesitter_enabled() then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            pcall(vim.treesitter.stop, ev.buf)
          end
        end)
      end
      if managed(ev.buf) then
        for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
          set_spell(win, ev.buf)
        end
      end
    end,
  })
end

return M
