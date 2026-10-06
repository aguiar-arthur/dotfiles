;;; -*- lexical-binding: t -*-

(require 'cl-lib)

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

(defun aa/line-diagnostics ()
  "Show the Flymake diagnostics of the current line."
  (interactive)
  (if-let* ((diags (flymake-diagnostics (line-beginning-position) (line-end-position))))
      (message "%s" (mapconcat #'flymake-diagnostic-text diags "\n"))
    (message "No diagnostics on this line")))

(defun aa/todos-project ()
  "Search TODO/FIXME/HACK/NOTE/BUG comments in the project with ripgrep."
  (interactive)
  (consult-ripgrep nil "\\b(TODO|FIXME|HACK|NOTE|BUG)\\b"))

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

(defun aa/enable-indent-bars ()
  "Enable indent guides outside Lisp modes."
  (unless (derived-mode-p 'clojure-mode 'emacs-lisp-mode)
    (indent-bars-mode 1)))

(use-package indent-bars
  :hook (prog-mode . aa/enable-indent-bars)
  :custom
  (indent-bars-prefer-character t)
  (indent-bars-width-frac 0.2))

(add-hook 'prog-mode-hook
          (lambda () (unless (derived-mode-p 'clojure-mode) (electric-pair-local-mode 1))))

(use-package wgrep
  :defer t
  :custom (wgrep-auto-save-buffer t))

(use-package vundo :defer t)

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode))

(unless noninteractive
  (require 'server)
  (unless (server-running-p) (server-start)))

(use-package magit
  :defer t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-diff-refine-hunk 'all))

(use-package diff-hl
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init (global-diff-hl-mode 1)
  :config (diff-hl-flydiff-mode 1))

(use-package browse-at-remote :commands browse-at-remote)

(use-package ediff
  :ensure nil
  :defer t
  :custom
  (ediff-window-setup-function #'ediff-setup-windows-plain)
  (ediff-split-window-function #'split-window-horizontally)
  (ediff-merge-split-window-function #'split-window-horizontally)
  (ediff-keep-variants nil))

(defun aa/git-changed-file ()
  "Open a changed, staged or untracked file of the current repository."
  (interactive)
  (require 'magit)
  (let* ((default-directory (or (magit-toplevel) (user-error "Not in a git repository")))
         (files (delete-dups (append (magit-unstaged-files) (magit-staged-files)
                                     (magit-untracked-files)))))
    (find-file (completing-read "Changed file: "
                                (or files (user-error "No changed files")) nil t))))

(defun aa/git-diff-view ()
  "Pick a changed file and show it side by side."
  (interactive)
  (require 'magit)
  (let* ((default-directory (or (magit-toplevel) (user-error "Not in a git repository")))
         (unstaged (magit-unstaged-files))
         (staged (magit-staged-files))
         (files (delete-dups (append unstaged staged)))
         (here (car (member (magit-current-file) files)))
         (file (cond ((null files) (user-error "No changes to diff"))
                     ((null (cdr files)) (car files))
                     (t (completing-read "Diff file: " files nil t nil nil here)))))
    (if (member file unstaged)
        (magit-ediff-show-unstaged file)
      (magit-ediff-show-staged file))))

(defun aa/git--side (rev file)
  "Buffer of FILE at REV (\"{worktree}\" for the working tree), or an empty one if absent."
  (if (if (equal rev "{worktree}")
          (file-exists-p file)
        (magit-git-success "cat-file" "-e" (concat rev ":" file)))
      (magit-ediff--find-file rev file)
    (with-current-buffer (get-buffer-create (format " *absent %s:%s*" rev file))
      (erase-buffer)
      (current-buffer))))

(defun aa/git-diff-branch ()
  "Pick a file this branch changed against origin and show it side by side."
  (interactive)
  (require 'magit)
  (require 'magit-ediff)
  (let* ((default-directory (or (magit-toplevel) (user-error "Not in a git repository")))
         (upstream (or (seq-find #'magit-rev-verify '("origin/HEAD" "origin/main" "origin/master"))
                       (user-error "No origin/HEAD, origin/main or origin/master")))
         (base (or (magit-git-string "merge-base" upstream "HEAD")
                   (user-error "No common ancestor with %s" upstream)))
         (files (magit-git-lines "diff" "--name-only" base))
         (file (cond ((null files) (user-error "No changes against %s" upstream))
                     ((null (cdr files)) (car files))
                     (t (completing-read (format "Diff against %s: " upstream) files nil t nil nil
                                         (car (member (magit-current-file) files)))))))
    (magit-ediff-buffers (aa/git--side base file) (aa/git--side "{worktree}" file))))

(defun aa/git-diff-file ()
  "Show this file side by side: index (left) against the working tree (right)."
  (interactive)
  (require 'magit)
  (magit-ediff-show-unstaged
   (or (magit-current-file) (user-error "Not visiting a file in a git repository"))))

(defconst aa/diff-backgrounds
  '((magit-diff-added . "#2c3f3d") (magit-diff-added-highlight . "#2f4f42")
    (magit-diff-removed . "#3e2e39") (magit-diff-removed-highlight . "#4f323c")
    (magit-diff-refine-added . "#36734e") (magit-diff-refine-removed . "#733941")
    (ediff-current-diff-A . "#4f323c") (ediff-fine-diff-A . "#733941")
    (ediff-current-diff-B . "#2f4f42") (ediff-fine-diff-B . "#36734e")
    (ediff-current-diff-C . "#34414e") (ediff-fine-diff-C . "#466372")
    (ediff-current-diff-Ancestor . "#34414e") (ediff-fine-diff-Ancestor . "#466372")
    (ediff-even-diff-A . "#313546") (ediff-odd-diff-A . "#313546")
    (ediff-even-diff-B . "#313546") (ediff-odd-diff-B . "#313546")
    (ediff-even-diff-C . "#313546") (ediff-odd-diff-C . "#313546"))
  "Background of each diff face.")

(defun aa/diff-faces (&rest _)
  "Apply `aa/diff-backgrounds' to the diff faces that are already defined."
  (pcase-dolist (`(,face . ,bg) aa/diff-backgrounds)
    (when (facep face)

      (set-face-attribute face nil :background bg :foreground 'unspecified :extend t))))

(with-eval-after-load 'magit-diff (aa/diff-faces))
(with-eval-after-load 'ediff-init (aa/diff-faces))
(add-hook 'enable-theme-functions #'aa/diff-faces)

(defun aa/display-in-new-tab-unless-current (buffer alist)
  "Display action: show BUFFER in a new tab unless it is the current buffer."
  (unless (eq buffer (window-buffer))
    (display-buffer-in-new-tab buffer alist)))

(defun aa/call-keeping-diff (command)
  "Call COMMAND interactively; inside ediff, buffers it opens go to a new tab."

  (let ((this-command command))
    (if (bound-and-true-p ediff-this-buffer-ediff-sessions)
        (let ((display-buffer-overriding-action '(aa/display-in-new-tab-unless-current))
              (switch-to-buffer-obey-display-actions t))
          (call-interactively command))
      (call-interactively command))))

(defmacro aa/def-nav (name command)
  "Define NAME, which runs COMMAND through `aa/call-keeping-diff'."
  `(defun ,name ()
     ,(format "Run `%s'; inside a diff, another file opens in a new tab." command)
     (interactive)
     (aa/call-keeping-diff #',command)))

(aa/def-nav aa/goto-definition xref-find-definitions)
(aa/def-nav aa/goto-references xref-find-references)
(aa/def-nav aa/goto-implementation eglot-find-implementation)
(aa/def-nav aa/goto-type-definition eglot-find-typeDefinition)

(defun aa/blame-toggle ()
  "Toggle magit blame for the current file."
  (interactive)
  (if (bound-and-true-p magit-blame-mode)
      (magit-blame-quit)
    (call-interactively #'magit-blame-addition)))

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
