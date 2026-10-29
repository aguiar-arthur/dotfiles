return {
  root_dir = function(buf, on_dir)
    local name = vim.api.nvim_buf_get_name(buf)
    on_dir(vim.fs.root(buf, vim.lsp.config.basedpyright.root_markers) or vim.fs.dirname(name))
  end,
  before_init = function(_, config)
    local settings = config.settings
    settings.python = vim.tbl_extend("keep", settings.python or {}, {
      pythonPath = require("dotfiles.python").path(config.root_dir),
    })
  end,
  settings = {
    basedpyright = {
      disableOrganizeImports = true,
      analysis = {
        typeCheckingMode = "standard",
        autoImportCompletions = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}
