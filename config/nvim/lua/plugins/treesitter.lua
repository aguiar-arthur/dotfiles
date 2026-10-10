local parsers = require("config.settings").parsers

local skip_highlight = { tex = true, plaintex = true, latex = true }

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup({})

    if vim.fn.executable("tree-sitter") == 1 then
      ts.install(parsers)
    else
      vim.schedule(function()
        vim.notify("tree-sitter CLI not found: brew install tree-sitter-cli", vim.log.levels.WARN)
      end)
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        if skip_highlight[ev.match] then
          return
        end

        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
