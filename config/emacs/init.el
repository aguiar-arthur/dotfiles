;;; -*- lexical-binding: t -*-

(when (version< emacs-version "29.1")
  (error "This configuration needs Emacs 29.1 or newer (running %s)" emacs-version))

(defconst aa/config-dir user-emacs-directory
  "Directory of this configuration (the repo checkout).")

(setq user-emacs-directory aa/data-dir)
(add-to-list 'load-path (expand-file-name "lisp" aa/config-dir))

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))

      package-archive-priorities '(("gnu" . 10) ("melpa" . 5) ("nongnu" . 1))
      package-install-upgrade-built-in nil)
(package-initialize)

(setq use-package-always-ensure t
      use-package-expand-minimally t)

(use-package no-littering
  :init (setq no-littering-etc-directory (expand-file-name "etc/" aa/data-dir)
              no-littering-var-directory (expand-file-name "var/" aa/data-dir))
  :config
  (no-littering-theme-backups)
  (setq custom-file (no-littering-expand-etc-file-name "custom.el")))

(defvar aa/failed-modules nil
  "Modules or files that signalled an error at startup, as (NAME . MESSAGE).")

(defun aa/load-module (feature)
  "Require FEATURE; on error record it and show a warning instead of aborting startup."
  (condition-case err
      (require feature)
    (error
     (push (cons feature (error-message-string err)) aa/failed-modules)
     (display-warning 'init (format "Module `%s' failed: %s"
                                    feature (error-message-string err))
                      :error))))

(defun aa/load-local ()
  "Load the untracked local.el next to init.el, recording an error instead of aborting."
  (let ((file (expand-file-name "local.el" aa/config-dir)))
    (when (file-exists-p file)
      (condition-case err
          (load file nil t)
        (error
         (push (cons 'local.el (error-message-string err)) aa/failed-modules)
         (display-warning 'init (format "local.el failed: %s" (error-message-string err))
                          :error))))))

(aa/load-module 'init-settings)
(aa/load-local)

(mapc #'aa/load-module
      (append '(init-core
                init-ui
                init-evil
                init-dev
                init-org
                init-notes)
              (when (memq 'clojure (if (boundp 'aa/languages) aa/languages '(clojure)))
                '(init-clojure))
              '(init-review
                init-keys
                init-health)))

(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 64 1024 1024))))

(provide 'init)
