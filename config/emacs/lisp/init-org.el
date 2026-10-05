;;; init-org.el --- Org: layout, TODOs, capture, refile, agenda, babel, export -*- lexical-binding: t -*-

;; ~/org (created on first start, nothing is overwritten):
;;   inbox.org     everything that arrives; empty it by refiling
;;   tasks.org     projects and next actions, by area
;;   calendar.org  appointments
;;   journal.org   week/day journal
;;   notes/        org-roam notes (notes/daily/ for dailies)
;;   slides/       Beamer presentations
;;   archive/      archived tasks

(defconst aa/org-dir (file-name-as-directory (expand-file-name "~/org/"))
  "Root of the Org files.")

(defun aa/org-file (name)
  "Absolute path of NAME inside `aa/org-dir'."
  (expand-file-name name aa/org-dir))

(defun aa/org-bootstrap ()
  "Create the folders and seed files of `aa/org-dir' when missing."
  (dolist (dir '("" "notes/" "slides/" "archive/"))
    (make-directory (aa/org-file dir) t))
  (pcase-dolist (`(,name . ,content)
                 '(("inbox.org" . "#+title: Inbox\n")
                   ("tasks.org" . "#+title: Tasks and projects\n\n* Personal\n* Work\n* Study\n")
                   ("calendar.org" . "#+title: Calendar\n")
                   ("journal.org" . "#+title: Journal\n")))
    (unless (file-exists-p (aa/org-file name))
      (with-temp-file (aa/org-file name) (insert content)))))

(aa/org-bootstrap)

(defun aa/org-find-file ()
  "Open an Org file from `aa/org-dir'."
  (interactive)
  (let* ((default-directory aa/org-dir)
         (files (directory-files-recursively aa/org-dir "\\.org\\'")))
    (find-file (expand-file-name
                (completing-read "Org: " (mapcar #'file-relative-name files) nil t)
                aa/org-dir))))

(defun aa/search-org ()
  "Search all of ~/org with ripgrep."
  (interactive)
  (consult-ripgrep aa/org-dir))

(defun aa/toggle-emphasis-markers ()
  "Show or hide emphasis markers (*bold*, /italic/...) in this buffer."
  (interactive)
  (setq-local org-hide-emphasis-markers (not org-hide-emphasis-markers))
  (when (derived-mode-p 'org-mode) (org-restart-font-lock)))

;; ------------------------------------------------------------------
;; Org (built in)
;; ------------------------------------------------------------------
(use-package org
  :ensure nil
  :defer t
  :config
  (require 'org-habit)
  (require 'org-tempo)                          ; <s TAB, <q TAB...

  (setq org-directory aa/org-dir
        org-default-notes-file (aa/org-file "inbox.org")

        ;; Look and editing
        org-startup-indented t
        org-startup-folded 'content
        org-startup-with-inline-images t
        org-image-actual-width '(500)
        org-ellipsis "…"
        org-pretty-entities t
        org-hide-emphasis-markers t
        org-use-sub-superscripts '{}
        org-return-follows-link t
        org-special-ctrl-a/e t
        org-insert-heading-respect-content t
        org-M-RET-may-split-line '((default . nil))
        org-blank-before-new-entry '((heading . t) (plain-list-item . nil))
        org-cycle-separator-lines 1
        org-fontify-done-headline t
        org-fontify-whole-heading-line t
        org-fontify-quote-and-verse-blocks t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 0
        org-confirm-babel-evaluate t

        ;; TODO flow
        org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCELLED(c@)"))
        org-todo-keyword-faces
        '(("NEXT" . (:foreground "#ff79c6" :weight bold))
          ("WAIT" . (:foreground "#ffb86c" :weight bold))
          ("CANCELLED" . (:foreground "#6272a4" :weight bold)))
        org-enforce-todo-dependencies t
        org-log-done 'time
        org-log-into-drawer t
        org-log-reschedule 'time
        org-log-redeadline 'time

        ;; Contexts (mutually exclusive) and markers
        org-tag-alist
        '((:startgroup)
          ("@home" . ?h) ("@work" . ?w) ("@study" . ?s) ("@out" . ?o)
          (:endgroup)
          ("PROJECT" . ?p) ("meeting" . ?m) ("slides" . ?l) ("idea" . ?i))
        org-tags-exclude-from-inheritance '("PROJECT")
        org-stuck-projects '("+PROJECT/-DONE-CANCELLED" ("NEXT") nil "")

        ;; Refile and archive
        org-refile-targets `((,(aa/org-file "tasks.org") :maxlevel . 3)
                             (,(aa/org-file "calendar.org") :level . 1))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm
        org-archive-location (concat (aa/org-file "archive/") "%s_archive::")

        ;; Clock and habits
        org-clock-persist 'history
        org-clock-persist-file (expand-file-name "org-clock-save.el" aa/data-dir)
        org-clock-out-remove-zero-time-clocks t
        org-clock-report-include-clocking-task t
        org-habit-graph-column 60
        org-habit-show-habits-only-for-today t

        ;; LaTeX preview (C-c C-x C-l)
        org-preview-latex-default-process 'dvisvgm)

  (plist-put org-format-latex-options :scale 1.4)
  (org-clock-persistence-insinuate)

  ;; Babel. Clojure blocks run through CIDER: jack in first (`, j' in Clojure).
  (require 'ob-clojure)
  (setq org-babel-clojure-backend 'cider)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t) (shell . t) (python . t) (latex . t) (clojure . t)))

  ;; Heading sizes survive theme changes
  (custom-theme-set-faces
   'user
   '(org-document-title ((t (:height 1.5 :weight bold))))
   '(org-level-1 ((t (:height 1.3 :weight bold))))
   '(org-level-2 ((t (:height 1.2 :weight semi-bold))))
   '(org-level-3 ((t (:height 1.1 :weight semi-bold))))
   '(org-level-4 ((t (:height 1.05)))))

  ;; Keep the agenda files on disk up to date
  (add-hook 'auto-save-hook #'org-save-all-org-buffers)
  (dolist (fn '(org-refile org-archive-subtree))
    (advice-add fn :after (lambda (&rest _) (org-save-all-org-buffers)))))

;; ------------------------------------------------------------------
;; Capture (SPC i): everything lands in the inbox, except events and journal
;; ------------------------------------------------------------------
(setq org-capture-templates
      `(("t" "Task" entry (file ,(aa/org-file "inbox.org"))
         "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n%i" :empty-lines 1)
        ("e" "Event" entry (file ,(aa/org-file "calendar.org"))
         "* %?\n%^T\n" :empty-lines 1)
        ("n" "Note" entry (file ,(aa/org-file "inbox.org"))
         "* %?\n%U\n%i\n%a" :empty-lines 1)
        ("i" "Idea" entry (file ,(aa/org-file "inbox.org"))
         "* %? :idea:\n%U" :empty-lines 1)
        ("m" "Meeting" entry (file ,(aa/org-file "inbox.org"))
         "* Meeting: %? :meeting:\n%U\n** Agenda\n** Notes\n** Actions\n"
         :empty-lines 1 :clock-in t :clock-resume t)
        ("j" "Journal" entry (file+olp+datetree ,(aa/org-file "journal.org"))
         "* %<%H:%M> %?\n%i" :tree-type week)))

(add-hook 'org-capture-mode-hook #'evil-insert-state)

(defmacro aa/def-capture (name key doc)
  "Define NAME, a command that starts capture template KEY."
  `(defun ,name () ,doc (interactive) (org-capture nil ,key)))

(aa/def-capture aa/capture-task "t" "Capture a task.")
(aa/def-capture aa/capture-event "e" "Capture an event.")
(aa/def-capture aa/capture-note "n" "Capture a note.")
(aa/def-capture aa/capture-idea "i" "Capture an idea.")
(aa/def-capture aa/capture-meeting "m" "Capture a meeting (clocked).")
(aa/def-capture aa/capture-journal "j" "Write in the journal.")

;; ------------------------------------------------------------------
;; Agenda (inbox, tasks and calendar; journal and archive stay out)
;; ------------------------------------------------------------------
(setq org-agenda-files (mapcar #'aa/org-file '("inbox.org" "tasks.org" "calendar.org"))
      calendar-week-start-day 1)

(setq org-agenda-custom-commands
      `(("d" "Day"
         ((agenda "" ((org-agenda-span 'day) (org-deadline-warning-days 7)))
          (todo "NEXT" ((org-agenda-overriding-header "Next actions")))
          (todo "WAIT" ((org-agenda-overriding-header "Waiting")))))
        ("w" "Week" agenda "" ((org-agenda-span 'week)))
        ("n" "Next actions" todo "NEXT")
        ("W" "Waiting" todo "WAIT")
        ("i" "Inbox" alltodo ""
         ((org-agenda-files '(,(aa/org-file "inbox.org")))
          (org-agenda-overriding-header "Inbox: refile (, r) or delete")))
        ("p" "Projects" tags "PROJECT" ((org-agenda-overriding-header "Projects")))
        ("s" "Stuck projects" stuck "")
        ("r" "Weekly review"
         ((alltodo "" ((org-agenda-files '(,(aa/org-file "inbox.org")))
                       (org-agenda-overriding-header "1. Empty the inbox")))
          (stuck "" ((org-agenda-overriding-header "2. Stuck projects")))
          (todo "WAIT" ((org-agenda-overriding-header "3. Waiting")))
          (agenda "" ((org-agenda-span 'week)
                      (org-agenda-start-with-log-mode t)
                      (org-agenda-overriding-header "4. The week")))))))

(with-eval-after-load 'org-agenda
  (setq org-agenda-window-setup 'current-window
        org-agenda-restore-windows-after-quit t
        org-agenda-start-on-weekday 1
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-tags-column 'auto
        org-agenda-block-separator ?─
        org-deadline-warning-days 7
        org-agenda-prefix-format '((agenda . " %i %-12:c%?-12t% s")
                                   (todo . " %i %-12:c")
                                   (tags . " %i %-12:c")
                                   (search . " %i %-12:c"))))

(defmacro aa/def-agenda (name key doc)
  "Define NAME, a command that opens agenda view KEY."
  `(defun ,name () ,doc (interactive) (org-agenda nil ,key)))

(aa/def-agenda aa/agenda-day "d" "Day agenda.")
(aa/def-agenda aa/agenda-week "w" "Week agenda.")
(aa/def-agenda aa/agenda-next "n" "Next actions.")
(aa/def-agenda aa/agenda-wait "W" "Waiting items.")
(aa/def-agenda aa/agenda-inbox "i" "Inbox.")
(aa/def-agenda aa/agenda-projects "p" "Projects.")
(aa/def-agenda aa/agenda-stuck "s" "Stuck projects.")
(aa/def-agenda aa/agenda-review "r" "Weekly review.")

;; ------------------------------------------------------------------
;; Look
;; ------------------------------------------------------------------
(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :custom (org-modern-star '("◉" "○" "◈" "◇" "●" "○" "◈")))

(use-package org-appear                         ; reveal markers under the cursor
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-delay 0.1)
  (org-appear-autoemphasis t)
  (org-appear-autosubmarkers t)
  (org-appear-autolinks t)
  (org-appear-autoentities t))

;; ------------------------------------------------------------------
;; Export: PDF via MacTeX; Beamer slides with `#+latex_class: beamer'
;; ------------------------------------------------------------------
(with-eval-after-load 'ox-latex
  (setq org-latex-compiler "pdflatex"
        org-latex-pdf-process
        '("latexmk -f -pdf -%latex -interaction=nonstopmode -output-directory=%o %f")))

(with-eval-after-load 'ox
  (setq org-export-with-smart-quotes t
        org-export-with-sub-superscripts '{}
        org-export-coding-system 'utf-8))

(provide 'init-org)
;;; init-org.el ends here
