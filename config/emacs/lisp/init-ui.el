;;; -*- lexical-binding: t -*-

(use-package dracula-theme
  :if (eq aa/theme 'dracula))

(condition-case err
    (load-theme aa/theme t)
  (error (display-warning 'init (format "Theme `%s' failed: %s" aa/theme (error-message-string err)))))

(use-package nerd-icons)

(use-package nerd-icons-completion
  :after (marginalia nerd-icons)
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup)
  :init (nerd-icons-completion-mode 1))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 24
        doom-modeline-buffer-file-name-style 'truncate-upto-project
        doom-modeline-buffer-encoding nil
        doom-modeline-vcs-max-length 20))

(use-package which-key
  :init (which-key-mode 1)
  :config
  (setq which-key-idle-delay 0.3
        which-key-idle-secondary-delay 0.05
        which-key-max-description-length 40))

(use-package vertico
  :init (vertico-mode 1)
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)))

(use-package vertico-repeat
  :ensure nil
  :after vertico
  :hook (minibuffer-setup . vertico-repeat-save))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(defun aa/corfu-ret ()
  "Accept the selected Corfu candidate, else behave as a plain RET."
  (interactive)
  (if (>= corfu--index 0)
      (corfu-insert)
    (corfu-quit)
    (call-interactively (key-binding (kbd "RET")))))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-preselect 'prompt)
  (corfu-cycle t)
  :bind (:map corfu-map
              ("TAB" . corfu-next)
              ([tab] . corfu-next)
              ("S-TAB" . corfu-previous)
              ([backtab] . corfu-previous)
              ("C-j" . corfu-next)
              ("C-k" . corfu-previous)
              ("RET" . aa/corfu-ret))
  :init (global-corfu-mode 1))

(use-package corfu-popupinfo
  :ensure nil
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :custom (corfu-popupinfo-delay '(0.5 . 0.2)))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

(use-package treemacs
  :defer t
  :custom
  (treemacs-width 32)
  (treemacs-follow-after-init t)
  (treemacs-missing-project-action 'remove)
  :custom-face
  (treemacs-git-modified-face ((t (:foreground "#ffb86c"))))
  (treemacs-git-added-face ((t (:foreground "#50fa7b"))))
  (treemacs-git-untracked-face ((t (:foreground "#8be9fd"))))
  (treemacs-git-renamed-face ((t (:foreground "#ff79c6"))))
  (treemacs-git-conflict-face ((t (:foreground "#ff5555" :weight bold))))
  (treemacs-git-ignored-face ((t (:foreground "#6272a4")))))

(use-package treemacs-evil
  :after (treemacs evil))

(defun aa/tree-toggle ()
  "Show only the current project in treemacs, or close the tree when it is open."
  (interactive)
  (require 'treemacs)
  (if (eq (treemacs-current-visibility) 'visible)
      (delete-window (treemacs-get-local-window))
    (treemacs-add-and-display-current-project-exclusively)))

(defun aa/tree-reveal ()
  "Show the current project in treemacs and move to the current file."
  (interactive)
  (require 'treemacs)
  (let ((buf (current-buffer)))
    (treemacs-add-and-display-current-project-exclusively)
    (with-current-buffer buf (treemacs-find-file))))

(use-package treemacs-nerd-icons
  :after treemacs
  :config (treemacs-load-theme "nerd-icons"))

(use-package dashboard
  :demand t
  :custom
  (dashboard-items '((recents . 8) (projects . 5) (agenda . 8)))
  (dashboard-projects-backend 'project-el)
  (dashboard-icon-type 'nerd-icons)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-center-content t)
  (dashboard-startup-banner 'logo)
  (dashboard-banner-logo-title "Emacs")
  :config

  (dashboard-setup-startup-hook)

  (when (daemonp)
    (setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))))

(provide 'init-ui)
