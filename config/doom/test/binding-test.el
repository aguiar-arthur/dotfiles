;; -*- lexical-binding: t; -*-

(require 'ert)

(require 'doom-keybinds)

(defun aa--lookup-leader (keys)
  "Resolve KEYS like \"l d\" inside `doom-leader-map`, following nested prefixes."
  (let* ((parts (split-string keys " " t))
         (map doom-leader-map)
         (result nil))
    (dolist (k parts)
      (setq result (lookup-key map (kbd k)))
      (setq map (and (keymapp result) result)))
    (and (not (numberp result)) result)))

(defun aa--lookup-localleader-in (_mode-map keys)
  "Resolve localleader KEYS in the current buffer by asking `key-binding`."
  (key-binding (kbd (format "%s %s" doom-localleader-key keys))))

(defun aa--assert-command (sym)
  (should (commandp sym)))

;; ---------------------------
;; Leader: window keys
;; ---------------------------
(ert-deftest bindings:leader-window-keys-exist ()
  (should (eq (aa--lookup-leader "w h") #'evil-window-left))
  (should (eq (aa--lookup-leader "w j") #'evil-window-down))
  (should (eq (aa--lookup-leader "w k") #'evil-window-up))
  (should (eq (aa--lookup-leader "w l") #'evil-window-right))
  (should (eq (aa--lookup-leader "w w") #'ace-window))
  (aa--assert-command 'evil-window-left)
  (aa--assert-command 'evil-window-down)
  (aa--assert-command 'evil-window-up)
  (aa--assert-command 'evil-window-right)
  (aa--assert-command 'ace-window))

;; ---------------------------
;; Leader: code keys
;; ---------------------------
(ert-deftest bindings:leader-code-keys-exist ()
  (should (eq (aa--lookup-leader "c c") #'comment-line))
  (should (eq (aa--lookup-leader "c C") #'comment-region))
  (should (eq (aa--lookup-leader "c t") #'comment-dwim))
  (aa--assert-command 'comment-line)
  (aa--assert-command 'comment-region)
  (aa--assert-command 'comment-dwim)
  ;; optional/custom
  (when (fboundp 'aa/indent-buffer)
    (should (eq (aa--lookup-leader "c I") #'aa/indent-buffer))
    (aa--assert-command 'aa/indent-buffer))
  ;; LSP-powered code helpers only when LSP module is enabled
  (when (modulep! :tools lsp)
    (require 'lsp-mode nil 'noerror)
    (when (fboundp 'lsp-extract-function)
      (should (eq (aa--lookup-leader "c f") #'lsp-extract-function))
      (aa--assert-command 'lsp-extract-function))
    (when (fboundp 'lsp-extract-variable)
      (should (eq (aa--lookup-leader "c v") #'lsp-extract-variable))
      (aa--assert-command 'lsp-extract-variable))
    (when (fboundp 'lsp-refactor)
      (should (eq (aa--lookup-leader "c r") #'lsp-refactor))
      (aa--assert-command 'lsp-refactor))))

;; ---------------------------
;; Leader: LSP keys (split by package)
;; ---------------------------
(ert-deftest bindings:leader-lsp-core-exist ()
  (when (modulep! :tools lsp)
    (require 'lsp-mode nil 'noerror)
    (should (eq (aa--lookup-leader "l d") #'lsp-find-definition))
    (should (eq (aa--lookup-leader "l r") #'lsp-find-references))
    (should (eq (aa--lookup-leader "l i") #'lsp-find-implementation))
    (should (eq (aa--lookup-leader "l t") #'lsp-goto-type-definition))
    (should (eq (aa--lookup-leader "l n") #'lsp-rename))
    (should (eq (aa--lookup-leader "l f") #'lsp-format-buffer))
    (should (eq (aa--lookup-leader "l o") #'lsp-organize-imports))
    (should (eq (aa--lookup-leader "l a") #'lsp-execute-code-action))
    (should (eq (aa--lookup-leader "l R") #'lsp-restart-workspace))
    (should (eq (aa--lookup-leader "l D") #'lsp-describe-thing-at-point))
    (aa--assert-command 'lsp-find-definition)
    (aa--assert-command 'lsp-find-references)
    (aa--assert-command 'lsp-find-implementation)
    (aa--assert-command 'lsp-goto-type-definition)
    (aa--assert-command 'lsp-rename)
    (aa--assert-command 'lsp-format-buffer)
    (aa--assert-command 'lsp-organize-imports)
    (aa--assert-command 'lsp-execute-code-action)
    (aa--assert-command 'lsp-restart-workspace)
    (aa--assert-command 'lsp-describe-thing-at-point)
    (when (fboundp 'rename-visited-file)
      (should (eq (aa--lookup-leader "l N") #'rename-visited-file))
      (aa--assert-command 'rename-visited-file))))

(ert-deftest bindings:leader-lsp-ui-exist-when-available ()
  (when (fboundp 'lsp-ui-doc-glance)
    (should (eq (aa--lookup-leader "l h") #'lsp-ui-doc-glance))
    (aa--assert-command 'lsp-ui-doc-glance)))

(ert-deftest bindings:leader-lsp-ivy-exist-when-available ()
  (when (fboundp 'lsp-ivy-workspace-symbol)
    (should (eq (aa--lookup-leader "l s") #'lsp-ivy-workspace-symbol))
    (aa--assert-command 'lsp-ivy-workspace-symbol)))

(ert-deftest bindings:leader-lsp-treemacs-exist-when-available ()
  (when (fboundp 'lsp-treemacs-errors-list)
    (should (eq (aa--lookup-leader "l l") #'lsp-treemacs-errors-list))
    (aa--assert-command 'lsp-treemacs-errors-list)))

;; ---------------------------
;; Python localleader keys
;; ---------------------------
(ert-deftest bindings:python-localleader-keys-exist ()
  (when (featurep 'python)
    (with-temp-buffer
      (python-mode)

      (when (modulep! :tools lsp)
        (should (eq (aa--lookup-localleader-in (current-local-map) "g d") #'lsp-find-definition))
        (should (eq (aa--lookup-localleader-in (current-local-map) "g r") #'lsp-find-references))
        (should (eq (aa--lookup-localleader-in (current-local-map) "g i") #'lsp-find-implementation)))

      (when (modulep! :tools lsp)
        (should (eq (aa--lookup-localleader-in (current-local-map) "f b") #'lsp-format-buffer))
        (should (eq (aa--lookup-localleader-in (current-local-map) "f r") #'lsp-format-region)))
      (when (fboundp 'python-black-buffer)
        (should (eq (aa--lookup-localleader-in (current-local-map) "f B") #'python-black-buffer))
        (aa--assert-command 'python-black-buffer))
      (when (fboundp 'python-isort-buffer)
        (should (eq (aa--lookup-localleader-in (current-local-map) "f i") #'python-isort-buffer))
        (aa--assert-command 'python-isort-buffer))

      (when (fboundp 'python-pytest)
        (should (eq (aa--lookup-localleader-in (current-local-map) "t t") #'python-pytest))
        (should (eq (aa--lookup-localleader-in (current-local-map) "t f") #'python-pytest-file))
        (should (eq (aa--lookup-localleader-in (current-local-map) "t d") #'python-pytest-function))
        (aa--assert-command 'python-pytest)
        (aa--assert-command 'python-pytest-file)
        (aa--assert-command 'python-pytest-function))

      (when (fboundp 'lsp-describe-thing-at-point)
        (should (eq (aa--lookup-localleader-in (current-local-map) "h h") #'lsp-describe-thing-at-point))
        (aa--assert-command 'lsp-describe-thing-at-point)))))

;; ---------------------------
;; Clojure localleader keys
;; ---------------------------
(ert-deftest bindings:clojure-localleader-keys-exist ()
  (when (require 'clojure-mode nil 'noerror)
    (with-temp-buffer
      (clojure-mode)
      (when (fboundp 'cider-jack-in-clj)
        (should (eq (aa--lookup-localleader-in (current-local-map) "s") #'cider-jack-in-clj))
        (aa--assert-command 'cider-jack-in-clj)))))


