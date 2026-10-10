;;; -*- lexical-binding: t -*-
(require 'ert)

(defconst test/modules
  '(init-settings init-core init-ui init-evil init-dev init-org init-notes init-clojure init-review init-keys init-health))

(ert-deftest smoke-modules-loaded ()
  (dolist (module test/modules)
    (should (featurep module))))

(ert-deftest smoke-no-module-failed-warning ()
  (let ((warnings (when (get-buffer "*Warnings*")
                    (with-current-buffer "*Warnings*" (buffer-string)))))
    (should-not (and warnings (string-match "Module .* failed" warnings)))))

(ert-deftest smoke-startup-makes-no-network-call ()
  (should-not (seq-filter (lambda (v) (string-prefix-p "network" v)) test/violations)))

(ert-deftest smoke-startup-asks-nothing ()
  (should-not (seq-filter (lambda (v) (string-prefix-p "prompt" v)) test/violations)))

(ert-deftest smoke-data-lives-outside-the-config ()
  (should (string-prefix-p (expand-file-name (getenv "XDG_DATA_HOME")) (expand-file-name aa/data-dir)))
  (should-not (file-exists-p (expand-file-name "elpa" aa/config-dir))))

(ert-deftest smoke-key-packages-present ()
  (dolist (feature '(evil evil-collection general magit treemacs treemacs-evil eglot corfu vertico))
    (should (or (featurep feature) (locate-library (symbol-name feature))))))

(defconst test/own-warning "^\\(?:early-\\)?init\\(?:-[a-z]+\\)?\\.el:[0-9]+:[0-9]+: \\(?:Warning\\|Error\\)")

(ert-deftest smoke-byte-compile-without-warnings ()
  (let ((byte-compile-warnings '(obsolete interactive-only lexical redefine suspicious mapcar
                                          constants callargs make-local))
        (byte-compile-dest-file-function
         (lambda (file)
           (expand-file-name (concat (file-name-nondirectory file) "c") temporary-file-directory)))
        (seen nil))
    (advice-add 'message :before
                (lambda (format-string &rest args)
                  (when format-string
                    (push (apply #'format format-string args) seen)))
                '((name . test/collect)))
    (unwind-protect
        (dolist (file (append (directory-files (expand-file-name "lisp" aa/config-dir) t "\\.el\\'")
                              (list (expand-file-name "init.el" aa/config-dir)
                                    (expand-file-name "early-init.el" aa/config-dir))))
          (byte-compile-file file))
      (advice-remove 'message 'test/collect))
    (should-not (seq-filter (lambda (line) (string-match-p test/own-warning line)) seen))))
