-- texlab: completion (comandos, \cite, \ref), diagnósticos (chktex), rename,
-- go-to-definition em labels/citações. A compilação e o PDF ficam com o vimtex.
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
