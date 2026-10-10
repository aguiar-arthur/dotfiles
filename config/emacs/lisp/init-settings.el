;;; -*- lexical-binding: t -*-

(defgroup aa nil
  "Settings of this configuration; override them in local.el."
  :group 'convenience)

(defcustom aa/theme 'dracula
  "Theme loaded at startup."
  :type 'symbol)

(defcustom aa/font-family "JetBrainsMono Nerd Font Mono"
  "Monospaced font family used when it is installed."
  :type 'string)

(defcustom aa/variable-font-family "JetBrainsMono Nerd Font"
  "Proportional font family used when it is installed."
  :type 'string)

(defcustom aa/font-height 130
  "Default font height in 1/10 pt."
  :type 'integer)

(defcustom aa/wrap t
  "Non-nil wraps long lines on screen in code, text and config buffers."
  :type 'boolean)

(defcustom aa/autoformat t
  "Non-nil formats buffers on save."
  :type 'boolean)

(defcustom aa/languages '(clojure)
  "Optional language support to load; the rest of the configuration is always loaded."
  :type '(set (const clojure)))

(defcustom aa/doctor-executables
  '(("git" . required) ("rg" . required) ("fd" . required) ("aspell" . optional)
    ("pandoc" . optional) ("prettier" . optional) ("shfmt" . optional) ("stylua" . optional)
    ("clojure-lsp" . clojure) ("clojure" . clojure) ("lein" . clojure) ("clj-kondo" . clojure))
  "Programs `aa/doctor' looks for, with `required', `optional' or the language that needs them."
  :type '(alist :key-type string :value-type symbol))

(defcustom aa/package-backups 3
  "How many backups of the package directory `aa/update-packages' keeps."
  :type 'integer)

(provide 'init-settings)
