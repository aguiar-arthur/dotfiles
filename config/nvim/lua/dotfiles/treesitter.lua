local M = {}

local skip_highlight = { tex = true, plaintex = true, latex = true }

function M.missing(parsers)
  local installed = {}
  for _, lang in ipairs(require("nvim-treesitter").get_installed()) do
    installed[lang] = true
  end
  return vim.tbl_filter(function(lang)
    return not installed[lang]
  end, parsers)
end

function M.enabled()
  return vim.g.treesitter_highlight ~= false
end

function M.start(buf)
  if not M.enabled() or skip_highlight[vim.bo[buf].filetype] then
    return
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local indent = vim.tbl_contains(require("config.settings").treesitter_indent, lang)
  if pcall(vim.treesitter.start, buf) and indent then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

function M.attach(buf)
  if M.enabled() then
    M.start(buf)
    return
  end
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.treesitter.stop, buf)
    end
  end)
end

function M.set(state)
  vim.g.treesitter_highlight = state
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
      if state then
        M.start(buf)
      else
        pcall(vim.treesitter.stop, buf)
      end
    end
  end
end

return M
