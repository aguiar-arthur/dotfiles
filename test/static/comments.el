;;; -*- lexical-binding: t -*-
(let ((root (car (last command-line-args-left))))
  (dolist (file (append (directory-files-recursively (expand-file-name "config/emacs" root) "\\.el\\'")
                        (directory-files-recursively (expand-file-name "test" root) "\\.el\\'")))
    (with-temp-buffer
      (insert-file-contents file)
      (emacs-lisp-mode)
      (goto-char (point-min))
      (forward-line 1)
      (while (comment-search-forward (point-max) t)
        (princ (format "%s:%d: comment\n" file (line-number-at-pos)))
        (end-of-line))))
  (setq command-line-args-left nil))
