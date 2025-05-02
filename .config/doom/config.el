;; -*- lexical-binding: t; -*-

;; Style
(setq doom-theme 'doom-dracula)
(setq which-key-idle-delay 0.5)
(setq display-line-numbers-type 'relative)

;; General editor preferences
(setq confirm-kill-emacs nil
      delete-by-moving-to-trash t
      window-combination-resize t
      evil-want-fine-undo t
      auto-save-default t
      truncate-string-ellipsis "…"
      require-final-newline t)

;; ---------------------------
;; Clojure settings
;; ---------------------------

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

;; (auto-completion)
(after! company
  (setq company-idle-delay 0.3
        company-minimum-prefix-length 2
        company-tooltip-limit 10
        company-show-quick-access t
        company-global-modes '(not eshell-mode shell-mode term-mode vterm-mode)
        company-dabbrev-downcase nil))

;; syntax checking
(after! flycheck
  (setq flycheck-check-syntax-automatically '(save mode-enabled)
        flycheck-display-errors-delay 0.3))

;; useful packages
(use-package! clj-refactor
  :hook (clojure-mode . clj-refactor-mode)
  :config
  (cljr-add-keybindings-with-prefix "C-c C-m"))

(use-package! paredit
  :hook ((clojure-mode . paredit-mode)
         (emacs-lisp-mode . paredit-mode)))

;; Simplified Hooks
(add-hook 'clojure-mode-hook #'rainbow-delimiters-mode)
(add-hook 'cider-repl-mode-hook #'rainbow-delimiters-mode)
(add-hook 'clojure-mode-hook #'paredit-mode)
(add-hook 'cider-repl-mode-hook #'paredit-mode)

;; Remaps
(map! :after clojure-mode
      :map clojure-mode-map
      :localleader
      "'" nil ;; This is a remap to avoid the smart keys in some systems
      :desc "Cider jack in CLJ"
      "s" #'cider-jack-in-clj)

(after! paredit
  (map! :map paredit-mode-map
        "C-c l" #'paredit-forward
        "C-c h" #'paredit-backward
        "C-c s l" #'paredit-forward-slurp-sexp
        "C-c s h" #'paredit-backward-slurp-sexp
        "C-c b l" #'paredit-forward-barf-sexp
        "C-c b h" #'paredit-backward-barf-sexp))
