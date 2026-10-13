return {
  settings = {
    texlab = {
      build = { onSave = false, auxDirectory = "build", logDirectory = "build" },
      chktex = { onOpenAndSave = true, onEdit = false },
      latexFormatter = "latexindent",
      latexindent = { modifyLineBreaks = false },
      bibtexFormatter = "texlab",
    },
  },
}
