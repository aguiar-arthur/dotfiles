local M = {}

M.prose = { "tex", "markdown", "text", "gitcommit", "plaintex" }

M.generation = 0

M.values = {}

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
  if
    not vim.wo[win].diff and not require("dotfiles.git").review(vim.api.nvim_win_get_tabpage(win))
  then
    set_local(win, "wrap", M.values.wrap)
  end
  set_local(win, "relativenumber", M.values.relativenumber)
  set_local(win, "conceallevel", M.values.conceallevel)
  set_spell(win, buf)
end

function M.apply_all()
  M.generation = M.generation + 1
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    M.apply(win)
  end
end

local function global(name, get, set)
  return Snacks.toggle({ name = name, get = get, set = set })
end

function M.option(name, option, on, off, blocked)
  local notify
  if blocked then
    notify = function(state)
      local reason = blocked()
      if reason then
        vim.notify(reason, vim.log.levels.WARN, { title = name })
        return
      end
      Snacks.notify(
        (state and "Enabled" or "Disabled") .. " **" .. name .. "**",
        { title = name, level = state and vim.log.levels.INFO or vim.log.levels.WARN }
      )
    end
  end
  return Snacks.toggle({
    name = name,
    notify = notify,
    get = function()
      return M.values[option] == on
    end,
    set = function(state)
      if blocked and blocked() then
        return
      end
      M.values[option] = state and on or off
      vim.go[option] = M.values[option]
      M.apply_all()
    end,
  })
end

local function review_blocks_wrap()
  if require("dotfiles.git").review() then
    return "Wrap stays off in a review: it would misalign the two sides"
  end
end

function M.map()
  global("Spelling (prose, all windows)", function()
    return vim.g.prose_spell ~= false
  end, function(state)
    vim.g.prose_spell = state
    M.apply_all()
  end):map("<leader>us")
  M.option("Wrap (all windows)", "wrap", true, false, review_blocks_wrap):map("<leader>uw")
  M.option("Relative number (all windows)", "relativenumber", true, false):map("<leader>uL")
  M.option("Conceal (all windows)", "conceallevel", 2, 0):map("<leader>uc")
  global("Inlay hints (all buffers)", function()
    return vim.lsp.inlay_hint.is_enabled()
  end, function(state)
    vim.lsp.inlay_hint.enable(state)
  end):map("<leader>uh")
  global("Grammar (LTeX)", function()
    return vim.lsp.is_enabled("ltex_plus")
  end, function(state)
    vim.lsp.enable("ltex_plus", state)
  end):map("<leader>uG")
  global("Markdown rendering", function()
    return require("render-markdown").get()
  end, function(state)
    require("render-markdown")[state and "enable" or "disable"]()
  end):map("<leader>um")
  global("Code context", function()
    return require("treesitter-context").enabled()
  end, function(state)
    require("treesitter-context")[state and "enable" or "disable"]()
  end):map("<leader>ux")
  global("Format on save (global)", function()
    return not vim.g.disable_autoformat
  end, function(state)
    vim.g.disable_autoformat = not state
  end):map("<leader>uf")
  global("Format on save (this buffer)", function()
    return not vim.b.disable_autoformat
  end, function(state)
    vim.b.disable_autoformat = not state
  end):map("<leader>uF")
  local treesitter = require("dotfiles.treesitter")
  global("Treesitter highlight (all buffers)", treesitter.enabled, treesitter.set):map("<leader>uT")
end

function M.setup()
  M.values = {
    wrap = vim.go.wrap,
    relativenumber = vim.go.relativenumber,
    conceallevel = vim.go.conceallevel,
  }
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
      if managed(ev.buf) then
        for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
          set_spell(win, ev.buf)
        end
      end
    end,
  })
end

return M
