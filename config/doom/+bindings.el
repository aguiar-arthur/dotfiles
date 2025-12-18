;; -*- lexical-binding: t; -*-

(after! doom-keybinds

  (define-key doom-leader-map (kbd "l") nil)
  (define-key doom-leader-map (kbd "c") nil)
  (define-key doom-leader-map (kbd "w") nil)

  (map! :leader
        :when (modulep! :tools lsp)
        (:prefix ("l" . "lsp")
         :desc "Find definition"        "d" #'lsp-find-definition
         :desc "Find references"        "r" #'lsp-find-references
         :desc "Find implementations"   "i" #'lsp-find-implementation
         :desc "Find type definition"   "t" #'lsp-goto-type-definition
         :desc "Rename symbol"          "n" #'lsp-rename
         :desc "Format buffer"          "f" #'lsp-format-buffer
         :desc "Organize imports"       "o" #'lsp-organize-imports
         :desc "Execute code action"    "a" #'lsp-execute-code-action
         :desc "Restart LSP"            "R" #'lsp-restart-workspace
         :desc "Describe thing"         "D" #'lsp-describe-thing-at-point
         (:when (fboundp 'rename-visited-file)
           :desc "Rename file in associated buffer" "N" #'rename-visited-file)))

  (map! :leader
        (:prefix ("c" . "code")
         :desc "Comment line" "c" #'comment-line
         :desc "Comment region" "C" #'comment-region
         :desc "Toggle comment" "t" #'comment-dwim

         (:when (and (modulep! :tools lsp) (fboundp 'lsp-extract-function))
           :desc "Extract function" "f" #'lsp-extract-function)
         (:when (and (modulep! :tools lsp) (fboundp 'lsp-extract-variable))
           :desc "Extract variable" "v" #'lsp-extract-variable)

         (:when (and (modulep! :tools lsp) (fboundp 'lsp-refactor))
           :desc "Refactor" "r" #'lsp-refactor)

         :desc "Evaluate buffer" "b" #'eval-buffer
         :desc "Evaluate region" "i" #'eval-region
         (:when (fboundp 'aa/indent-buffer) :desc "Indent buffer" "I" #'aa/indent-buffer)

         :desc "Jump to definition" "j" #'xref-find-definitions))

  (map! :leader
        :prefix "w"
        :desc "Window commands"

        :desc "Move to left window"           "h" #'evil-window-left
        :desc "Move to window below"          "j" #'evil-window-down
        :desc "Move to window above"          "k" #'evil-window-up
        :desc "Move to right window"          "l" #'evil-window-right
        :desc "Jump to window (interactive)"  "w" #'ace-window

        :desc "Split window vertically"        "v" #'evil-window-vsplit
        :desc "Split window horizontally"      "s" #'evil-window-split
        :desc "Close other windows (maximize)" "o" #'delete-other-windows

        (:when (fboundp 'aa/window-decrease-width)
          :desc "Narrow window (width)"        "H" #'aa/window-decrease-width)
        (:when (fboundp 'aa/window-decrease-height)
          :desc "Shrink window (height)"       "J" #'aa/window-decrease-height)
        (:when (fboundp 'aa/window-increase-height)
          :desc "Enlarge window (height)"      "K" #'aa/window-increase-height)
        (:when (fboundp 'aa/window-increase-width)
          :desc "Widen window (width)"         "L" #'aa/window-increase-width)
        :desc "Balance window sizes"           "=" #'balance-windows

        :desc "Close current window"           "c" #'evil-window-delete
        :desc "Kill current buffer"            "q" #'kill-current-buffer

        :desc "Switch to another frame"        "f" #'other-frame))

(setq evil-vsplit-window-right t
      evil-split-window-below t
      window-combination-resize t)

;; ---------------------------
;; LSP (optional integrations)
;; ---------------------------
(after! lsp-ui
  (map! :leader
        (:prefix ("l" . "lsp")
                 (:when (fboundp 'lsp-ui-doc-glance)
                   :desc "Show documentation" "h" #'lsp-ui-doc-glance))))

(after! lsp-ivy
  (map! :leader
        (:prefix ("l" . "lsp")
                 (:when (fboundp 'lsp-ivy-workspace-symbol)
                   :desc "Workspace symbols" "s" #'lsp-ivy-workspace-symbol))))

(after! lsp-treemacs
  (map! :leader
        (:prefix ("l" . "lsp")
                 (:when (fboundp 'lsp-treemacs-errors-list)
                   :desc "List diagnostics" "l" #'lsp-treemacs-errors-list))))

;; ---------------------------
;; Clojure
;; ---------------------------
(map! :after clojure-mode
      :map clojure-mode-map
      :localleader
      "'" nil
      (:when (fboundp 'cider-jack-in-clj)
        :desc "Cider jack in CLJ" "s" #'cider-jack-in-clj))

(after! paredit
  (map! :map paredit-mode-map
        :desc "Move forward over S-expression"           "C-c l"   #'paredit-forward
        :desc "Move backward over S-expression"          "C-c h"   #'paredit-backward

        :desc "Slurp forward (include next expression)"  "C-c s l" #'paredit-forward-slurp-sexp
        :desc "Slurp backward (include previous expr)"   "C-c s h" #'paredit-backward-slurp-sexp

        :desc "Barf forward (exclude last expression)"   "C-c b l" #'paredit-forward-barf-sexp
        :desc "Barf backward (exclude first expression)" "C-c b h" #'paredit-backward-barf-sexp))
