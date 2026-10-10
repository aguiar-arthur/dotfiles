;;; -*- lexical-binding: t -*-
(require 'ert)
(require 'seq)

(defmacro test/with-sample-repo (var &rest body)
  (declare (indent 1))
  `(let* ((,var (file-name-as-directory (file-truename (make-temp-file "sample-repo" t))))
          (default-directory ,var)
          (process-environment (append '("GIT_AUTHOR_NAME=test" "GIT_AUTHOR_EMAIL=t@example.com"
                                         "GIT_COMMITTER_NAME=test" "GIT_COMMITTER_EMAIL=t@example.com")
                                       process-environment)))
     (unwind-protect
         (progn
           (call-process "git" nil nil nil "init" "-q")
           (with-temp-file (expand-file-name "clean.txt" ,var) (insert "clean\n"))
           (with-temp-file (expand-file-name "mod.txt" ,var) (insert "one\n"))
           (call-process "git" nil nil nil "add" ".")
           (call-process "git" nil nil nil "commit" "-qm" "initial")
           (with-temp-file (expand-file-name "mod.txt" ,var) (insert "one\ntwo\n"))
           (with-temp-file (expand-file-name "new.txt" ,var) (insert "new\n"))
           ,@body)
       (dolist (buf (buffer-list))
         (when (and (buffer-file-name buf) (string-prefix-p ,var (buffer-file-name buf)))
           (with-current-buffer buf (set-buffer-modified-p nil))
           (kill-buffer buf)))
       (delete-directory ,var t))))

(defun test/settle (seconds)
  (let ((deadline (+ (float-time) seconds)))
    (while (< (float-time) deadline)
      (accept-process-output nil 0.05))))

(ert-deftest behavior-wrap-toggle-reaches-every-buffer-and-later-ones ()
  (let ((aa/wrap t) (first (generate-new-buffer "wrap-a")) (second (generate-new-buffer "wrap-b")))
    (unwind-protect
        (progn
          (dolist (buf (list first second))
            (with-current-buffer buf (emacs-lisp-mode)))
          (should (buffer-local-value 'visual-line-mode first))
          (aa/toggle-wrap)
          (dolist (buf (list first second))
            (should (buffer-local-value 'truncate-lines buf))
            (should-not (buffer-local-value 'visual-line-mode buf)))
          (with-temp-buffer
            (text-mode)
            (should truncate-lines))
          (aa/toggle-wrap)
          (dolist (buf (list first second))
            (should (buffer-local-value 'visual-line-mode buf))))
      (kill-buffer first)
      (kill-buffer second)
      (setq aa/wrap t))))

(ert-deftest behavior-no-lsp-in-revision-buffers ()
  (let ((started nil))
    (cl-letf (((symbol-function 'eglot-ensure) (lambda () (setq started t))))
      (with-temp-buffer
        (rename-buffer "core.clj.~abc123~" t)
        (aa/clojure-lsp)
        (should-not started))
      (with-temp-buffer
        (rename-buffer "core.clj" t)
        (aa/clojure-lsp)
        (should started)))))

(ert-deftest behavior-tree-keys-work-in-a-terminal ()
  (test/with-sample-repo repo
    (find-file (expand-file-name "mod.txt" repo))
    (aa/tree-toggle)
    (test/settle 1.5)
    (let ((window (treemacs-get-local-window)))
      (should window)
      (with-current-buffer (window-buffer window)
        (should (eq evil-state 'treemacs))
        (dolist (pair '(("j" . treemacs-next-line) ("k" . treemacs-previous-line)
                        ("RET" . treemacs-RET-action) ("TAB" . treemacs-TAB-action)
                        ("h" . treemacs-COLLAPSE-action) ("l" . treemacs-RET-action)))
          (should (eq (key-binding (kbd (car pair))) (cdr pair))))
        (should (keymapp (key-binding (kbd "SPC"))))))
    (aa/tree-toggle)
    (should-not (treemacs-get-local-window))))

(ert-deftest behavior-tree-shows-only-the-current-project ()
  (test/with-sample-repo repo
    (find-file (expand-file-name "mod.txt" repo))
    (aa/tree-toggle)
    (test/settle 1)
    (let ((paths (mapcar (lambda (project) (file-name-as-directory (file-truename (treemacs-project->path project))))
                         (treemacs-workspace->projects (treemacs-current-workspace)))))
      (should (equal paths (list repo))))
    (aa/tree-toggle)))

(ert-deftest behavior-tree-marks-git-status-with-distinct-colors ()
  (let ((default (face-attribute 'default :foreground nil t))
        (colors nil))
    (dolist (face '(treemacs-git-modified-face treemacs-git-added-face treemacs-git-untracked-face
                    treemacs-git-renamed-face treemacs-git-conflict-face treemacs-git-ignored-face))
      (let ((color (face-attribute face :foreground nil t)))
        (should (stringp color))
        (should-not (equal color default))
        (push color colors)))
    (should (= (length colors) (length (delete-dups (copy-sequence colors)))))))

(defun test/tree-face-of (name)
  (save-excursion
    (goto-char (point-min))
    (when (search-forward name nil t)
      (ensure-list (get-text-property (match-beginning 0) 'face)))))

(ert-deftest behavior-tree-nodes-carry-git-faces ()
  (test/with-sample-repo repo
    (find-file (expand-file-name "mod.txt" repo))
    (aa/tree-toggle)
    (test/settle 3)
    (with-current-buffer (window-buffer (treemacs-get-local-window))
      (should (memq 'treemacs-git-modified-face (test/tree-face-of "mod.txt")))
      (should (memq 'treemacs-git-untracked-face (test/tree-face-of "new.txt")))
      (should (memq 'treemacs-git-unmodified-face (test/tree-face-of "clean.txt"))))
    (aa/tree-toggle)))

(ert-deftest behavior-opening-a-file-does-not-show-the-dashboard ()
  (should-not initial-buffer-choice))

(ert-deftest behavior-evil-moves-by-screen-line-in-wrapped-buffers ()
  (should evil-respect-visual-line-mode))

(ert-deftest behavior-review-worktree-lists-changes-and-cleans-up ()
  (test/with-sample-repo repo
    (find-file (expand-file-name "clean.txt" repo))
    (let ((windows-before (length (window-list))))
      (aa/review-worktree)
      (test/settle 2)
      (should (get-buffer aa/review--panel-name))
      (with-current-buffer aa/review--panel-name
        (let ((text (buffer-string)))
          (should (string-match-p "mod\\.txt" text))
          (should (string-match-p "new\\.txt" text))
          (should-not (string-match-p "clean\\.txt" text))))
      (aa/review-quit)
      (test/settle 1)
      (should-not (get-buffer-window aa/review--panel-name))
      (should (= (length (window-list)) windows-before)))))

(ert-deftest behavior-local-el-overrides-settings ()
  (let* ((dir (file-name-as-directory (make-temp-file "local-el" t)))
         (aa/config-dir dir)
         (aa/failed-modules nil)
         (aa/font-height 130))
    (unwind-protect
        (progn
          (with-temp-file (expand-file-name "local.el" dir)
            (insert "(setq aa/font-height 160)\n"))
          (aa/load-local)
          (should (= aa/font-height 160))
          (should-not aa/failed-modules))
      (delete-directory dir t))))

(ert-deftest behavior-broken-local-el-is-reported-not-fatal ()
  (let* ((dir (file-name-as-directory (make-temp-file "local-el" t)))
         (aa/config-dir dir)
         (aa/failed-modules nil))
    (unwind-protect
        (progn
          (with-temp-file (expand-file-name "local.el" dir)
            (insert "(error \"broken on purpose\")\n"))
          (aa/load-local)
          (should (assq 'local.el aa/failed-modules))
          (should (seq-find (lambda (row) (and (eq (car row) 'error) (string-match-p "local.el" (cadr row))))
                            (aa/health-report))))
      (delete-directory dir t))))

(ert-deftest behavior-health-report-covers-the-basics ()
  (let ((rows (aa/health-report)))
    (should (seq-every-p (lambda (row) (memq (car row) '(ok warn error info))) rows))
    (dolist (needle '("Emacs" "theme" "git" "package index" "data directory"))
      (should (seq-find (lambda (row) (string-match-p needle (cadr row))) rows)))))

(ert-deftest behavior-failed-module-is-announced-at-startup ()
  (let ((aa/failed-modules '((init-fake . "boom")))
        (shown nil))
    (cl-letf (((symbol-function 'message) (lambda (fmt &rest args) (setq shown (apply #'format fmt args)))))
      (aa/report-failed-modules))
    (should (string-match-p "init-fake" shown))
    (should (string-match-p "SPC o h" shown))))

(ert-deftest behavior-package-backup-and-rollback ()
  (let* ((root (file-name-as-directory (make-temp-file "emacs-data" t)))
         (aa/data-dir root)
         (package-user-dir (expand-file-name "elpa/" root))
         (aa/package-backups 2)
         (inhibit-message t))
    (unwind-protect
        (progn
          (make-directory (expand-file-name "pkg-1" package-user-dir) t)
          (with-temp-file (expand-file-name "pkg-1/version" package-user-dir) (insert "good"))
          (let ((first (aa/backup-packages)))
            (should (file-exists-p (expand-file-name "pkg-1/version" first))))
          (dotimes (_ 2) (sleep-for 1.1) (aa/backup-packages))
          (should (= (length (aa/package-backup-dirs)) 2))
          (with-temp-file (expand-file-name "pkg-1/version" package-user-dir) (insert "broken"))
          (aa/rollback-packages (file-name-nondirectory (car (aa/package-backup-dirs))))
          (should (equal (with-temp-buffer
                           (insert-file-contents (expand-file-name "pkg-1/version" package-user-dir))
                           (buffer-string))
                         "good"))
          (should (directory-files root nil "\\`elpa\\.broken\\.")))
      (delete-directory root t))))

(ert-deftest behavior-ediff-starts-on-the-first-change ()
  (require 'ediff)
  (let ((a (generate-new-buffer "ediff-a"))
        (b (generate-new-buffer "ediff-b"))
        (inhibit-message t)
        (control nil))
    (unwind-protect
        (progn
          (with-current-buffer a (insert "one\n"))
          (with-current-buffer b (insert "one\ntwo\n"))
          (ediff-buffers a b)
          (setq control (get-buffer "*Ediff Control Panel*"))
          (with-current-buffer control
            (should (= ediff-current-difference 0))))
      (when (buffer-live-p control)
        (with-current-buffer control
          (let ((ediff-keep-variants t)) (ediff-really-quit nil))))
      (dolist (buf (list a b)) (when (buffer-live-p buf) (kill-buffer buf))))))

(ert-deftest behavior-tree-drops-missing-projects-without-asking ()
  (require 'treemacs)
  (should (eq treemacs-missing-project-action 'remove)))
