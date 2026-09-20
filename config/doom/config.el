;;; config.el -*- lexical-binding: t; -*-

(setq org-directory "~/org")

(setq doom-theme 'cinder-muted
      doom-font (font-spec :family "Iosevka Nerd Font" :size 18))

(after! solaire-mode (solaire-global-mode -1))

(setq display-line-numbers-type 'relative
      scroll-margin 8
      make-backup-files t
      confirm-kill-emacs #'y-or-n-p)

(setq-default truncate-lines nil)

(after! dap-mode
  (require 'dap-java)
  (setq dap-java-test-runner
        (expand-file-name "test-runner/junit-platform-console-standalone.jar"
                          lsp-java-server-install-dir)))

(after! corfu
  (setq corfu-count 10))

(after! evil-escape
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay 0.15))

(after! lsp-ui
  (setq
   lsp-ui-doc-enable t
   lsp-ui-doc-use-childframe t
   lsp-ui-doc-show-with-cursor t
   lsp-ui-doc-position 'at-point
   lsp-ui-doc-delay 0.4
   ;; DO NOT REMOVE
   ;; some hovers are MarkedString lists
   ;; this prevents lsp-ui's from dropping them
   lsp-ui-doc-include-signature t))

(after! lsp-mode
  (add-hook 'lsp-mode-hook #'lsp-ui-mode))

(load! "+bindings")
(load! "+org")
(load! "+sql")
(load! "+dbt")
(load! "+lang-extras")
(load! "+tasks")
