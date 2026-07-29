;;; init.el --- Setup Vanilla Modular -*- lexical-binding: t -*-

;; ==========================================
;; 1. PACKAGE MANAGEMENT
;; ==========================================
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; Install use-package if not present
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t) 

;; ==========================================
;; 2. CORE CONFIGURATIONS
;; ==========================================
(setq byte-compile-warnings '(not obsolete))
(setq warning-minimum-level 'error)

(setq confirm-kill-emacs nil
      delete-by-moving-to-trash t
      window-combination-resize t
      auto-save-default t
      truncate-string-ellipsis "…"
      require-final-newline t)

(setq-default display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)
(global-visual-line-mode t)
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; Fonts
(set-face-attribute 'default nil :family "FiraCode Nerd Font Mono" :height 120)
(set-face-attribute 'variable-pitch nil :family "FiraCode Nerd Font" :height 120)

;; ==========================================
;; 3. CUSTOM FUNCTIONS
;; ==========================================
(defun aa/indent-buffer ()
  "Indent the current buffer."
  (interactive)
  (indent-region (point-min) (point-max)))

(defun aa/update-packages ()
  "Refresh package contents and upgrade all installed packages automatically."
  (interactive)
  (package-refresh-contents)
  (package-upgrade-all))

(defcustom aa/window-resize-step 10
  "Number of columns/rows to resize windows by per keypress."
  :type 'integer
  :group 'windows)

(defun aa/window-decrease-width (amount)
  (interactive "P")
  (let* ((count (if amount (prefix-numeric-value amount) 1))
         (delta (* (max 1 count) aa/window-resize-step)))
    (shrink-window-horizontally delta)))

(defun aa/window-increase-width (amount)
  (interactive "P")
  (let* ((count (if amount (prefix-numeric-value amount) 1))
         (delta (* (max 1 count) aa/window-resize-step)))
    (enlarge-window-horizontally delta)))

(defun aa/window-decrease-height (amount)
  (interactive "P")
  (let* ((count (if amount (prefix-numeric-value amount) 1))
         (delta (* (max 1 count) aa/window-resize-step)))
    (shrink-window delta)))

(defun aa/window-increase-height (amount)
  (interactive "P")
  (let* ((count (if amount (prefix-numeric-value amount) 1))
         (delta (* (max 1 count) aa/window-resize-step)))
    (enlarge-window delta)))

;; ==========================================
;; 4. EVIL MODE AND KEYBINDINGS (GENERAL.EL)
;; ==========================================
(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-vsplit-window-right t
        evil-split-window-below t
        evil-want-fine-undo t)
  :config
  (evil-mode 1)

  ;; Force Evil to handle C-d and C-u for half-page scrolling
  (define-key evil-normal-state-map (kbd "C-d") 'evil-scroll-down)
  (define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-visual-state-map (kbd "C-d") 'evil-scroll-down)
  (define-key evil-visual-state-map (kbd "C-u") 'evil-scroll-up))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package general
  :config
  (general-evil-setup t)
  
  (general-create-definer my-leader-def
    :states '(normal visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")
    
  ;; Defining the Local Leader (,)
  (general-create-definer my-local-leader-def
    :states '(normal visual emacs)
    :prefix ",")

  (my-leader-def
    ;; Window bindings
    "w" '(:ignore t :which-key "window")
    "w h" 'evil-window-left
    "w j" 'evil-window-down
    "w k" 'evil-window-up
    "w l" 'evil-window-right
    "w w" 'ace-window
    "w v" 'evil-window-vsplit
    "w s" 'evil-window-split
    "w o" 'delete-other-windows
    "w H" 'aa/window-decrease-width
    "w J" 'aa/window-decrease-height
    "w K" 'aa/window-increase-height
    "w L" 'aa/window-increase-width
    "w =" 'balance-windows
    "w c" 'evil-window-delete
    "w q" 'kill-current-buffer
    "w f" 'other-frame

    ;; Code bindings
    "c" '(:ignore t :which-key "code")
    "c c" 'comment-line
    "c C" 'comment-region
    "c t" 'comment-dwim
    "c b" 'eval-buffer
    "c i" 'eval-region
    "c I" 'aa/indent-buffer
    "c j" 'xref-find-definitions
    "c f" 'lsp-extract-function
    "c v" 'lsp-extract-variable
    "c r" 'lsp-refactor

    ;; LSP bindings
    "l" '(:ignore t :which-key "lsp")
    "l d" 'lsp-find-definition
    "l r" 'lsp-find-references
    "l i" 'lsp-find-implementation
    "l t" 'lsp-goto-type-definition
    "l n" 'lsp-rename
    "l f" 'lsp-format-buffer
    "l o" 'lsp-organize-imports
    "l a" 'lsp-execute-code-action
    "l R" 'lsp-restart-workspace
    "l D" 'lsp-describe-thing-at-point
    "l s" 'lsp-ivy-workspace-symbol
    "l h" 'lsp-ui-doc-glance

    ;; Search bindings (Consult)
    "s" '(:ignore t :which-key "search")
    "s s" 'consult-line
    "s p" 'consult-ripgrep
    "s b" 'consult-buffer))

;; ==========================================
;; 5. USER INTERFACE (UI)
;; ==========================================
(use-package dracula-theme
  :config
  (load-theme 'dracula t))

(use-package nerd-icons)

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 24
        doom-modeline-buffer-file-name-style 'truncate-upto-project
        doom-modeline-buffer-encoding nil
        doom-modeline-vcs-max-length 20))

(use-package which-key
  :init (which-key-mode)
  :config
  (setq which-key-idle-delay 0.25
        which-key-idle-secondary-delay 0.05
        which-key-max-description-length 40)

  ;; Essential native Emacs shortcuts grouped under Which-Key
  (my-leader-def
    "?" '(:ignore t :which-key "emacs help & basics")
    ;; Files and Buffers
    "? f" '(find-file :which-key "find file (C-x C-f)")
    "? b" '(switch-to-buffer :which-key "switch buffer (C-x b)")
    "? k" '(kill-buffer :which-key "kill buffer (C-x k)")
    "? s" '(save-buffer :which-key "save buffer (C-x C-s)")
    "? S" '(write-file :which-key "save as / write-file (C-x C-w)")
    
    ;; Window Management (Frames and Splits)
    "? 0" '(delete-window :which-key "close current window (C-x 0)")
    "? 1" '(delete-other-windows :which-key "close other windows (C-x 1)")
    "? 2" '(split-window-below :which-key "split window horizontal (C-x 2)")
    "? 3" '(split-window-right :which-key "split window vertical (C-x 3)")
    "? o" '(other-window :which-key "cycle other window (C-x o)")

    ;; Explorer and Utilities
    "? d" '(dired :which-key "dired file manager (C-x d)")
    "? r" '(consult-recent-file :which-key "recent files")
    "? U" '(aa/update-packages :which-key "update all packages")
    "? y" '(show-scratch-buffer :which-key "scratch buffer")

    ;; Emergency Control and Editing
    "? u" '(undo :which-key "undo (C-/ / C-_)")
    "? g" '(keyboard-quit :which-key "cancel / quit (C-g)")
    "? x" '(execute-extended-command :which-key "M-x execute command (M-x)"))
  )

(use-package treemacs
  :config
  (setq treemacs-width 35
        treemacs-follow-after-init t
        treemacs-project-follow-cleanup t))

(use-package lsp-treemacs
  :after (lsp-mode treemacs)
  :config
  (my-leader-def "l l" 'lsp-treemacs-errors-list))

(use-package ace-window
  :config
  (setq aw-keys '(?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9 ?0)
        aw-scope 'global
        aw-background nil
        aw-minibuffer-flag t)
  (custom-set-faces
   '(aw-leading-char-face ((t (:foreground "white" :weight bold))))))

(use-package flycheck
  :init (global-flycheck-mode)
  :config
  (setq flycheck-check-syntax-automatically '(save mode-enabled)
        flycheck-display-errors-delay 0.5))

;; ==========================================
;; 6. COMPLETION (Vertico, Corfu, Consult)
;; ==========================================
(use-package vertico
  :init (vertico-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package corfu
  :init (global-corfu-mode))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-M-l" . consult-imenu)
         ("C-x b" . consult-buffer)))

;; ==========================================
;; 6.1. TREE-SITTER (ADVANCED PARSER)
;; ==========================================
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (global-treesit-auto-mode)
  
  ;; Tree-sitter leader shortcuts
  (my-leader-def
    "c T" '(:ignore t :which-key "tree-sitter")
    "c T r" 'treesit-install-language-grammar
    "c T i" 'treesit-inspect-mode))

;; ==========================================
;; 7. LANGUAGES AND DEVELOPMENT
;; ==========================================
(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :config
  (setq lsp-lens-enable t
        lsp-clojure-server-path "clojure-lsp"
        lsp-clojure-custom-server-command '("clojure-lsp")
        lsp-clojure-semantic-tokens-enable t
        lsp-enable-folding t
        lsp-enable-snippet t
        lsp-enable-file-watchers t))

(use-package lsp-ui :commands lsp-ui-mode)

(use-package clojure-mode
  :hook ((clojure-mode . lsp-deferred)
         (clojure-mode . rainbow-delimiters-mode)
         (clojure-mode . paredit-mode)
         (clojure-mode . flycheck-mode))
  :config
  (setq clojure-indent-style 'align-arguments
        clojure-align-forms-automatically t
        clojure-toplevel-inside-comment-form t
        clojure-thread-all-but-last t
        clojure-thread-first-all t
        clojure-docstring-fill-column 72)
  
  (my-local-leader-def
    :keymaps '(clojure-mode-map clojurescript-mode-map clojurec-mode-map)
    "'" nil
    "s" 'cider-jack-in-clj
    
    ;; Code Evaluation (Eval)
    "e" '(:ignore t :which-key "eval")
    "e b" 'cider-eval-buffer
    "e e" 'cider-eval-last-sexp
    "e d" 'cider-eval-defun-at-point
    "e r" 'cider-eval-region
    
    ;; Tests
    "t" '(:ignore t :which-key "test")
    "t t" 'cider-test-run-test
    "t n" 'cider-test-run-ns-tests
    "t a" 'cider-test-run-project-tests

    ;; Documentation
    "h" '(:ignore t :which-key "help")
    "h d" 'cider-doc
    "h j" 'cider-javadoc))

(use-package cider
  :hook ((cider-repl-mode . rainbow-delimiters-mode)
         (cider-repl-mode . paredit-mode)))

(use-package paredit
  :hook (emacs-lisp-mode . paredit-mode)
  :bind (:map paredit-mode-map
              ("C-c l"   . paredit-forward)
              ("C-c h"   . paredit-backward)
              ("C-c s l" . paredit-forward-slurp-sexp)
              ("C-c s h" . paredit-backward-slurp-sexp)
              ("C-c b l" . paredit-forward-barf-sexp)
              ("C-c b h" . paredit-backward-barf-sexp)))

(use-package rainbow-delimiters)

;; ==========================================
;; 8. ORG MODE
;; ==========================================
(use-package org
  :config
  (setq org-directory "~/org/"
        org-ellipsis "…"
        org-pretty-entities t
        org-startup-indented t
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
  
  (custom-set-faces
   '(org-level-1 ((t (:height 1.3 :weight bold :inherit font-lock-function-name-face))))
   '(org-level-2 ((t (:height 1.2 :weight semi-bold :inherit font-lock-variable-name-face))))
   '(org-level-3 ((t (:height 1.1 :weight semi-bold :inherit font-lock-keyword-face))))
   '(org-level-4 ((t (:height 1.05 :weight normal :inherit font-lock-type-face))))
   '(org-document-title ((t (:height 1.5 :weight bold :inherit font-lock-preprocessor-face))))))

(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  (setq org-modern-star '("◉" "○" "◈" "◇" "●" "○" "◈")
        org-modern-variable-pitch t))

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-delay 0.1
        org-appear-autoemphasis t
        org-appear-autosubmarkers t
        org-appear-autolinks t
        org-appear-autoentities t))

;; ==========================================
;; 9. PROJECT MANAGEMENT AND EDITING
;; ==========================================

;; Projectile (Project and file searching)
(use-package projectile
  :init
  (projectile-mode +1)
  :config
  (my-leader-def
    "p" '(:ignore t :which-key "project")
    "p p" 'projectile-switch-project
    "p f" 'projectile-find-file
    "SPC" 'projectile-find-file)) 

;; Evil Surround (Manipulation of quotes, parentheses, etc.)
(use-package evil-surround
  :config
  (global-evil-surround-mode 1))

;; ==========================================
;; 10. FILE TREE & SIDEBAR (TREEMACS)
;; ==========================================
(use-package treemacs
  :defer t
  :init
  (with-eval-after-load 'winum
    (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))
  :config
  (setq treemacs-width 35
        treemacs-follow-after-init t
        treemacs-project-follow-cleanup t
        treemacs-silent-file-watchers t
        treemacs-silent-refresh t)
  (treemacs-resize-icons 16)
  
  ;; Register Treemacs under Which-Key (`SPC f` prefix)
  (my-leader-def
    "f"   '(:ignore t :which-key "file")
    "f t" '(treemacs :which-key "toggle file tree")
    "f T" '(treemacs-select-window :which-key "focus file tree")))

(use-package treemacs-evil
  :after (treemacs evil))

(use-package treemacs-icons-dired
  :hook (dired-mode . treemacs-icons-dired-mode))

(use-package lsp-treemacs
  :after (lsp-mode treemacs)
  :config
  (my-leader-def "l l" 'lsp-treemacs-errors-list))

(provide 'init)
;;; init.el ends here
