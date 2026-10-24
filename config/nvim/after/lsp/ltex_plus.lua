return {
  filetypes = { "tex", "plaintex" },
  root_dir = function(buf, on_dir)
    local name = vim.api.nvim_buf_get_name(buf)
    on_dir(vim.fs.root(name, ".git") or vim.fs.dirname(name))
  end,
  offset_encoding = "utf-16",
  settings = {
    ltex = {
      language = "pt-BR",
      disabledRules = {
        ["pt-BR"] = { "MORFOLOGIK_RULE_PT_BR" },
        ["en-US"] = { "MORFOLOGIK_RULE_EN_US" },
      },
      additionalRules = { enablePickyRules = false },
      ["ltex-ls"] = { logLevel = "warning" },
      latex = {
        commands = {
          ["\\citeonline{}"] = "dummy",
          ["\\apud{}{}"] = "dummy",
        },
      },
    },
  },
}
