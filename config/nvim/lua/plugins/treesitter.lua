-- nvim-treesitter (branch `main`, a reescrita para Neovim >= 0.11):
--   * não existe mais `require("nvim-treesitter.configs")`
--   * parsers são compilados localmente → precisa do `tree-sitter` CLI e de um compilador C
--     (brew install tree-sitter-cli; Xcode CLT já traz o cc)
--   * highlight/indent são ligados por nós, num autocmd de FileType
local parsers = {
  "bash", "c", "clojure", "cpp", "css", "diff", "html", "javascript", "json",
  "latex", "lua", "luadoc", "markdown", "markdown_inline", "python",
  "query", "regex", "ruby", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
}

-- LaTeX: o vimtex faz o highlight/folds/concealment por regex+syntax. Ligar o
-- treesitter por cima dele é desaconselhado pelo próprio vimtex.
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
      ts.install(parsers) -- assíncrono; ignora o que já está instalado
    else
      vim.schedule(function()
        vim.notify("tree-sitter CLI não encontrado: brew install tree-sitter-cli", vim.log.levels.WARN)
      end)
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        if skip_highlight[ev.match] then return end
        -- start() falha se não houver parser para o filetype: simplesmente ignora
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
