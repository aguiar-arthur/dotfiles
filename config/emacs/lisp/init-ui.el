;;; init-ui.el --- Theme, modeline, completion, file tree -*- lexical-binding: t -*-

(use-package dracula-theme
  :config
  (load-theme 'dracula t))

;; Icons: run `M-x nerd-icons-install-fonts' once if symbols look broken
;; (the JetBrainsMono Nerd Font from the Brewfile already covers most of them).
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

;; ------------------------------------------------------------------
;; Minibuffer: vertico + orderless + marginalia + consult (C-j / C-k like nvim)
;; ------------------------------------------------------------------
(use-package vertico
  :init (vertico-mode 1)
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)))

;; Resume the last picker (SPC f R)
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

;; Actions on the thing at point (SPC .). `embark-export' + wgrep edits results in place.
(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; ------------------------------------------------------------------
;; In-buffer: corfu + cape. Tab/S-Tab/C-j/C-k select; RET accepts only a selected
;; candidate (like blink.cmp).
;; ------------------------------------------------------------------
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

;; ------------------------------------------------------------------
;; File tree (SPC o p)
;; ------------------------------------------------------------------
(use-package treemacs
  :defer t
  :custom
  (treemacs-width 32)
  (treemacs-follow-after-init t))

(use-package treemacs-nerd-icons
  :after treemacs
  :config (treemacs-load-theme "nerd-icons"))

;; ------------------------------------------------------------------
;; Dashboard (SPC o d): recent files, projects and today's agenda
;; ------------------------------------------------------------------
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
  (initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
  :config (dashboard-setup-startup-hook))

(provide 'init-ui)
;;; init-ui.el ends here
