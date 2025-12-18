;; -*- lexical-binding: t; -*-

;; ---------------------------
;; Editing helpers
;; ---------------------------
(defun aa/indent-buffer ()
  "Indent the current buffer"
  (interactive)
  (indent-region (point-min) (point-max)))

;; ---------------------------
;; Window resize step helpers
;; ---------------------------
(defcustom aa/window-resize-step 10
  "Number of columns/rows to resize windows by per keypress."
  :type 'integer
  :group 'windows)

(defun aa/window-decrease-width (amount)
  "Shrink current window horizontally by AMOUNT steps."
  (interactive "P")
  (let* ((count (if amount (prefix-numeric-value amount) 1))
         (delta (* (max 1 count) aa/window-resize-step)))
    (shrink-window-horizontally delta)))

(defun aa/window-increase-width (amount)
  "Enlarge current window horizontally by AMOUNT steps."
  (interactive "P")
  (let* ((count (if amount (prefix-numeric-value amount) 1))
         (delta (* (max 1 count) aa/window-resize-step)))
    (enlarge-window-horizontally delta)))

(defun aa/window-decrease-height (amount)
  "Shrink current window vertically by AMOUNT steps."
  (interactive "P")
  (let* ((count (if amount (prefix-numeric-value amount) 1))
         (delta (* (max 1 count) aa/window-resize-step)))
    (shrink-window delta)))

(defun aa/window-increase-height (amount)
  "Enlarge current window vertically by AMOUNT steps."
  (interactive "P")
  (let* ((count (if amount (prefix-numeric-value amount) 1))
         (delta (* (max 1 count) aa/window-resize-step)))
    (enlarge-window delta)))
