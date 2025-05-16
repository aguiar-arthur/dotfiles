;; -*- lexical-binding: t; -*-

;; This will remove some of the default bindinds from
(after! evil
  (dolist (key '("w" "l" "c"))
    (evil-define-key* 'normal 'global (kbd (concat "SPC " key)) nil)
    (define-key doom-leader-map key nil)))

;; ---------------------------
;; Lsp
;; ---------------------------
(map! :leader
      (:prefix ("l" . "lsp")
       :desc "Find definition" "d" #'lsp-find-definition
       :desc "Find references" "r" #'lsp-find-references
       :desc "Find implementations" "i" #'lsp-find-implementation
       :desc "Find type definition" "t" #'lsp-goto-type-definition
       :desc "Rename symbol" "n" #'lsp-rename
       :desc "Rename file in associated buffer" "N" #'rename-visited-file
       :desc "Format buffer" "f" #'lsp-format-buffer
       :desc "Organize imports" "o" #'lsp-organize-imports
       :desc "Execute code action" "a" #'lsp-execute-code-action
       :desc "Show documentation" "h" #'lsp-ui-doc-glance
       :desc "Workspace symbols" "s" #'lsp-ivy-workspace-symbol
       :desc "Restart LSP" "R" #'lsp-restart-workspace
       :desc "Describe thing" "D" #'lsp-describe-thing-at-point
       :desc "List diagnostics" "l" #'lsp-treemacs-errors-list))

;; ---------------------------
;; Code
;; ---------------------------
(map! :leader
      (:prefix ("c" . "code")
       :desc "Comment line" "c" #'comment-line
       :desc "Comment region" "C" #'comment-region
       :desc "Toggle comment" "t" #'comment-dwim
       :desc "Extract function" "f" #'lsp-extract-function
       :desc "Extract variable" "v" #'lsp-extract-variable
       :desc "Refactor" "r" #'lsp-refactor
       :desc "Evaluate buffer" "b" #'eval-buffer
       :desc "Evaluate region" "i" #'eval-region
       :desc "Indent buffer" "I" #'indent-buffer
       :desc "Jump to definition" "j" #'xref-find-definitions))

;; ---------------------------
;; Window
;; ---------------------------
(map! :leader
      :prefix "w"
      :desc "Window commands"

      ;; Basic navigation
      "h" #'evil-window-left
      "j" #'evil-window-down
      "k" #'evil-window-up
      "l" #'evil-window-right
      "w" #'ace-window  ; quick window selection

      ;; Splitting
      "v" #'evil-window-vsplit
      "s" #'evil-window-split
      "o" #'delete-other-windows

      ;; Resizing
      "H" #'evil-window-decrease-width
      "J" #'evil-window-decrease-height
      "K" #'evil-window-increase-height
      "L" #'evil-window-increase-width
      "=" #'balance-windows

      ;; Operations
      "c" #'evil-window-delete
      "q" #'kill-current-buffer

      ;; Frames
      "f" #'other-frame)

(setq evil-vsplit-window-right t
      evil-split-window-below t
      window-combination-resize t)

;; ---------------------------
;; Clojure
;; ---------------------------
(map! :after clojure-mode
      :map clojure-mode-map
      :localleader
      "'" nil
      :desc "Cider jack in CLJ" "s" #'cider-jack-in-clj)

(after! paredit
  (map! :map paredit-mode-map
        :desc "Move forward over S-expression"           "C-c l"   #'paredit-forward
        :desc "Move backward over S-expression"          "C-c h"   #'paredit-backward
        :desc "Slurp forward (include next expression)"  "C-c s l" #'paredit-forward-slurp-sexp
        :desc "Slurp backward (include previous expr)"   "C-c s h" #'paredit-backward-slurp-sexp
        :desc "Barf forward (exclude last expression)"   "C-c b l" #'paredit-forward-barf-sexp
        :desc "Barf backward (exclude first expression)" "C-c b h" #'paredit-backward-barf-sexp))
