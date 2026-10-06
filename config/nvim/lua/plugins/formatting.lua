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
      markdown = { "rumdl" },
      tex = { "latexindent" },

    },
    default_format_opts = { lsp_format = "fallback" },

    format_on_save = function(buf)
      if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
      if vim.tbl_contains({ "tex", "plaintex", "bib" }, vim.bo[buf].filetype) then return end
      return { timeout_ms = 1500 }
    end,
  },
  init = function()
    vim.api.nvim_create_user_command("FormatToggle", function(args)
      if args.bang then
        vim.b.disable_autoformat = not vim.b.disable_autoformat
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
