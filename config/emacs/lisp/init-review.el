;;; -*- lexical-binding: t -*-

(require 'cl-lib)

(defvar aa/review--entries nil
  "Entries of the review: plists with :section :status :file :old :rev-a :rev-b.")
(defvar aa/review--title nil "Title shown at the top of the review panel.")
(defvar aa/review--source nil "Function that recomputes the entries, or nil.")
(defvar aa/review--index nil "Index of the entry shown side by side.")
(defvar aa/review--wconf nil "Window configuration before the review started.")
(defvar aa/review--root nil "Repository root of the review.")
(defconst aa/review--panel-name "*review*" "Name of the review panel buffer.")

(defvar-keymap aa/review-mode-map :doc "Keys active in every buffer of a review.")

(define-minor-mode aa/review-mode
  "Review keys: TAB / S-TAB next / previous file, q ends the review."
  :keymap aa/review-mode-map
  (when (fboundp 'evil-normalize-keymaps) (evil-normalize-keymaps)))

(defun aa/review--side (rev file)
  "Buffer of FILE at REV, or an empty buffer when FILE does not exist there."
  (let ((exists (pcase rev
                  ("{worktree}" (file-exists-p file))
                  ("{index}" (magit-git-success "cat-file" "-e" (concat ":" file)))
                  (_ (magit-git-success "cat-file" "-e" (concat rev ":" file))))))
    (if exists
        (magit-ediff--find-file rev file)
      (with-current-buffer (get-buffer-create (format " *absent %s:%s*" rev file))
        (let ((inhibit-read-only t)) (erase-buffer))
        (setq buffer-read-only t)
        (current-buffer)))))

(defun aa/review--name-status (section rev-a rev-b &rest args)
  "Entries for SECTION from `git diff --name-status ARGS', compared REV-A to REV-B."
  (mapcar (lambda (line)
            (let* ((fields (split-string line "\t"))
                   (status (substring (car fields) 0 1))
                   (old (cadr fields))
                   (file (car (last fields))))
              (list :section section :status status :file file :old old
                    :rev-a rev-a :rev-b rev-b)))
          (apply #'magit-git-lines "diff" "--name-status" args)))

(defun aa/review--worktree-entries ()
  "Unstaged, staged and untracked changes of the repository."
  (append
   (aa/review--name-status "Changes" "{index}" "{worktree}")
   (mapcar (lambda (file)
             (list :section "Untracked" :status "?" :file file :old file
                   :rev-a "{index}" :rev-b "{worktree}"))
           (magit-untracked-files))
   (aa/review--name-status "Staged" "HEAD" "{index}" "--cached")))

(defun aa/review--upstream ()
  "First of origin/HEAD, origin/main and origin/master that exists."
  (or (seq-find #'magit-rev-verify '("origin/HEAD" "origin/main" "origin/master"))
      (user-error "No origin/HEAD, origin/main or origin/master")))

(defun aa/review--branch-entries ()
  "Changes of the working tree since the branch left upstream."
  (let* ((upstream (aa/review--upstream))
         (base (or (magit-git-string "merge-base" upstream "HEAD")
                   (user-error "No common ancestor with %s" upstream))))
    (setq aa/review--title (format "Branch vs %s" upstream))
    (aa/review--name-status "Branch" base "{worktree}" base)))

(defun aa/review--quit-ediff ()
  "Close the current ediff session of the review without asking."
  (dolist (buf (buffer-list))
    (when (and (buffer-live-p buf) (eq (buffer-local-value 'major-mode buf) 'ediff-mode))
      (with-current-buffer buf
        (let ((ediff-keep-variants t))
          (ediff-really-quit nil))))))

(defun aa/review--render ()
  "Draw the review panel."
  (with-current-buffer (get-buffer-create aa/review--panel-name)
    (let ((inhibit-read-only t) (section nil) (line-of-current nil))
      (erase-buffer)
      (insert (propertize (or aa/review--title "Review") 'face 'bold) "\n")
      (cl-loop for entry in aa/review--entries
               for i from 0
               do (unless (equal section (plist-get entry :section))
                    (setq section (plist-get entry :section))
                    (insert "\n" (propertize section 'face 'font-lock-keyword-face) "\n"))
                  (let ((current (eql i aa/review--index)))
                    (when current (setq line-of-current (line-number-at-pos)))
                    (insert (propertize
                             (format "%s %s %s\n" (if current ">" " ")
                                     (plist-get entry :status) (plist-get entry :file))
                             'aa/review-index i
                             'face (if current 'highlight 'default)))))
      (when (null aa/review--entries) (insert "\nNo changes\n"))
      (goto-char (point-min))
      (when line-of-current (forward-line (1- line-of-current)))
      (dolist (win (get-buffer-window-list (current-buffer) nil t))
        (set-window-point win (point))))))

(defun aa/review--show-panel ()
  "Show the review panel in a left side window that survives ediff's layout."
  (let ((buf (get-buffer-create aa/review--panel-name)))
    (with-current-buffer buf
      (aa/review-panel-mode)
      (setq default-directory aa/review--root))
    (aa/review--render)
    (display-buffer-in-side-window
     buf '((side . left) (slot . 0) (window-width . 34)
           (window-parameters (no-delete-other-windows . t))))))

(defun aa/review--open (index)
  "Show entry INDEX side by side."
  (let* ((n (length aa/review--entries))
         (index (mod index n))
         (entry (nth index aa/review--entries))
         (default-directory aa/review--root))
    (aa/review--quit-ediff)
    (setq aa/review--index index)
    (aa/review--render)
    (let ((a (aa/review--side (plist-get entry :rev-a) (plist-get entry :old)))
          (b (aa/review--side (plist-get entry :rev-b) (plist-get entry :file))))
      (select-window (or (seq-find (lambda (w) (not (window-parameter w 'window-side)))
                                   (window-list nil 'nomini))
                         (selected-window)))
      (magit-ediff-buffers a b))))

(defun aa/review--enable-in-session ()
  "Turn on the review keys in the control buffer and both sides."
  (when aa/review--entries
    (aa/review-mode 1)
    (dolist (buf (list ediff-buffer-A ediff-buffer-B))
      (when (buffer-live-p buf)
        (with-current-buffer buf (aa/review-mode 1))))))

(defun aa/review--disable-in-session ()
  "Turn off the review keys in both sides of the closing session."
  (dolist (buf (list ediff-buffer-A ediff-buffer-B))
    (when (buffer-live-p buf)
      (with-current-buffer buf (aa/review-mode -1)))))

(add-hook 'ediff-startup-hook #'aa/review--enable-in-session)
(add-hook 'ediff-cleanup-hook #'aa/review--disable-in-session)

(defun aa/review--start (title source)
  "Start a review titled TITLE whose entries come from SOURCE."
  (require 'magit)
  (require 'magit-ediff)
  (let* ((root (or (magit-toplevel) (user-error "Not in a git repository")))
         (default-directory root)
         (here (magit-current-file)))
    (when aa/review--entries (aa/review-quit))
    (setq aa/review--root root
          aa/review--title title
          aa/review--source source
          aa/review--wconf (current-window-configuration)
          aa/review--entries (funcall source))
    (unless aa/review--entries (user-error "No changes to review"))
    (aa/review--show-panel)
    (aa/review--open (or (cl-position here aa/review--entries
                                      :key (lambda (e) (plist-get e :file)) :test #'equal)
                         0))))

(defun aa/review-worktree ()
  "Review unstaged, staged and untracked changes side by side."
  (interactive)
  (aa/review--start "Working tree" #'aa/review--worktree-entries))

(defun aa/review-branch ()
  "Review everything the branch changed against origin, side by side."
  (interactive)
  (aa/review--start "Branch" #'aa/review--branch-entries))

(defun aa/review-next ()
  "Show the next file of the review."
  (interactive)
  (aa/review--open (1+ aa/review--index)))

(defun aa/review-prev ()
  "Show the previous file of the review."
  (interactive)
  (aa/review--open (1- aa/review--index)))

(defun aa/review-open-at-point ()
  "Show the file on the current line of the review panel."
  (interactive)
  (when-let* ((i (get-text-property (line-beginning-position) 'aa/review-index)))
    (aa/review--open i)))

(defun aa/review-toggle-stage ()
  "Stage or unstage the file on the current panel line, then refresh the list."
  (interactive)
  (when-let* ((i (get-text-property (line-beginning-position) 'aa/review-index))
              (entry (nth i aa/review--entries))
              (default-directory aa/review--root))
    (unless (eq aa/review--source #'aa/review--worktree-entries)
      (user-error "Staging works in the working-tree review (SPC g v)"))
    (if (equal (plist-get entry :section) "Staged")
        (magit-call-git "reset" "-q" "--" (plist-get entry :file))
      (magit-call-git "add" "--" (plist-get entry :file)))
    (setq aa/review--entries (funcall aa/review--source))
    (if aa/review--entries
        (aa/review--open (min aa/review--index (1- (length aa/review--entries))))
      (aa/review-quit))))

(defun aa/review-quit ()
  "End the review and restore the previous layout."
  (interactive)
  (aa/review--quit-ediff)
  (setq aa/review--entries nil aa/review--index nil)
  (dolist (buf (buffer-list))
    (when (and (buffer-live-p buf) (buffer-local-value 'aa/review-mode buf))
      (with-current-buffer buf (aa/review-mode -1))))
  (dolist (buf (buffer-list))
    (when (or (equal (buffer-name buf) aa/review--panel-name)
              (string-prefix-p " *absent " (buffer-name buf)))
      (kill-buffer buf)))
  (when aa/review--wconf (set-window-configuration aa/review--wconf))
  (setq aa/review--wconf nil))

(define-derived-mode aa/review-panel-mode special-mode "Review"
  "List of the files in a review."
  (setq truncate-lines t)
  (hl-line-mode 1))

(provide 'init-review)
