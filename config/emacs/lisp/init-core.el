;;; init-core.el --- Defaults, macOS, fonts, sessions -*- lexical-binding: t -*-

;; ------------------------------------------------------------------
;; Defaults
;; ------------------------------------------------------------------
(setq use-short-answers t
      ring-bell-function #'ignore
      initial-scratch-message nil
      confirm-kill-emacs nil
      delete-by-moving-to-trash t
      create-lockfiles nil
      backup-by-copying t
      load-prefer-newer t
      require-final-newline t
      sentence-end-double-space nil
      window-combination-resize t
      warning-minimum-level :error
      scroll-margin 8
      scroll-conservatively 101
      scroll-preserve-screen-position t
      mouse-wheel-progressive-speed nil
      save-interprogram-paste-before-kill t
      truncate-string-ellipsis "…")

(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 90
              truncate-lines t                  ; prose turns wrapping back on
              display-line-numbers-type 'relative)

(dolist (mode '(global-auto-revert-mode delete-selection-mode show-paren-mode
                column-number-mode global-hl-line-mode pixel-scroll-precision-mode
                recentf-mode savehist-mode save-place-mode))
  (when (fboundp mode) (funcall mode 1)))

(load custom-file 'noerror 'nomessage)
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

(add-hook 'text-mode-hook (lambda () (setq-local truncate-lines nil) (visual-line-mode 1)))

;; Spell check (SPC u s); needs `brew install aspell'
(when (executable-find "aspell")
  (setq ispell-program-name "aspell"
        ispell-dictionary "en_US"
        ispell-extra-args '("--sug-mode=ultra"))
  (add-hook 'text-mode-hook #'flyspell-mode))

;; ------------------------------------------------------------------
;; macOS
;; ------------------------------------------------------------------
(when (eq system-type 'darwin)
  (setq ns-use-proxy-icon nil
        ns-alternate-modifier 'meta            ; left Option = Meta (M-j / M-k)
        ns-right-alternate-modifier 'none      ; right Option still types accents
        ns-command-modifier 'super)
  (add-to-list 'default-frame-alist '(ns-appearance . dark))
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t)))

;; A GUI Emacs does not inherit the shell PATH: clojure, clojure-lsp, rg, fd...
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (setq exec-path-from-shell-variables '("PATH" "MANPATH" "LANG"))
  (exec-path-from-shell-initialize))

(let ((texbin "/Library/TeX/texbin"))           ; MacTeX
  (when (and (file-directory-p texbin) (not (member texbin exec-path)))
    (add-to-list 'exec-path texbin)
    (setenv "PATH" (concat texbin ":" (getenv "PATH")))))

;; ------------------------------------------------------------------
;; Fonts (the Brewfile installs JetBrainsMono Nerd Font)
;; ------------------------------------------------------------------
(defcustom aa/font-height 130
  "Default font height in 1/10 pt."
  :type 'integer
  :group 'faces)

(defun aa/setup-fonts ()
  "Apply JetBrainsMono Nerd Font when it is installed."
  (when (display-graphic-p)
    (pcase-dolist (`(,face ,family) '((default "JetBrainsMono Nerd Font Mono")
                                      (variable-pitch "JetBrainsMono Nerd Font")))
      (when (find-font (font-spec :name family))
        (set-face-attribute face nil :family family :height aa/font-height)))))

(aa/setup-fonts)
(add-hook 'server-after-make-frame-hook #'aa/setup-fonts)

;; ------------------------------------------------------------------
;; Commands
;; ------------------------------------------------------------------
(defun aa/update-packages ()
  "Refresh the package index and upgrade every installed package."
  (interactive)
  (package-refresh-contents)
  (package-upgrade-all))

;; Sessions (SPC S): windows and buffers
(setq desktop-dirname aa/data-dir
      desktop-path (list aa/data-dir)
      desktop-base-file-name "emacs.desktop")

(defun aa/session-save ()
  "Save the current session."
  (interactive)
  (desktop-save aa/data-dir))

(defun aa/session-restore ()
  "Restore the saved session."
  (interactive)
  (desktop-read aa/data-dir))

(defun aa/session-delete ()
  "Delete the saved session."
  (interactive)
  (desktop-remove))

;; Window resizing (SPC w H/J/K/L); a prefix argument multiplies the step
(defcustom aa/window-resize-step 2
  "Columns or lines changed per keypress when resizing windows."
  :type 'integer
  :group 'windows)

(defmacro aa/def-resize (name fn sign doc)
  "Define NAME, which calls FN with SIGN times the resize step."
  `(defun ,name (n)
     ,doc
     (interactive "p")
     (,fn (* ,sign n aa/window-resize-step))))

(aa/def-resize aa/window-decrease-width enlarge-window-horizontally -1 "Narrow the window.")
(aa/def-resize aa/window-increase-width enlarge-window-horizontally 1 "Widen the window.")
(aa/def-resize aa/window-decrease-height enlarge-window -1 "Shorten the window.")
(aa/def-resize aa/window-increase-height enlarge-window 1 "Heighten the window.")

(provide 'init-core)
;;; init-core.el ends here
