-- Formatting with conform.nvim (replaces none-ls).
-- Diagnostics/lint come from the LSP servers themselves (ruff, bashls+shellcheck,
-- texlab+chktex, lua_ls...), so there is no extra linter layer.
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_organize_imports", "ruff_format" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      tex = { "latexindent" }, -- ships with MacTeX
      -- no entry (e.g. clojure, toml, c): falls back to the LSP formatter (lsp_format)
    },
    default_format_opts = { lsp_format = "fallback" },

    -- Format on save, except in tex/bib (latexindent is slow and reindents the
    -- whole file; use <leader>lf when you want it) and when disabled
    -- (:FormatToggle, <leader>uf).
    format_on_save = function(buf)
      if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
      if vim.tbl_contains({ "tex", "plaintex", "bib" }, vim.bo[buf].filetype) then return end
      return { timeout_ms = 1500 }
    end,
  },
  init = function()
    vim.api.nvim_create_user_command("FormatToggle", function(args)
      if args.bang then
        vim.b.disable_autoformat = not vim.b.disable_autoformat -- current buffer only
      else
        vim.g.disable_autoformat = not vim.g.disable_autoformat
      end
      vim.notify(
        ("Auto-format %s%s"):format(
          (args.bang and vim.b.disable_autoformat or vim.g.disable_autoformat) and "OFF" or "ON",
          args.bang and " (buffer)" or ""
        )
      )
    end, { bang = true, desc = "Toggle auto-format (! = this buffer only)" })
  end,
}
