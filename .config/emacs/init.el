;; -*- lexical-binding: t; -*-

;; ========================================
;; Useful Variables
;; ========================================
(defvar efs/default-font-size 120)
(defvar efs/default-variable-font-size 120)
(defvar efs/default-font-family "FiraCode Nerd Font Mono")
(defvar efs/fallback-font-family "Monospace")

;; ========================================
;; Checking dependencies
;; ========================================
(when (not (executable-find "gls"))
  (warn "GNU Coreutils (gls) is not installed - falling back to basic ls")
  (setq dired-use-ls-dired nil
        dired-listing-switches "-alh"))

(when (not (executable-find "rg"))
  (warn "ripgrep (rg) is not installed - some search features will be slower."))

(when (not (find-font (font-spec :name efs/default-font-family)))
  (warn "Font '%s' is not installed - falling back to system default." efs/default-font-family))

;; ========================================
;; Early Performance Optimizations
;; ========================================
(setq gc-cons-threshold (* 50 1000 1000))  ; Increase GC threshold during init
(setq read-process-output-max (* 1024 1024))  ; 1MB for process output
(setq bidi-paragraph-direction 'left-to-right)  ; Better performance for LTR text
(setq idle-update-delay 1.0)  ; Reduce UI updates during idle

(add-hook 'emacs-startup-hook
          (lambda () 
            (setq gc-cons-threshold (* 2 1000 1000)  ; Reset after startup
                  gc-cons-percentage 0.1)))

;; ========================================
;; Package Management
;; ========================================
(setq package-enable-at-startup nil)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize packages without errors
(unless (bound-and-true-p package--initialized)
  (package-initialize t))

;; Bootstrap use-package more robustly
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(setq use-package-always-ensure t
      use-package-verbose t)  ; Helpful for debugging

;; ========================================
;; Basic UI Configuration
;; ========================================
(setq inhibit-startup-message t)   ; Hide the startup message
(setq visible-bell t)              ; Enable visible bell
(menu-bar-mode -1)                 ; Disable menu bar
(tool-bar-mode -1)                 ; Disable tool bar
(scroll-bar-mode -1)               ; Disable scroll bar
(tooltip-mode -1)                  ; Disable tooltips
(set-fringe-mode 10)               ; Set fringe space
(column-number-mode)               ; Show column number
(global-display-line-numbers-mode t) ; Enable line numbers
(setq display-line-numbers-type 'relative) ; Relative line numbers

;; ========================================
;; Font Configuration
;; ========================================
(use-package all-the-icons
  :ensure t
  :if (display-graphic-p)
  :config
  (condition-case err
      (unless (find-font (font-spec :name "all-the-icons"))
        (all-the-icons-install-fonts))
    (error
     (message "All-the-icons error: %s" err))))

(defun efs/set-font ()
  (condition-case err
      (progn
        (set-face-attribute 'default nil :font efs/default-font-family :height efs/default-font-size)
        (set-face-attribute 'variable-pitch nil :font efs/default-font-family :height efs/default-variable-font-size)
        (set-face-attribute 'fixed-pitch nil :font efs/default-font-family :height efs/default-font-size))
    (error
     (message "Font error: %s" err)
     (set-face-attribute 'default nil :family efs/fallback-font-family :height efs/default-font-size))))

(add-hook 'after-init-hook 'efs/set-font)  ; Set fonts after UI is ready

;; ========================================
;; Theme
;; ========================================
(use-package doom-themes
  :ensure t
  :init
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  :config
  (condition-case err
      (progn
        (load-theme 'doom-palenight t)
        ;; Enable doom-themes features only if main theme loads
        (doom-themes-visual-bell-config)
        (doom-themes-org-config))
    (error
     (message "Theme error: %s" err)
     (when (package-installed-p 'wombat-theme)
       (load-theme 'wombat t))
     (unless (package-installed-p 'wombat-theme)
       (load-theme 'tango t)))))  ; Built-in fallback

;; ========================================
;; UI Components
;; ========================================
(use-package all-the-icons
  :ensure t
  :if (display-graphic-p)
  :config
  (unless (find-font (font-spec :name "all-the-icons"))
    (all-the-icons-install-fonts 'force)))

(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode)
  :custom
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-major-mode-color-icon t)
  (doom-modeline-buffer-state-icon t)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-unicode-fallback t) 
  (doom-modeline-height 25)
  :config
  (setq doom-modeline-icon-families 'all-the-icons))

(use-package minions
  :ensure t
  :hook (doom-modeline-mode . minions-mode))

(use-package ace-window
  :ensure t
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(use-package diff-hl
  :ensure t
  :hook ((prog-mode . diff-hl-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh)))

;; ========================================
;; Keybindings and Core Utilities
;; ========================================
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)  ; Make ESC quit prompts

;; Disable line numbers in specific modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                treemacs-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; ========================================
;; Editing Experience
;; ========================================
(use-package consult
  :ensure t)

(use-package undo-fu
  :ensure t)

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
         :map ivy-minibuffer-map
         ("TAB" . ivy-alt-done)	
         ("C-l" . ivy-alt-done)
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill))
  :config
  (ivy-mode 1))

(use-package counsel
  :bind (("C-M-j" . 'counsel-switch-buffer)
         :map minibuffer-local-map
         ("C-r" . 'counsel-minibuffer-history))
  :config
  (counsel-mode 1))

(use-package treesit-auto
  :ensure t
  :config (global-treesit-auto-mode))

;; ========================================
;; Project Management
;; ========================================
(use-package projectile
  :ensure t
  :init
  (projectile-mode +1)
  :bind-keymap
  ("C-c p" . projectile-command-map))

;; ========================================
;; File Tree
;; ========================================
(use-package treemacs
  :ensure t
  :defer t
  :config
  (setq treemacs-width 30
        treemacs-is-never-other-window t
        treemacs-silent-refresh t)
  
  ;; Keybindings - add to your general/leader key setup
  :bind (:map global-map
              ("M-0"       . treemacs-select-window)
              ("C-x t t"   . treemacs)
              ("C-x t d"   . treemacs-select-directory)))

;; ========================================
;; Evil Mode 
;; ========================================
(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-fu
        evil-respect-visual-line-mode t)
  :config
  (evil-mode 1)
  (evil-set-undo-system 'undo-fu)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line))

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init))

(use-package general
  :ensure t
  :after evil
  :config
  ;; Clear any existing SPC bindings that might conflict
  (general-unbind "SPC")
  
  ;; Initialize general with evil integration
  (general-evil-setup t)
  
  ;; Define leader keys with proper prefix handling
  (general-create-definer efs/leader-keys
    :states '(normal visual motion)
    :prefix "SPC"
    :keymaps 'override)
  
  ;; Ensure Space works in Insert mode
  (general-define-key
   :states 'insert
   "SPC" 'self-insert-command)) ; Makes Space insert a space in Insert mode

(efs/leader-keys
  ;; File operations
  "f"  '(:ignore t :which-key "files")
  "ff" '(find-file :which-key "find file")
  "fF" '(consult-file-externally :which-key "open with external program")
  "fs" '(save-buffer :which-key "save file")
  "fS" '(save-some-buffers :which-key "save all buffers")
  "fr" '(consult-recent-file :which-key "recent files")
  "fl" '(consult-locate :which-key "locate file")
  "fy" '(show-kill-ring :which-key "show kill ring")
  
  ;; Buffer operations
  "b"  '(:ignore t :which-key "buffers")
  "bb" '(consult-buffer :which-key "switch buffer")
  "bk" '(kill-this-buffer :which-key "kill buffer")
  "bK" '(kill-some-buffers :which-key "kill multiple buffers") 
  "bn" '(next-buffer :which-key "next buffer")
  "bp" '(previous-buffer :which-key "previous buffer")
  "bR" '(revert-buffer :which-key "revert buffer")
  
  ;; Project operations
  "p"  '(:ignore t :which-key "projects")
  "pf" '(projectile-find-file :which-key "find file in project")
  "ps" '(projectile-switch-project :which-key "switch project")
  "pp" '(projectile-command-map :which-key "projectile")
  "p!" '(projectile-run-shell-command-in-root :which-key "run shell command") 
  "p&" '(projectile-run-async-shell-command-in-root :which-key "run async command")  
  
  ;; Window operations    
  "w"  '(:ignore t :which-key "windows")
  "wd" '(delete-window :which-key "delete window")
  "wD" '(delete-other-windows :which-key "delete other windows")
  "ws" '(split-window-below :which-key "split horizontal")
  "wv" '(split-window-right :which-key "split vertical")
  "wh" '(evil-window-left  :which-key "left window")
  "wj" '(evil-window-down  :which-key "down window")
  "wk" '(evil-window-up    :which-key "up window")
  "wl" '(evil-window-right :which-key "right window")
  "wf" '(make-frame-command :which-key "new frame")
  "w TAB" '(ace-window :which-key "select window")
  "ww" '(other-window :which-key "cycle window")
  "w+" '(evil-window-increase-height :which-key "increase height")
  "w-" '(evil-window-decrease-height :which-key "decrease height")
  "w>" '(evil-window-increase-width  :which-key "increase width")
  "w<" '(evil-window-decrease-width  :which-key "decrease width")
  "w=" '(balance-windows :which-key "balance windows")  ; New

  ;; Toggles
  "t"  '(:ignore t :which-key "toggle")
  "tt" '(consult-theme :which-key "change theme")
  "tn" '(display-line-numbers-mode :which-key "line numbers")
  "tf" '(treemacs :which-key "toggle file tree")
  "tw" '(toggle-truncate-lines :which-key "toggle line wrapping")
  "tv" '(visual-line-mode :which-key "toggle visual line mode")
  
  ;; Applications
  "a"  '(:ignore t :which-key "applications")
  "ad" '(dired :which-key "dired"))

;; ========================================
;; LSP and Completion
;; ========================================
(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

;; Lsp core
(use-package lsp-mode
  :ensure t
  :init (setq lsp-keymap-prefix "C-c l")
  :commands lsp)

(use-package vertico
  :ensure t
  :init
  (vertico-mode))

(use-package orderless
  :ensure t
  :init
  (setq completion-styles '(orderless basic)))

;; ========================================
;; Org Mode Configuration
;; ========================================
(defun efs/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (auto-fill-mode 0)
  (visual-line-mode 1)
  (setq evil-auto-indent nil))

(use-package org
  :hook (org-mode . efs/org-mode-setup)
  :config
  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t
        org-adapt-indentation nil))

;; Configure org faces AFTER org-mode is loaded
(with-eval-after-load 'org
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font efs/default-font-family :height efs/default-font-size)))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

;; ========================================
;; Backup and Auto-Save Configuration
;; ========================================
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t
      auto-save-default t
      auto-save-timeout 20
      auto-save-interval 200)

;; ========================================
;; Custom File (for M-x customize)
;; ========================================
(setq custom-file (locate-user-emacs-file "custom.el"))
(unless (file-exists-p custom-file)
  (write-region "" nil custom-file))
(load custom-file 'noerror 'nomessage)

;; ========================================
;; Final Initialization Message
;; ========================================
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs ready in %.2f seconds with %d garbage collections"
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))