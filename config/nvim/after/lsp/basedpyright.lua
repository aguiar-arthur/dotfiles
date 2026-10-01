return {
  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- imports ficam com o ruff
      analysis = {
        typeCheckingMode = "standard",
        autoImportCompletions = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}
