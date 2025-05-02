;; -*- lexical-binding: t; -*-

;; ---------------------------
;; Core
;; ---------------------------

(package! lsp-mode)
(package! lsp-ui)
(package! company-lsp)

;; ---------------------------
;; Clojure
;; ---------------------------

(package! clojure-mode)
(package! cider)

(use-package! paredit
  :hook ((clojure-mode . paredit-mode)
         (emacs-lisp-mode . paredit-mode)))
