local M = {}

local saved

function M.on()
  if saved then
    return
  end
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  local markdown, context = require("render-markdown"), require("treesitter-context")
  saved = {
    lens = vim.lsp.codelens.is_enabled(),
    virtual_lines = vim.diagnostic.config().virtual_lines,
    markdown = markdown.get(),
    context = context.enabled(),
  }
  vim.lsp.codelens.enable(false)
  vim.diagnostic.config({ virtual_lines = false })
  markdown.disable()
  context.disable()
end

function M.off()
  if not saved then
    return
  end
  local markdown, context = require("render-markdown"), require("treesitter-context")
  vim.lsp.codelens.enable(saved.lens)
  vim.diagnostic.config({ virtual_lines = saved.virtual_lines })
  markdown[saved.markdown and "enable" or "disable"]()
  context[saved.context and "enable" or "disable"]()
  saved = nil
end

return M
