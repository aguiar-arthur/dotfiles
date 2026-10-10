;;; -*- lexical-binding: t -*-
(defvar test/violations nil)

(dolist (fn '(url-retrieve url-retrieve-synchronously make-network-process open-network-stream))
  (advice-add fn :before
              (lambda (&rest _) (push (format "network: %s" this-command) test/violations))))

(dolist (fn '(y-or-n-p yes-or-no-p read-string completing-read read-from-minibuffer))
  (advice-add fn :before
              (lambda (&rest args) (push (format "prompt: %S" (car args)) test/violations))))

(let ((config (expand-file-name "~/.config/emacs/")))
  (setq user-emacs-directory config)
  (load (expand-file-name "early-init.el" config) nil t)
  (load (expand-file-name "init.el" config) nil t))
