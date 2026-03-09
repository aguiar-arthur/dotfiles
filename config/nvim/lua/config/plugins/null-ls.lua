return {
  "nvimtools/none-ls.nvim",
  event = "BufReadPre",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        -- Formatters
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.prettier.with({
          filetypes = { "javascript", "typescript", "css", "html", "json", "yaml", "markdown" },
        }),
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.shfmt,

        -- Linters
        null_ls.builtins.diagnostics.eslint,
        null_ls.builtins.diagnostics.flake8,
        null_ls.builtins.diagnostics.shellcheck,

        -- Code actions
        null_ls.builtins.code_actions.eslint,
        null_ls.builtins.code_actions.shellcheck,
      },
    })
  end,
}