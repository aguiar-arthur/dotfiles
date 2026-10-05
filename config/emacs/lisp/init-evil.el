;;; init-evil.el --- Evil, surround, commentary, jumps, Org bindings -*- lexical-binding: t -*-

(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil            ; evil-collection handles it
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil              ; keep TAB free (Org, buffer switching)
        evil-want-fine-undo t
        evil-vsplit-window-right t
        evil-split-window-below t
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

;; ys/ds/cs by default; gsa/gsd/gsr (mini.surround) are added in init-keys.el
(use-package evil-surround
  :after evil
  :config (global-evil-surround-mode 1))

;; gc / gcc
(use-package evil-commentary
  :after evil
  :config (evil-commentary-mode 1))

;; flash.nvim: `s' / `S' (init-keys.el)
(use-package avy
  :defer t
  :custom
  (avy-all-windows nil)
  (avy-timeout-seconds 0.3))

;; M-j / M-k move lines (init-keys.el)
(use-package move-text :defer t)

(use-package evil-org
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar todo heading))
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(provide 'init-evil)
;;; init-evil.el ends here
