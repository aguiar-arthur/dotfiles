local prettier = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.json5",
  ".prettierrc.yaml",
  ".prettierrc.yml",
  ".prettierrc.toml",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.ts",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
}

local function any_file(names)
  return function(buf)
    return vim.fs.root(buf, names) ~= nil
  end
end

local function file_matching(name, pattern)
  return function(buf)
    local root = vim.fs.root(buf, vim.split(name, "/")[1])
    local ok, lines = pcall(vim.fn.readfile, (root or "") .. "/" .. name)
    if not root or not ok then
      return false
    end
    for _, line in ipairs(lines) do
      if line:match(pattern) then
        return true
      end
    end
    return false
  end
end

local function either(...)
  local checks = { ... }
  return function(buf)
    for _, check in ipairs(checks) do
      if check(buf) then
        return true
      end
    end
    return false
  end
end

local clang_format = any_file({ ".clang-format", "_clang-format" })
local shfmt_editorconfig = file_matching(".editorconfig", "^%s*%[[^%]]*%f[%w]b?a?sh%f[%W]")
local prettier_config = any_file(prettier)

local style_markers = {
  c = clang_format,
  cpp = clang_format,
  lua = any_file({ "stylua.toml", ".stylua.toml" }),
  sh = shfmt_editorconfig,
  bash = shfmt_editorconfig,
  python = either(
    any_file({ "ruff.toml", ".ruff.toml" }),
    file_matching("pyproject.toml", "^%s*%[tool%.ruff")
  ),
  markdown = any_file({
    ".rumdl.toml",
    "rumdl.toml",
    ".markdownlint.json",
    ".markdownlint.jsonc",
    ".markdownlint.yaml",
    ".markdownlint.yml",
  }),
  toml = any_file({ ".taplo.toml", "taplo.toml" }),
  clojure = either(
    any_file({ ".cljfmt.edn", "cljfmt.edn", ".cljfmt.clj", "cljfmt.clj" }),
    file_matching(".lsp/config.edn", ":cljfmt")
  ),
}
for _, ft in ipairs({
  "javascript",
  "typescript",
  "javascriptreact",
  "typescriptreact",
  "css",
  "html",
  "json",
  "jsonc",
  "yaml",
}) do
  style_markers[ft] = prettier_config
end

return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>lf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
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
      if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
        return
      end
      if vim.tbl_contains({ "tex", "plaintex", "bib" }, vim.bo[buf].filetype) then
        return
      end
      local has_style = style_markers[vim.bo[buf].filetype]
      if has_style and not has_style(buf) then
        return
      end
      return { timeout_ms = 1500 }
    end,
  },
  init = function()
    if vim.g.disable_autoformat == nil then
      vim.g.disable_autoformat = not require("config.settings").format_on_save
    end
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
