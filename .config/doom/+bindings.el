;; -*- lexical-binding: t; -*-

;; ---------------------------
;; Window
;; ---------------------------

;; Removing the default bindings for "<leader> w"
(after! evil
  (evil-define-key* 'normal 'global (kbd "SPC w") nil)
  (define-key doom-leader-map "w" nil))

;; Now define our new window management bindings
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

;; Supporting configuration
(setq evil-vsplit-window-right t
      evil-split-window-below t
      window-combination-resize t)

;; ---------------------------
;; Clojure
;; ---------------------------

(map! :after clojure-mode
      :map clojure-mode-map
      :localleader
      "'" nil ;; This is a remap to avoid the smart keys in some systems
      :desc "Cider jack in CLJ"
      "s" #'cider-jack-in-clj)

(after! paredit
  (map! :map paredit-mode-map
        "C-c l" #'paredit-forward
        "C-c h" #'paredit-backward
        "C-c s l" #'paredit-forward-slurp-sexp
        "C-c s h" #'paredit-backward-slurp-sexp
        "C-c b l" #'paredit-forward-barf-sexp
        "C-c b h" #'paredit-backward-barf-sexp))
