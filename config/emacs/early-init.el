;;; early-init.el --- Runs before init.el and the first frame -*- lexical-binding: t -*-

;; Speed up startup; init.el restores a sane value afterwards.
(setq gc-cons-threshold most-positive-fixnum)

;; Everything Emacs generates (packages, caches, history) lives outside the repo.
(defconst aa/data-dir
  (expand-file-name "emacs/" (or (getenv "XDG_DATA_HOME") "~/.local/share/"))
  "Root of all generated Emacs data.")

(setq package-enable-at-startup nil
      package-user-dir (expand-file-name "elpa/" aa/data-dir))

(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" aa/data-dir)))

;; Native compilation fails with this macOS toolchain (clang rejects
;; -mmacosx-version-min=...), so stay on byte-code: no JIT, no subr trampolines
;; (evil advises the primitive `select-window', which would trigger one).
(setq native-comp-jit-compilation nil
      native-comp-deferred-compilation nil
      native-comp-enable-subr-trampolines nil
      native-comp-async-report-warnings-errors 'silent)

;; Clean frame from the first paint
(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;;; early-init.el ends here
