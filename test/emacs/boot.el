;;; -*- lexical-binding: t -*-
(defvar test/violations nil)
(defvar test/unwatched nil)

(defconst test/config-dir (expand-file-name "~/.config/emacs/"))

(setq user-emacs-directory test/config-dir)
(load (expand-file-name "early-init.el" test/config-dir) nil t)

(when (featurep 'native-compile)
  (setq native-comp-enable-subr-trampolines nil))

(defun test/watch (functions kind)
  "Record a violation of KIND whenever one of FUNCTIONS is called."
  (dolist (fn functions)
    (condition-case err
        (advice-add fn :before
                    (lambda (&rest args)
                      (push (format "%s: %s %S" kind fn (car args)) test/violations)))
      (error (push (format "%s: %s" fn (error-message-string err)) test/unwatched)))))

(test/watch '(url-retrieve url-retrieve-synchronously make-network-process open-network-stream)
            "network")
(test/watch '(y-or-n-p yes-or-no-p read-string completing-read read-from-minibuffer) "prompt")

(when test/unwatched
  (message "boot.el could not watch: %s" (string-join test/unwatched "; ")))

(load (expand-file-name "init.el" test/config-dir) nil t)
