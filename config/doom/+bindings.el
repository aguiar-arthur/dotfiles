;; -*- lexical-binding: t; -*-
 
(after! doom-keybinds

      (define-key doom-leader-map (kbd "l") nil)
      (define-key doom-leader-map (kbd "c") nil)
      (define-key doom-leader-map (kbd "w") nil)
      (define-key doom-leader-map (kbd "m") nil)

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
            :desc "Indent buffer" "I" #'aa/indent-buffer

            :desc "Jump to definition" "j" #'xref-find-definitions))

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

                  :desc "Switch to another frame"       "f" #'other-frame))

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

;; ---------------------------
;; Python
;; ---------------------------
(map! :after python
      :map python-mode-map
      :localleader

      :desc "Python REPL" "'" #'run-python
      :desc "Send buffer to REPL" "b" #'python-shell-send-buffer
      :desc "Send region to REPL" "r" #'python-shell-send-region
      :desc "Send defun to REPL" "d" #'python-shell-send-defun
      :desc "Send statement to REPL" "s" #'python-shell-send-statement

      (:prefix ("t" . "test")
       :desc "Run pytest" "t" #'python-pytest
       :desc "Run pytest current file" "f" #'python-pytest-file
       :desc "Run pytest current function" "d" #'python-pytest-function)

      (:prefix ("g" . "goto")
       :desc "Go to definition" "d" #'lsp-find-definition
       :desc "Go to references" "r" #'lsp-find-references
       :desc "Go to implementation" "i" #'lsp-find-implementation)

      (:prefix ("f" . "format")
       :desc "Format buffer" "b" #'lsp-format-buffer
       :desc "Format region" "r" #'lsp-format-region
       :desc "Black format buffer" "B" #'python-black-buffer
       :desc "Isort buffer" "i" #'python-isort-buffer)

      (:prefix ("h" . "help")
       :desc "Describe at point" "h" #'lsp-describe-thing-at-point
       :desc "Python help" "p" #'python-eldoc-at-point))
