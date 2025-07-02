;; -*- lexical-binding: t; -*-

;; ---------------------------
;; Core
;; ---------------------------
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(global-visual-line-mode t)

(setq doom-localleader-key ",")

(setq doom-font (font-spec :family "FiraCode Nerd Font Mono" :size 12) ;; For coding
      doom-variable-pitch-font (font-spec :family "FiraCode Nerd Font" :size 12)) ;; For variable-width text areas

(setq doom-theme 'doom-dracula
      display-line-numbers-type 'relative
      fancy-splash-image (concat "~/dotfiles/config/doom/" "splash.png"))

(setq confirm-kill-emacs nil
      delete-by-moving-to-trash t
      window-combination-resize t
      evil-want-fine-undo t
      auto-save-default t
      truncate-string-ellipsis "…"
      require-final-newline t
      which-key-idle-delay 0.5)

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
       :foreground "white"
       :weight bold)))

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
(add-hook 'clojure-mode-hook #'flycheck-mode)
(add-hook 'cider-repl-mode-hook #'rainbow-delimiters-mode)
(add-hook 'cider-repl-mode-hook #'paredit-mode)

;; ---------------------------
;; Org mode
;; ---------------------------

(use-package! org-modern
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  (setq org-modern-star '("◉" "○" "●" "○" "●" "○" "●")))

(custom-set-faces!
  '(org-level-1 :height 1.3 :weight bold :inherit 'font-lock-function-name-face)
  '(org-level-2 :height 1.2 :weight semi-bold :inherit 'font-lock-variable-name-face)
  '(org-level-3 :height 1.1 :weight semi-bold :inherit 'font-lock-keyword-face)
  '(org-level-4 :height 1.05 :weight normal :inherit 'font-lock-type-face)

  '(org-level-5 :inherit 'font-lock-string-face)
  '(org-level-6 :inherit 'font-lock-constant-face)
  '(org-level-7 :inherit 'font-lock-builtin-face)
  '(org-level-8 :inherit 'font-lock-comment-face)

  '(org-document-title :height 1.5 :weight bold :inherit 'font-lock-preprocessor-face))

(setq org-directory "~/org/"
      org-cycle-separator-lines 1

      org-display-inline-images t
      org-redisplay-inline-images t
      org-startup-with-inline-images t

      org-hide-emphasis-markers t
      org-fontify-done-headline t
      org-fontify-whole-heading-line t
      org-fontify-quote-and-verse-blocks t
      org-blank-before-new-entry '((heading . t) (plain-list-item . nil)))

(add-hook 'org-mode-hook 'org-display-inline-images)

;; ---------------------------
;; Additional
;; ---------------------------
(load! (expand-file-name "dotfiles/config/doom/+bindings.el" (getenv "HOME")))
