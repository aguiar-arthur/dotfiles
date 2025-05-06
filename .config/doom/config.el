;; -*- lexical-binding: t; -*-

;; ---------------------------
;; Core
;; ---------------------------
(setq doom-theme 'doom-dracula)
(setq which-key-idle-delay 0.5)
(setq display-line-numbers-type 'relative)

(setq confirm-kill-emacs nil
      delete-by-moving-to-trash t
      window-combination-resize t
      evil-want-fine-undo t
      auto-save-default t
      truncate-string-ellipsis "…"
      require-final-newline t)

(after! flycheck
  (setq flycheck-check-syntax-automatically '(save mode-enabled)
        flycheck-display-errors-delay 0.5))

(add-hook 'after-init-hook #'global-flycheck-mode)

(after! ace-window
  (setq aw-keys '(?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9 ?0))
  (setq aw-scope 'global)
  (setq aw-background nil)
  (setq aw-minibuffer-flag t))

(after! ace-window
  (custom-set-faces!
    '(aw-leading-char-face
       :foreground "white" :background "red" :weight bold :height 2.0)))
       
;; ---------------------------
;; Clojure
;; ---------------------------
(use-package! paredit
  :hook ((clojure-mode . paredit-mode)
         (emacs-lisp-mode . paredit-mode)))

(after! clojure-mode
  (setq clojure-indent-style 'align-arguments
        clojure-align-forms-automatically t
        clojure-toplevel-inside-comment-form t
        clojure-thread-all-but-last t
        clojure-thread-first-all t
        clojure-docstring-fill-column 72))

(after! lsp-mode
  (setq lsp-lens-enable t
        lsp-clojure-server-path "clojure-lsp"
        lsp-clojure-custom-server-command '("clojure-lsp")
        lsp-clojure-semantic-tokens-enable t
        lsp-enable-folding t
        lsp-enable-snippet t
        lsp-enable-file-watchers t))

(after! company
  (setq company-idle-delay 0.3
        company-minimum-prefix-length 2
        company-tooltip-limit 10
        company-show-quick-access t
        company-global-modes '(not eshell-mode shell-mode term-mode vterm-mode)
        company-dabbrev-downcase nil))

(add-hook 'clojure-mode-hook #'rainbow-delimiters-mode)
(add-hook 'clojure-mode-hook #'paredit-mode)
(add-hook 'cider-repl-mode-hook #'rainbow-delimiters-mode)
(add-hook 'cider-repl-mode-hook #'paredit-mode)

;; ---------------------------
;; Additional
;; ---------------------------
(load! "+bindings")
