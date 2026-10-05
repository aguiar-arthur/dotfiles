;;; init-dev.el --- Projects, LSP, formatting, git, terminal, marks -*- lexical-binding: t -*-

(require 'cl-lib)

;; ------------------------------------------------------------------
;; Projects and search
;; ------------------------------------------------------------------
(use-package project
  :ensure nil
  :custom (project-vc-extra-root-markers '("deps.edn" "project.clj" "bb.edn")))

(setq xref-search-program 'ripgrep)

(defun aa/find-file-smart ()
  "Find a file in the current project, else with fd in the current directory."
  (interactive)
  (if (project-current) (project-find-file) (consult-fd default-directory)))

(defun aa/grep-project ()
  "Live grep (ripgrep) in the project or current directory."
  (interactive)
  (consult-ripgrep))

(defun aa/grep-word ()
  "Grep the active region or the symbol at point."
  (interactive)
  (consult-ripgrep nil (if (use-region-p)
                           (buffer-substring-no-properties (region-beginning) (region-end))
                         (thing-at-point 'symbol t))))

(defun aa/find-config ()
  "Find a file in this configuration."
  (interactive)
  (consult-fd (file-truename aa/config-dir)))

;; ------------------------------------------------------------------
;; LSP (eglot) and diagnostics (flymake). clojure-lsp is eglot's default server.
;; ------------------------------------------------------------------
(use-package eglot
  :ensure nil
  :defer t
  :custom
  (eglot-autoshutdown t)
  (eglot-send-changes-idle-time 0.3)
  (eglot-extend-to-xref t))

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom (flymake-no-changes-timeout 0.5))

(setq eldoc-idle-delay 0.3)

(defun aa/next-error-diag ()
  "Jump to the next error diagnostic."
  (interactive)
  (flymake-goto-next-error 1 '(:error) t))

(defun aa/prev-error-diag ()
  "Jump to the previous error diagnostic."
  (interactive)
  (flymake-goto-prev-error 1 '(:error) t))

(defun aa/toggle-inlay-hints ()
  "Toggle LSP inlay hints (Emacs 30+)."
  (interactive)
  (if (fboundp 'eglot-inlay-hints-mode)
      (eglot-inlay-hints-mode 'toggle)
    (user-error "Inlay hints need Emacs 30 or newer")))

;; ------------------------------------------------------------------
;; Formatting: eglot in LSP buffers, apheleia (prettier, shfmt, stylua...) elsewhere.
;; Both run on save; SPC u f toggles, SPC l f formats on demand.
;; ------------------------------------------------------------------
(defvar aa/autoformat t
  "Non-nil formats buffers on save.")

(defun aa/lsp-p ()
  "Non-nil when the current buffer is managed by eglot."
  (and (fboundp 'eglot-managed-p) (eglot-managed-p)))

(defun aa/format-buffer ()
  "Format the region or buffer: eglot, else apheleia, else plain re-indent."
  (interactive)
  (cond ((aa/lsp-p)
         (if (use-region-p)
             (eglot-format (region-beginning) (region-end))
           (eglot-format-buffer)))
        ((bound-and-true-p apheleia-mode)
         (call-interactively #'apheleia-format-buffer))
        (t (indent-region (if (use-region-p) (region-beginning) (point-min))
                          (if (use-region-p) (region-end) (point-max))))))

(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (add-hook 'before-save-hook
                      (lambda () (when (and aa/autoformat (aa/lsp-p))
                                   (ignore-errors (eglot-format-buffer))))
                      nil t)))

(defun aa/toggle-autoformat ()
  "Toggle formatting on save."
  (interactive)
  (message "Auto-format %s" (if (setq aa/autoformat (not aa/autoformat)) "ON" "OFF")))

(use-package apheleia
  :custom (apheleia-log-only-errors t)
  :config
  (add-to-list 'apheleia-inhibit-functions (lambda () (or (not aa/autoformat) (aa/lsp-p))))
  (apheleia-global-mode 1))

;; ------------------------------------------------------------------
;; Editing aids
;; ------------------------------------------------------------------
;; Indent guides (SPC u g), not in Lisp where they add noise
(defun aa/enable-indent-bars ()
  "Enable indent guides outside Lisp modes."
  (unless (derived-mode-p 'clojure-mode 'emacs-lisp-mode)
    (indent-bars-mode 1)))

(use-package indent-bars
  :hook (prog-mode . aa/enable-indent-bars)
  :custom
  (indent-bars-prefer-character t)
  (indent-bars-width-frac 0.2))

;; Brackets: electric-pair everywhere but Clojure (smartparens does it there)
(add-hook 'prog-mode-hook
          (lambda () (unless (derived-mode-p 'clojure-mode) (electric-pair-local-mode 1))))

;; Edit grep / embark-export buffers in place: C-c C-p, then C-c C-c
(use-package wgrep
  :defer t
  :custom (wgrep-auto-save-buffer t))

(use-package vundo :defer t)                    ; undo tree (SPC f u)

(use-package hl-todo                            ; TODO/FIXME highlighting, ]t [t
  :hook (prog-mode . hl-todo-mode))

;; `emacsclient file' (alias `e' from install.sh) reuses this instance
(unless noninteractive
  (require 'server)
  (unless (server-running-p) (server-start)))

;; ------------------------------------------------------------------
;; Git: magit + diff-hl (gitsigns)
;; ------------------------------------------------------------------
(use-package magit
  :defer t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-diff-refine-hunk 'all))                 ; word-level highlights, like inline:char in nvim

(use-package diff-hl
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init (global-diff-hl-mode 1)
  :config (diff-hl-flydiff-mode 1))

(use-package browse-at-remote :commands browse-at-remote)

(defun aa/blame-toggle ()
  "Toggle magit blame for the current file."
  (interactive)
  (if (bound-and-true-p magit-blame-mode)
      (magit-blame-quit)
    (call-interactively #'magit-blame-addition)))

;; ------------------------------------------------------------------
;; Terminal (eat): SPC t f / h / v, C-\ toggles
;; ------------------------------------------------------------------
(use-package eat :commands eat)

(defun aa/term-full ()
  "Terminal in the current window."
  (interactive)
  (eat))

(defun aa/term-below ()
  "Terminal in a split below."
  (interactive)
  (split-window-below -15)
  (other-window 1)
  (eat))

(defun aa/term-right ()
  "Terminal in a split on the right."
  (interactive)
  (split-window-right -70)
  (other-window 1)
  (eat))

(defun aa/term-toggle ()
  "Open a terminal, or leave it when already in one."
  (interactive)
  (if (not (derived-mode-p 'eat-mode))
      (eat)
    (if (one-window-p) (previous-buffer) (delete-window))))

;; ------------------------------------------------------------------
;; Marks (harpoon): SPC m. A per-project file list, persisted in the data dir.
;; ------------------------------------------------------------------
(defvar aa/harpoon-file (expand-file-name "harpoon.eld" aa/data-dir)
  "Where the harpoon lists are saved.")

(defvar aa/harpoon-lists
  (when (file-exists-p aa/harpoon-file)
    (with-temp-buffer
      (insert-file-contents aa/harpoon-file)
      (ignore-errors (read (current-buffer)))))
  "Alist of (PROJECT-ROOT . FILES).")

(defun aa/harpoon--root ()
  "Root of the current project, else the current directory."
  (expand-file-name (if-let ((p (project-current))) (project-root p) default-directory)))

(defun aa/harpoon--files ()
  "Files marked in the current project."
  (alist-get (aa/harpoon--root) aa/harpoon-lists nil nil #'equal))

(defun aa/harpoon--set (files)
  "Store FILES for the current project and persist."
  (setf (alist-get (aa/harpoon--root) aa/harpoon-lists nil nil #'equal) files)
  (with-temp-file aa/harpoon-file (prin1 aa/harpoon-lists (current-buffer))))

(defun aa/harpoon-add ()
  "Mark the current file."
  (interactive)
  (let ((file (or (buffer-file-name) (user-error "Not visiting a file")))
        (files (aa/harpoon--files)))
    (if (member file files)
        (message "Already marked")
      (aa/harpoon--set (append files (list file)))
      (message "Marked %s (%d)" (file-name-nondirectory file) (1+ (length files))))))

(defun aa/harpoon-remove ()
  "Unmark a file."
  (interactive)
  (when-let ((files (aa/harpoon--files))
             (choice (completing-read "Unmark: " files nil t)))
    (aa/harpoon--set (delete choice files))))

(defun aa/harpoon-menu ()
  "Pick a marked file."
  (interactive)
  (if-let ((files (aa/harpoon--files)))
      (find-file (completing-read "Harpoon: " files nil t))
    (message "No marks in this project")))

(defun aa/harpoon-goto (n)
  "Open the N-th marked file."
  (if-let ((file (nth (1- n) (aa/harpoon--files))))
      (find-file file)
    (message "No mark %d" n)))

(defun aa/harpoon-step (delta)
  "Open the marked file DELTA positions from the current one (wraps around)."
  (let* ((files (or (aa/harpoon--files) (user-error "No marks in this project")))
         (idx (cl-position (buffer-file-name) files :test #'equal)))
    (find-file (nth (mod (+ (or idx (if (> delta 0) -1 0)) delta) (length files)) files))))

(defun aa/harpoon-next () (interactive) (aa/harpoon-step 1))
(defun aa/harpoon-prev () (interactive) (aa/harpoon-step -1))

(dotimes (i 5)
  (let ((n (1+ i)))
    (defalias (intern (format "aa/harpoon-goto-%d" n))
      (lambda () (interactive) (aa/harpoon-goto n))
      (format "Open marked file %d." n))))

(provide 'init-dev)
;;; init-dev.el ends here
