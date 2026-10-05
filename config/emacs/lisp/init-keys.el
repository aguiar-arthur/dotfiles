;;; init-keys.el --- Keymaps: same scheme as Neovim (SPC leader, `,' local leader) -*- lexical-binding: t -*-

;; Same prefixes as config/nvim/lua/config/keymaps.lua:
;;   SPC b buffer   c code   d diagnostics   D debug (CIDER)   f file/find
;;   SPC g git      l lsp    m marks (harpoon) o open          S session
;;   SPC t terminal u ui toggles   w window
;;   C-h/j/k/l windows · s / S jump (flash) · TAB / S-TAB buffers · M-j / M-k move lines
;;   gd gr gi K  go-to / hover · ]d [d ]e [e diagnostics · ]c [c git hunks
;;   gsa gsd gsr surround · gc comment · ,  mode-specific keys (Org, Clojure)
;; Extra letters the Neovim setup does not use:
;;   SPC a agenda · SPC i capture (inbox) · SPC n notes (org-roam) · SPC h help · SPC . embark
;; In insert/emacs states use C-SPC instead of SPC.
;; SPC ? shows the top-level keymap; just press SPC and wait for which-key.

(defun aa/toggle-relative-numbers ()
  "Toggle relative/absolute line numbers in this buffer."
  (interactive)
  (setq-local display-line-numbers-type
              (if (eq display-line-numbers-type 'relative) t 'relative))
  (display-line-numbers-mode -1)
  (display-line-numbers-mode 1))

;; ------------------------------------------------------------------
;; Helpers
;; ------------------------------------------------------------------
(defun aa/tab-lisp ()
  "On a bracket jump to its match; anywhere else switch to the next buffer."
  (interactive)
  (if (memq (char-after) '(?\( ?\) ?\[ ?\] ?\{ ?\}))
      (evil-jump-item)
    (next-buffer)))

;; ------------------------------------------------------------------
;; Bindings
;; ------------------------------------------------------------------
(use-package general
  :demand t
  :after evil
  :config
  (general-create-definer my-leader-def
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")

  ;; --- No prefix --------------------------------------------------
  ;; Windows, clear search highlight (override: work in every buffer)
  (general-define-key
   :states '(normal motion)
   :keymaps 'override
   "C-h" 'evil-window-left
   "C-j" 'evil-window-down
   "C-k" 'evil-window-up
   "C-l" 'evil-window-right
   "C-\\" 'aa/term-toggle)

  (general-define-key
   :states 'normal
   "<escape>" 'evil-ex-nohighlight
   "TAB" 'next-buffer
   "<backtab>" 'previous-buffer
   ;; LSP go-to / hover
   "gd" 'xref-find-definitions
   "gr" 'xref-find-references
   "gi" 'eglot-find-implementation
   "K" 'eldoc-doc-buffer
   ;; Diagnostics and git hunks
   "]d" 'flymake-goto-next-error
   "[d" 'flymake-goto-prev-error
   "]e" 'aa/next-error-diag
   "[e" 'aa/prev-error-diag
   "]c" 'diff-hl-next-hunk
   "[c" 'diff-hl-previous-hunk
   "]t" 'hl-todo-next
   "[t" 'hl-todo-previous
   ;; Surround (mini.surround style)
   "gsa" 'evil-surround-edit
   "gsd" 'evil-surround-delete
   "gsr" 'evil-surround-change)

  (general-define-key
   :states 'visual
   "gsa" 'evil-surround-region)

  ;; Flash-like jumps (note: replaces evil's `s' / `S', as flash.nvim does)
  (general-define-key
   :states '(normal motion)
   "s" 'avy-goto-char-timer
   "S" 'avy-goto-line)

  ;; Move lines / selections
  (general-define-key
   :states '(normal visual)
   "M-j" 'move-text-down
   "M-k" 'move-text-up)

  ;; --- SPC leader -------------------------------------------------
  (my-leader-def
    "s" '(save-buffer :wk "save")
    "q" '(evil-quit :wk "quit window")
    "Q" '(save-buffers-kill-terminal :wk "quit Emacs")
    "?" '(which-key-show-top-level :wk "show keymaps")
    "." '(embark-act :wk "actions (embark)")

    ;; Buffer ---------------------------------------------------------
    "b" '(:ignore t :wk "buffer")
    "b n" '(next-buffer :wk "next buffer")
    "b p" '(previous-buffer :wk "previous buffer")
    "b d" '(kill-current-buffer :wk "close buffer")
    "b k" '(kill-current-buffer :wk "kill buffer")
    "b b" '(consult-buffer :wk "list buffers")

    ;; Code -----------------------------------------------------------
    "c" '(:ignore t :wk "code")
    "c c" '(evil-commentary-line :wk "comment line")
    "c d" '(eldoc-doc-buffer :wk "diagnostics at point (eldoc)")

    ;; Diagnostics ----------------------------------------------------
    "d" '(:ignore t :wk "diagnostics")
    "d x" '(flymake-show-project-diagnostics :wk "diagnostics (project)")
    "d d" '(flymake-show-buffer-diagnostics :wk "document diagnostics")
    "d s" '(consult-imenu :wk "symbols")
    "d l" '(flymake-show-buffer-diagnostics :wk "location list")
    "d q" '(consult-compile-error :wk "quickfix (compile errors)")
    "d t" '(hl-todo-occur :wk "todos (buffer)")
    "d T" '(hl-todo-rgrep :wk "todos (project)")

    ;; Debug: CIDER (Clojure) ----------------------------------------
    "D" '(:ignore t :wk "debug (CIDER)")
    "D d" '(cider-debug-defun-at-point :wk "debug defun")
    "D t" '(cider-toggle-trace-var :wk "trace var")
    "D T" '(cider-toggle-trace-ns :wk "trace namespace")
    "D r" '(cider-switch-to-repl-buffer :wk "REPL")
    "D i" '(cider-inspect-last-result :wk "inspect last result")
    "D e" '(cider-read-and-eval :wk "eval expression")

    ;; File / find ----------------------------------------------------
    "f" '(:ignore t :wk "file/find")
    "f f" '(aa/find-file-smart :wk "find files (project)")
    "f F" '(find-file :wk "find any file")
    "f g" '(aa/grep-project :wk "live grep")
    "f w" '(aa/grep-word :wk "grep word / selection")
    "f r" '(consult-recent-file :wk "recent files")
    "f b" '(consult-buffer :wk "buffers")
    "f c" '(aa/find-config :wk "Emacs config files")
    "f h" '(describe-symbol :wk "help: symbol")
    "f k" '(describe-bindings :wk "keymaps")
    "f d" '(consult-flymake :wk "diagnostics")
    "f s" '(consult-imenu :wk "symbols")
    "f S" '(xref-find-apropos :wk "workspace symbols")
    "f u" '(vundo :wk "undo history")
    "f C" '(consult-theme :wk "colorschemes")
    "f R" '(vertico-repeat :wk "resume last picker")
    "f /" '(consult-line :wk "search in buffer")
    "f p" '(project-switch-project :wk "projects")

    ;; Git ------------------------------------------------------------
    "g" '(:ignore t :wk "git")
    "g g" '(magit-status :wk "magit")
    "g t" '(magit-status :wk "git status")
    "g l" '(magit-log-current :wk "git log")
    "g f" '(magit-log-buffer-file :wk "git log (file)")
    "g s" '(diff-hl-stage-current-hunk :wk "stage hunk")
    "g r" '(diff-hl-revert-hunk :wk "reset hunk")
    "g S" '(magit-stage-buffer-file :wk "stage buffer")
    "g R" '(vc-revert :wk "reset buffer")
    "g p" '(diff-hl-show-hunk :wk "preview hunk")
    "g b" '(magit-blame-addition :wk "blame")
    "g B" '(aa/blame-toggle :wk "toggle blame")
    "g d" '(magit-diff-buffer-file :wk "diff this")
    "g v" '(magit-diff-dwim :wk "diff view")
    "g V" '(magit-diff-range :wk "diff view: range / branch")
    "g h" '(magit-log-buffer-file :wk "file history")
    "g H" '(magit-log-all :wk "repo history")
    "g O" '(browse-at-remote :wk "open in browser")

    ;; LSP ------------------------------------------------------------
    "l" '(:ignore t :wk "lsp")
    "l d" '(xref-find-definitions :wk "definition")
    "l r" '(xref-find-references :wk "references")
    "l i" '(eglot-find-implementation :wk "implementation")
    "l t" '(eglot-find-typeDefinition :wk "type definition")
    "l D" '(eglot-find-declaration :wk "declaration")
    "l n" '(eglot-rename :wk "rename symbol")
    "l a" '(eglot-code-actions :wk "code action")
    "l h" '(eldoc-doc-buffer :wk "hover documentation")
    "l s" '(eldoc-doc-buffer :wk "signature help")
    "l l" '(flymake-show-buffer-diagnostics :wk "buffer diagnostics")
    "l R" '(eglot-reconnect :wk "restart LSP")
    "l f" '(aa/format-buffer :wk "format buffer/selection")
    "l M" '(list-packages :wk "packages")

    ;; Marks (harpoon) ------------------------------------------------
    "m" '(:ignore t :wk "marks (harpoon)")
    "m a" '(aa/harpoon-add :wk "add file")
    "m d" '(aa/harpoon-remove :wk "remove file")
    "m m" '(aa/harpoon-menu :wk "harpoon menu")
    "m n" '(aa/harpoon-next :wk "harpoon next")
    "m p" '(aa/harpoon-prev :wk "harpoon previous")
    "m 1" '(aa/harpoon-goto-1 :wk "harpoon file 1")
    "m 2" '(aa/harpoon-goto-2 :wk "harpoon file 2")
    "m 3" '(aa/harpoon-goto-3 :wk "harpoon file 3")
    "m 4" '(aa/harpoon-goto-4 :wk "harpoon file 4")
    "m 5" '(aa/harpoon-goto-5 :wk "harpoon file 5")

    ;; Open / toggle --------------------------------------------------
    "o" '(:ignore t :wk "open/toggle")
    "o p" '(treemacs :wk "toggle file tree")
    "o f" '(treemacs-find-file :wk "find file in tree")
    "o n" '(view-echo-area-messages :wk "message history")
    "o d" '(dashboard-open :wk "dashboard")

    ;; Session --------------------------------------------------------
    "S" '(:ignore t :wk "session")
    "S r" '(aa/session-restore :wk "restore session")
    "S l" '(aa/session-restore :wk "restore last session")
    "S s" '(aa/session-save :wk "save session")
    "S d" '(aa/session-delete :wk "delete saved session")

    ;; Terminal -------------------------------------------------------
    "t" '(:ignore t :wk "terminal")
    "t f" '(aa/term-full :wk "terminal (this window)")
    "t h" '(aa/term-below :wk "horizontal terminal")
    "t v" '(aa/term-right :wk "vertical terminal")
    "t g" '(magit-status :wk "magit")

    ;; UI toggles -----------------------------------------------------
    "u" '(:ignore t :wk "ui toggles")
    "u s" '(flyspell-mode :wk "spelling")
    "u w" '(visual-line-mode :wk "wrap")
    "u L" '(aa/toggle-relative-numbers :wk "relative number")
    "u c" '(aa/toggle-emphasis-markers :wk "conceal (Org markers)")
    "u d" '(flymake-mode :wk "diagnostics")
    "u h" '(aa/toggle-inlay-hints :wk "inlay hints")
    "u f" '(aa/toggle-autoformat :wk "auto-format")
    "u g" '(indent-bars-mode :wk "indent guides")

    ;; Window ---------------------------------------------------------
    "w" '(:ignore t :wk "window")
    "w h" '(evil-window-left :wk "window left")
    "w j" '(evil-window-down :wk "window below")
    "w k" '(evil-window-up :wk "window above")
    "w l" '(evil-window-right :wk "window right")
    "w w" '(evil-window-next :wk "next window")
    "w v" '(evil-window-vsplit :wk "split vertically")
    "w s" '(evil-window-split :wk "split horizontally")
    "w o" '(delete-other-windows :wk "close other windows")
    "w c" '(evil-window-delete :wk "close window")
    "w q" '(evil-quit :wk "quit window")
    "w =" '(balance-windows :wk "balance windows")
    "w H" '(aa/window-decrease-width :wk "narrower")
    "w L" '(aa/window-increase-width :wk "wider")
    "w J" '(aa/window-decrease-height :wk "shorter")
    "w K" '(aa/window-increase-height :wk "taller")

    ;; Org (letters the Neovim setup does not use) --------------------
    "a" '(:ignore t :wk "agenda/org")
    "a a" '(org-agenda :wk "agenda menu")
    "a d" '(aa/agenda-day :wk "day")
    "a w" '(aa/agenda-week :wk "week")
    "a n" '(aa/agenda-next :wk "next actions")
    "a W" '(aa/agenda-wait :wk "waiting")
    "a i" '(aa/agenda-inbox :wk "inbox")
    "a p" '(aa/agenda-projects :wk "projects")
    "a s" '(aa/agenda-stuck :wk "stuck projects")
    "a r" '(aa/agenda-review :wk "weekly review")
    "a f" '(aa/org-find-file :wk "open Org file")
    "a /" '(aa/search-org :wk "grep in ~/org")

    "n" '(:ignore t :wk "notes (org-roam)")
    "n f" '(org-roam-node-find :wk "find / create note")
    "n i" '(org-roam-node-insert :wk "insert link to note")
    "n c" '(org-roam-capture :wk "capture note")
    "n b" '(org-roam-buffer-toggle :wk "backlinks")
    "n t" '(org-roam-dailies-goto-today :wk "today's daily note")
    "n d" '(org-roam-dailies-capture-today :wk "capture in daily note")
    "n j" '(org-roam-dailies-goto-date :wk "daily note for a date")
    "n a" '(org-id-get-create :wk "make heading a node")

    "i" '(:ignore t :wk "capture")
    "i c" '(org-capture :wk "capture menu")
    "i t" '(aa/capture-task :wk "task")
    "i e" '(aa/capture-event :wk "event")
    "i n" '(aa/capture-note :wk "note")
    "i i" '(aa/capture-idea :wk "idea")
    "i m" '(aa/capture-meeting :wk "meeting")
    "i j" '(aa/capture-journal :wk "journal")

    "h" '(:ignore t :wk "help")
    "h f" '(describe-function :wk "function")
    "h v" '(describe-variable :wk "variable")
    "h k" '(describe-key :wk "key")
    "h m" '(describe-mode :wk "mode")
    "h b" '(describe-bindings :wk "bindings")
    "h p" '(describe-package :wk "package")
    "h i" '(info :wk "manuals (Info)"))

  ;; Visual-mode variants of the comment keys
  (general-define-key
   :states 'visual
   :keymaps 'override
   :prefix "SPC"
   "c c" '(evil-commentary :wk "comment selection"))

  ;; TAB on a bracket jumps to its match in Lisp buffers (`%' still works too)
  (general-define-key
   :states 'normal
   :keymaps '(clojure-mode-map clojurec-mode-map clojurescript-mode-map
              emacs-lisp-mode-map lisp-data-mode-map)
   "TAB" 'aa/tab-lisp
   "<tab>" 'aa/tab-lisp)

  ;; --- `,' local leader: Org -------------------------------------------
  (with-eval-after-load 'org
    ;; TAB cycles headings in Org (it switches buffers everywhere else)
    (general-define-key
     :states 'normal
     :keymaps 'org-mode-map
     "TAB" 'org-cycle
     "<tab>" 'org-cycle
     "<backtab>" 'org-shifttab)
    (general-define-key
     :states '(normal visual)
     :keymaps 'org-mode-map
     :prefix ","
     "t" '(org-todo :wk "TODO state")
     "s" '(org-schedule :wk "schedule")
     "d" '(org-deadline :wk "deadline")
     "p" '(org-priority :wk "priority")
     "T" '(org-set-tags-command :wk "tags")
     "r" '(org-refile :wk "refile")
     "a" '(org-archive-subtree :wk "archive")
     "i" '(org-clock-in :wk "clock in")
     "o" '(org-clock-out :wk "clock out")
     "l" '(org-insert-link :wk "insert link")
     "L" '(org-store-link :wk "store link")
     "x" '(org-toggle-checkbox :wk "toggle checkbox")
     "n" '(org-narrow-to-subtree :wk "narrow")
     "N" '(widen :wk "widen")
     "e" '(org-export-dispatch :wk "export")
     "v" '(org-latex-preview :wk "preview LaTeX")
     "b" '(org-babel-execute-src-block :wk "run code block")
     "B" '(org-babel-tangle :wk "tangle")
     "'" '(org-edit-special :wk "edit block")))

  ;; --- `,' local leader: Clojure (CIDER) -------------------------------
  (with-eval-after-load 'clojure-mode
    (general-define-key
     :states '(normal visual)
     :keymaps '(clojure-mode-map clojurec-mode-map clojurescript-mode-map)
     :prefix ","
     ;; connection
     "j" '(cider-jack-in :wk "jack-in (clj)")
     "J" '(cider-jack-in-cljs :wk "jack-in (cljs)")
     "c" '(cider-connect :wk "connect")
     "q" '(cider-quit :wk "quit REPL")
     "R" '(cider-ns-refresh :wk "refresh namespaces")
     ;; eval
     "e" '(:ignore t :wk "eval")
     "e e" '(cider-eval-last-sexp :wk "last sexp")
     "e f" '(cider-eval-defun-at-point :wk "defun")
     "e b" '(cider-eval-buffer :wk "buffer")
     "e r" '(cider-eval-region :wk "region")
     "e n" '(cider-eval-ns-form :wk "ns form")
     "e p" '(cider-pprint-eval-last-sexp :wk "last sexp (pprint)")
     "l" '(cider-load-buffer :wk "load buffer")
     "L" '(cider-load-all-project-ns :wk "load all project ns")
     ;; REPL
     "s" '(:ignore t :wk "repl")
     "s s" '(cider-switch-to-repl-buffer :wk "switch to REPL")
     "s n" '(cider-repl-set-ns :wk "set REPL ns")
     ;; tests
     "t" '(:ignore t :wk "test")
     "t t" '(cider-test-run-test :wk "test at point")
     "t n" '(cider-test-run-ns-tests :wk "namespace tests")
     "t p" '(cider-test-run-project-tests :wk "project tests")
     "t l" '(cider-test-run-loaded-tests :wk "loaded tests")
     "t r" '(cider-test-rerun-failed-tests :wk "rerun failed")
     "t s" '(cider-test-show-report :wk "report")
     ;; docs
     "d" '(:ignore t :wk "docs")
     "d d" '(cider-doc :wk "doc")
     "d c" '(cider-clojuredocs :wk "clojuredocs")
     "d j" '(cider-javadoc :wk "javadoc")
     "d a" '(cider-apropos :wk "apropos")
     ;; misc
     "m" '(cider-macroexpand-1 :wk "macroexpand-1")
     "i" '(cider-inspect :wk "inspect")
     ;; structural editing (smartparens)
     ">" '(sp-forward-slurp-sexp :wk "slurp forward")
     "<" '(sp-forward-barf-sexp :wk "barf forward")
     "(" '(sp-backward-slurp-sexp :wk "slurp backward")
     ")" '(sp-backward-barf-sexp :wk "barf backward")
     "w" '(sp-wrap-round :wk "wrap in ( )")
     "u" '(sp-unwrap-sexp :wk "unwrap")
     "^" '(sp-raise-sexp :wk "raise sexp"))))

(provide 'init-keys)
;;; init-keys.el ends here
