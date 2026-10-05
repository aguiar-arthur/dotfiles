;;; init-clojure.el --- clojure-mode, CIDER, clojure-lsp, structural editing -*- lexical-binding: t -*-

;; CIDER owns the REPL, evaluation, completion, docs and tests; eglot + clojure-lsp
;; (with clj-kondo) owns diagnostics, rename, references and formatting. LSP
;; completion is off so it does not compete with CIDER's REPL-aware completion.
;; Needs (Brewfile): clojure, leiningen, clojure-lsp, clj-kondo.

(use-package rainbow-delimiters
  :hook ((clojure-mode emacs-lisp-mode) . rainbow-delimiters-mode))

;; Strict mode keeps parentheses balanced
(use-package smartparens
  :hook (clojure-mode . smartparens-strict-mode)
  :config (require 'smartparens-config))

;; Makes evil operators (d, y, c, x...) respect structure
(use-package evil-smartparens
  :after (evil smartparens)
  :hook (smartparens-enabled . evil-smartparens-mode))

(defun aa/clojure-lsp ()
  "Start clojure-lsp in this buffer, leaving completion to CIDER."
  (setq-local eglot-ignored-server-capabilities '(:completionProvider))
  (eglot-ensure))

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
;;; init-clojure.el ends here
