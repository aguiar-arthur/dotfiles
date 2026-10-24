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

local function trusted(path)
  local real = vim.uv.fs_realpath(path)
  local file = real and io.open(real, "rb")
  if not file then
    return false
  end
  local hash = vim.fn.sha256(file:read("*a"))
  file:close()
  local ok, lines = pcall(vim.fn.readfile, vim.fn.stdpath("state") .. "/trust")
  return ok and vim.tbl_contains(lines, hash .. " " .. real)
end

local function prettier_trusted(buf)
  local dirname = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
  local root = require("conform.formatters.prettier").cwd(nil, { dirname = dirname })
  return root ~= nil and trusted(root .. "/.nvim.lua")
end

local shfmt_editorconfig = file_matching(".editorconfig", "^%s*%[[^%]]*%f[%w]b?a?sh%f[%W]")

local style_markers = {
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
  "css",
  "html",
  "json",
  "jsonc",
  "yaml",
}) do
  style_markers[ft] = prettier_trusted
end

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
          return prettier_trusted(ctx.buf)
        end,
        append_args = function(_, ctx)
          return ctx.filename:match("%.json%.[^/]+$") and { "--parser", "json" } or {}
        end,
      },
    },
    default_format_opts = { lsp_format = "fallback" },

    format_on_save = function(buf)
      if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
        return
      end
      local has_style = style_markers[vim.bo[buf].filetype]
      if not has_style or not has_style(buf) then
        return
      end
      return { timeout_ms = 1500 }
    end,
  },
  init = function()
    if vim.g.disable_autoformat == nil then
      vim.g.disable_autoformat = not require("config.settings").format_on_save
    end
  end,
}
