return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>lf",
      function()
        require("conform").format({ async = true })
      end,
      mode = { "n", "x" },
      desc = "Format buffer/selection",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_organize_imports", "ruff_format" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "rumdl" },
      tex = { "latexindent" },
    },
    formatters = {
      prettier = {
        command = function()
          local path = vim.fn.exepath("prettier")
          return path ~= "" and path or "prettier"
        end,
        condition = function(_, ctx)
          return require("dotfiles.format").prettier_trusted(ctx.buf)
        end,
        append_args = function(_, ctx)
          return ctx.filename:match("%.json%.[^/]+$") and { "--parser", "json" } or {}
        end,
      },
    },
    default_format_opts = { lsp_format = "fallback" },

    format_on_save = function(buf)
      return require("dotfiles.format").on_save(buf)
    end,
  },
  init = function()
    if vim.g.disable_autoformat == nil then
      vim.g.disable_autoformat = not require("config.settings").format_on_save
    end
  end,
}
