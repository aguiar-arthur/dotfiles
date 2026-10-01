-- nvim-treesitter (`main` branch, the rewrite for Neovim >= 0.11):
--   * `require("nvim-treesitter.configs")` no longer exists
--   * parsers are compiled locally → needs the `tree-sitter` CLI and a C compiler
--     (brew install tree-sitter-cli; Xcode CLT already provides cc)
--   * highlight/indent are enabled by us, in a FileType autocmd
local parsers = {
  "bash", "c", "clojure", "cpp", "css", "diff", "html", "javascript", "json",
  "latex", "lua", "luadoc", "markdown", "markdown_inline", "python",
  "query", "regex", "ruby", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
}

-- LaTeX: vimtex handles highlight/folds/concealment via regex+syntax. Enabling
-- treesitter on top of it is discouraged by vimtex itself.
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
      ts.install(parsers) -- asynchronous; skips what is already installed
    else
      vim.schedule(function()
        vim.notify("tree-sitter CLI not found: brew install tree-sitter-cli", vim.log.levels.WARN)
      end)
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        if skip_highlight[ev.match] then return end
        -- start() fails if there is no parser for the filetype: just ignore it
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
