;;; -*- lexical-binding: t -*-

(setq gc-cons-threshold most-positive-fixnum)

(defconst aa/data-dir
  (expand-file-name "emacs/" (or (getenv "XDG_DATA_HOME") "~/.local/share/"))
  "Root of all generated Emacs data.")

(setq package-enable-at-startup nil
      package-user-dir (expand-file-name "elpa/" aa/data-dir))

(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" aa/data-dir)))

(setq native-comp-jit-compilation nil
      native-comp-deferred-compilation nil
      native-comp-enable-subr-trampolines nil
      native-comp-async-report-warnings-errors 'silent)

(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
