-- texlab: completion (commands, \cite, \ref), diagnostics (chktex), rename,
-- go-to-definition on labels/citations. Compilation and the PDF are handled by vimtex.
return {
  settings = {
    texlab = {
      build = { onSave = false },
      chktex = { onOpenAndSave = true, onEdit = false },
      latexFormatter = "latexindent",
      latexindent = { modifyLineBreaks = false },
      bibtexFormatter = "texlab",
    },
  },
}
