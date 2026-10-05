;;; init.el --- Emacs for Org mode and Clojure -*- lexical-binding: t -*-

;; Keymaps mirror the Neovim setup (config/nvim): SPC leader, `,' local leader.
;; Layout: this directory holds only configuration; generated files live in
;; `aa/data-dir' (see early-init.el).

(when (version< emacs-version "29.1")
  (error "This configuration needs Emacs 29.1 or newer (running %s)" emacs-version))

(defconst aa/config-dir user-emacs-directory
  "Directory of this configuration (the repo checkout).")

;; Anything that still defaults to `user-emacs-directory' writes to the data dir.
(setq user-emacs-directory aa/data-dir)
(add-to-list 'load-path (expand-file-name "lisp" aa/config-dir))

;; ------------------------------------------------------------------
;; Packages
;; ------------------------------------------------------------------
(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      ;; NonGNU's index sometimes lists tarballs its server lacks, so rank it last.
      package-archive-priorities '(("gnu" . 10) ("melpa" . 5) ("nongnu" . 1))
      package-install-upgrade-built-in nil)
(package-initialize)

(defun aa/archives-stale-p ()
  "Non-nil when the package index is missing or older than a day."
  (let ((attrs (file-attributes
                (expand-file-name "archives/melpa/archive-contents" package-user-dir))))
    (or (null attrs)
        (> (float-time (time-since (file-attribute-modification-time attrs))) 86400))))

(when (aa/archives-stale-p)
  (condition-case err
      (package-refresh-contents)
    (error (message "Could not refresh the package index: %s" err))))

(setq use-package-always-ensure t
      use-package-expand-minimally t)

;; Keep config/ clean: redirect the files packages write (history, caches, DBs).
(use-package no-littering
  :init (setq no-littering-etc-directory (expand-file-name "etc/" aa/data-dir)
              no-littering-var-directory (expand-file-name "var/" aa/data-dir))
  :config
  (no-littering-theme-backups)
  (setq custom-file (no-littering-expand-etc-file-name "custom.el")))

;; ------------------------------------------------------------------
;; Modules (a failing one is reported and skipped, the rest still load)
;; ------------------------------------------------------------------
(defun aa/load-module (feature)
  "Require FEATURE; on error show a warning instead of aborting startup."
  (condition-case err
      (require feature)
    (error
     (display-warning 'init (format "Module `%s' failed: %s"
                                    feature (error-message-string err))
                      :error))))

(mapc #'aa/load-module
      '(init-core                       ; defaults, macOS, fonts, sessions
        init-ui                         ; theme, modeline, completion, dashboard
        init-evil                       ; evil and friends
        init-dev                        ; projects, LSP, formatting, git, terminal
        init-org                        ; Org: layout, capture, agenda, babel, export
        init-notes                      ; org-roam
        init-clojure                    ; clojure-mode, CIDER, structural editing
        init-keys))                     ; SPC / , keymaps

(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 64 1024 1024))))

(provide 'init)
;;; init.el ends here
