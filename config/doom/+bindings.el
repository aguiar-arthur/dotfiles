;; -*- lexical-binding: t; -*-

(use-package general
  :after evil
  :config
  (general-auto-unbind-keys)

 (map! :leader
       :desc "w" nil
       :desc "l" nil
       :desc "c" nil
       :desc "m" nil
       :desc "o" nil))

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

      :desc "Move to left window"          "h" #'evil-window-left
      :desc "Move to window below"          "j" #'evil-window-down
      :desc "Move to window above"          "k" #'evil-window-up
      :desc "Move to right window"          "l" #'evil-window-right
      :desc "Jump to window (interactive)"  "w" #'ace-window

      :desc "Split window vertically"      "v" #'evil-window-vsplit
      :desc "Split window horizontally"     "s" #'evil-window-split
      :desc "Close other windows (maximize)" "o" #'delete-other-windows

      :desc "Narrow window (width)"         "H" #'evil-window-decrease-width
      :desc "Shrink window (height)"        "J" #'evil-window-decrease-height
      :desc "Enlarge window (height)"       "K" #'evil-window-increase-height
      :desc "Widen window (width)"          "L" #'evil-window-increase-width
      :desc "Balance window sizes"          "=" #'balance-windows

      :desc "Close current window"          "c" #'evil-window-delete
      :desc "Kill current buffer"           "q" #'kill-current-buffer

      :desc "Switch to another frame"       "f" #'other-frame)

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