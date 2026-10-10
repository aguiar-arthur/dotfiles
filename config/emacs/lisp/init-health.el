;;; -*- lexical-binding: t -*-

(require 'package)
(require 'seq)

(defun aa/health--executables ()
  "Rows for the programs listed in `aa/doctor-executables'."
  (let (rows)
    (pcase-dolist (`(,program . ,need) aa/doctor-executables)
      (let ((path (executable-find program)))
        (cond (path (push (list 'ok (format "%s: %s" program path)) rows))
              ((eq need 'required) (push (list 'error (format "%s is missing (brew bundle)" program)) rows))
              ((eq need 'optional) (push (list 'warn (format "%s is missing; some commands will not work" program)) rows))
              ((memq need aa/languages)
               (push (list 'warn (format "%s is missing; %s support needs it" program need)) rows)))))
    (nreverse rows)))

(defun aa/health--archive-age ()
  "Days since the package index was refreshed, or nil when it never was."
  (let ((files (file-expand-wildcards (expand-file-name "archives/*/archive-contents" package-user-dir))))
    (when files
      (/ (float-time (time-subtract nil (apply #'max (mapcar (lambda (f) (float-time (file-attribute-modification-time (file-attributes f)))) files))))
         86400))))

(defun aa/package-backup-dirs ()
  "Backups of the package directory, newest first."
  (sort (directory-files aa/data-dir t "\\`elpa\\.bak\\.[0-9-]+\\'") #'string>))

(defun aa/health-report ()
  "Return the health checks as a list of (LEVEL TEXT), LEVEL being ok, warn, error or info."
  (let ((rows nil)
        (age (aa/health--archive-age))
        (backups (aa/package-backup-dirs))
        (local (expand-file-name "local.el" aa/config-dir)))
    (push (if (version<= "29.1" emacs-version)
              (list 'ok (format "Emacs %s" emacs-version))
            (list 'error (format "Emacs %s is older than 29.1" emacs-version)))
          rows)
    (push (list 'info (format "native compilation %s, started in %s"
                              (if (featurep 'native-compile) "available (off by design)" "not built in")
                              (if noninteractive "n/a (batch)" (emacs-init-time "%.2f s"))))
          rows)
    (if aa/failed-modules
        (pcase-dolist (`(,name . ,message) (reverse aa/failed-modules))
          (push (list 'error (format "%s failed: %s" name message)) rows))
      (push (list 'ok "every module loaded") rows))
    (push (list 'info (if (file-exists-p local) (format "local overrides: %s" local) "no local.el (defaults only)")) rows)
    (push (if (custom-theme-enabled-p aa/theme)
              (list 'ok (format "theme %s" aa/theme))
            (list 'error (format "theme %s is not active" aa/theme)))
          rows)
    (setq rows (append (reverse (aa/health--executables)) rows))
    (push (cond ((not (display-graphic-p)) (list 'info "terminal frame: the terminal draws the font and icons"))
                ((find-font (font-spec :name aa/font-family)) (list 'ok (format "font %s" aa/font-family)))
                (t (list 'warn (format "font %s is not installed (brew bundle)" aa/font-family))))
          rows)
    (push (list 'info (format "%d packages in %s" (length package-alist) package-user-dir)) rows)
    (push (cond ((null age) (list 'warn "the package index was never downloaded"))
                ((> age 30) (list 'warn (format "package index is %d days old (M-x aa/update-packages)" age)))
                (t (list 'ok (format "package index is %d days old" age))))
          rows)
    (push (if backups
              (list 'ok (format "%d package backup(s), newest %s" (length backups) (file-name-nondirectory (car backups))))
            (list 'info "no package backup yet (M-x aa/update-packages makes one)"))
          rows)
    (push (if (file-writable-p aa/data-dir)
              (list 'ok (format "data directory %s" aa/data-dir))
            (list 'error (format "data directory %s is not writable" aa/data-dir)))
          rows)
    (nreverse rows)))

(defun aa/health--line (row)
  "Format ROW as one line of the report."
  (format "%-6s %s" (pcase (car row) ('ok "ok") ('warn "WARN") ('error "ERROR") (_ "info")) (cadr row)))

(defun aa/doctor ()
  "Show the health of this configuration."
  (interactive)
  (let ((rows (aa/health-report)))
    (with-current-buffer (get-buffer-create "*doctor*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "Emacs configuration health\n\n")
        (dolist (row rows)
          (insert (propertize (aa/health--line row)
                              'face (pcase (car row) ('ok 'success) ('warn 'warning) ('error 'error) (_ 'shadow)))
                  "\n"))
        (goto-char (point-min))
        (special-mode))
      (pop-to-buffer (current-buffer)))))

(defun aa/doctor-batch ()
  "Print the health report and exit with the number of errors."
  (let ((rows (aa/health-report)))
    (dolist (row rows) (princ (concat (aa/health--line row) "\n")))
    (kill-emacs (min 1 (seq-count (lambda (row) (eq (car row) 'error)) rows)))))

(defun aa/report-failed-modules ()
  "Tell the user when a module failed at startup."
  (when aa/failed-modules
    (message "%d part(s) of the configuration failed at startup (%s): SPC o h shows the details"
             (length aa/failed-modules)
             (mapconcat (lambda (entry) (format "%s" (car entry))) aa/failed-modules ", "))))

(add-hook 'emacs-startup-hook (lambda () (run-with-idle-timer 0.5 nil #'aa/report-failed-modules)))

(defun aa/backup-packages ()
  "Copy the package directory to a dated backup and keep the newest `aa/package-backups'."
  (interactive)
  (let ((target (expand-file-name (format-time-string "elpa.bak.%Y%m%d-%H%M%S") aa/data-dir)))
    (copy-directory (directory-file-name package-user-dir) target t)
    (dolist (old (nthcdr aa/package-backups (aa/package-backup-dirs)))
      (delete-directory old t))
    (message "Packages backed up to %s" target)
    target))

(defun aa/update-packages ()
  "Back up the packages, refresh the index and upgrade every installed package."
  (interactive)
  (let ((backup (aa/backup-packages)))
    (package-refresh-contents)
    (package-upgrade-all)
    (message "Packages updated. Backup: %s. If something broke: M-x aa/rollback-packages" backup)))

(defun aa/rollback-packages (backup)
  "Replace the package directory with BACKUP, keeping the current one aside."
  (interactive
   (list (or (completing-read "Restore packages from: "
                              (mapcar #'file-name-nondirectory (aa/package-backup-dirs)) nil t)
             (user-error "No package backup"))))
  (let ((source (expand-file-name backup aa/data-dir))
        (current (directory-file-name package-user-dir))
        (aside (expand-file-name (format-time-string "elpa.broken.%Y%m%d-%H%M%S") aa/data-dir)))
    (unless (file-directory-p source) (user-error "No backup named %s" backup))
    (rename-file current aside)
    (copy-directory source current t)
    (message "Restored %s. The previous packages are in %s. Restart Emacs." backup aside)))

(provide 'init-health)
