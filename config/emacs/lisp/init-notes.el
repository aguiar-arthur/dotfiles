;;; -*- lexical-binding: t -*-

(use-package org-roam
  :defer t
  :custom
  (org-roam-directory (file-truename (aa/org-file "notes/")))
  (org-roam-db-location (expand-file-name "org-roam.db" aa/data-dir))
  (org-roam-dailies-directory "daily/")
  (org-roam-completion-everywhere t)
  (org-roam-node-display-template
   (concat "${title:*} " (propertize "${tags:20}" 'face 'org-tag)))
  (org-roam-capture-templates
   '(("d" "Note" plain "%?"
      :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n#+filetags: \n")
      :unnarrowed t)
     ("r" "Reading / reference" plain "* Summary\n%?\n\n* Quotes\n\n* Ideas\n"
      :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n#+filetags: :reading:\n#+source: \n")
      :unnarrowed t)))
  :config (org-roam-db-autosync-mode 1))

(provide 'init-notes)
