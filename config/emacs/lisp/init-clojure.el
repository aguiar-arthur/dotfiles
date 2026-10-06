;;; -*- lexical-binding: t -*-

(use-package rainbow-delimiters
  :hook ((clojure-mode emacs-lisp-mode) . rainbow-delimiters-mode))

(use-package smartparens
  :hook (clojure-mode . smartparens-strict-mode)
  :config (require 'smartparens-config))

(use-package evil-smartparens
  :after (evil smartparens)
  :hook (smartparens-enabled . evil-smartparens-mode))

(defun aa/clojure-lsp ()
  "Start clojure-lsp, leaving completion to CIDER; skip revision buffers."
  (unless (string-match-p "\\.~[^~]+~\\'" (buffer-name))
    (setq-local eglot-ignored-server-capabilities '(:completionProvider))
    (eglot-ensure)))

(use-package clojure-mode
  :hook ((clojure-mode clojurec-mode clojurescript-mode) . aa/clojure-lsp)
  :custom (clojure-align-forms-automatically t))

(use-package cider
  :defer t
  :custom
  (cider-repl-display-help-banner nil)
  (cider-repl-pop-to-buffer-on-connect 'display-only)
  (cider-repl-wrap-history t)
  (cider-repl-history-file (expand-file-name "cider-history" aa/data-dir))
  (cider-save-file-on-load t)
  (cider-show-error-buffer 'only-in-repl)
  (cider-eldoc-display-for-symbol-at-point t)
  (nrepl-hide-special-buffers t))

(provide 'init-clojure)
