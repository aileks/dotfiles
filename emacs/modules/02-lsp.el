;;; -*- lexical-binding: t -*-

;; Eglot (built-in to Emacs 29+)
(use-package eglot
  :ensure nil
  :config
  (setq eglot-connect-timeout 30
        eglot-autoshutdown nil
        eglot-ignored-server-capabilities nil)
  :bind
  ("C-c r" . eglot-rename)
  ("C-c f" . eglot-format)
  ("C-c a" . eglot-code-actions)
  ("C-c o" . eglot-code-action-organize-imports)
  ("C-c h" . eglot-show-call-hierarchy)
  ("C-c t" . eglot-show-type-hierarchy)
  ("C-c d" . eldoc-doc-buffer)
  ("C-c C-d" . flymake-show-project-diagnostics))

;; Language servers
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(c-mode . ("clangd"))
               '(c++-mode . ("clangd"))
               '(c-ts-base-mode . ("clangd"))
               '(typescript-base-mode . ("typescript-language-server" "--stdio"))
               '(js-mode . ("typescript-language-server" "--stdio"))
               '(zig-mode . ("zls"))
               '(web-mode . ("vscode-html-language-server" "--stdio"))
               '(css-mode . ("vscode-css-language-server" "--stdio"))))

;; Auto-start Eglot for programming modes
(dolist (hook '(c-mode-hook c++-mode-hook typescript-mode-hook js-mode-hook
                  zig-mode-hook web-mode-hook css-mode-hook))
  (add-hook hook #'eglot-ensure))
