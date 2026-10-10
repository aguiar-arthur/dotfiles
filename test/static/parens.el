;;; -*- lexical-binding: t -*-
(let ((root (car (last command-line-args-left)))
      (header ";;; -*- lexical-binding: t -*-"))
  (dolist (file (directory-files-recursively (expand-file-name "config/emacs" root) "\\.el\\'"))
    (with-temp-buffer
      (insert-file-contents file)
      (emacs-lisp-mode)
      (condition-case err
          (let ((inhibit-message t))
            (check-parens))
        (error (princ (format "%s: %S\n" file err))))
      (goto-char (point-min))
      (unless (equal (buffer-substring (point) (line-end-position)) header)
        (princ (format "%s: first line is not the lexical-binding header\n" file)))))
  (setq command-line-args-left nil))
