return {
  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- imports are handled by ruff
      analysis = {
        typeCheckingMode = "standard",
        autoImportCompletions = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}
