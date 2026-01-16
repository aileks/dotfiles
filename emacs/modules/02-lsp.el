;;; -*- lexical-binding: t -*-

;; Eglot (built-in to Emacs 29+)
(use-package eglot
  :ensure nil
  :hook ((c-mode c++-mode c-ts-mode c++-ts-mode zig-mode
                 python-mode python-ts-mode sh-mode bash-ts-mode
                 typescript-ts-mode tsx-ts-mode js-ts-mode
                 css-mode web-mode) . eglot-ensure)
  :config
  (setq eglot-connect-timeout 30
        eglot-autoshutdown nil
        eglot-ignored-server-capabilities nil)
  :bind
  ("C-c e r" . eglot-rename)
  ("C-c e f" . eglot-format)
  ("C-c e a" . eglot-code-actions)
  ("C-c e o" . eglot-code-action-organize-imports)
  ("C-c e h" . eglot-show-call-hierarchy)
  ("C-c e t" . eglot-show-type-hierarchy)
  ("C-c e d" . eldoc-doc-buffer)
  ("C-c e D" . flymake-show-project-diagnostics))

(use-package eglot-booster
  :after eglot
  :straight (:host github :repo "jdtsmith/eglot-booster")
  :config (eglot-booster-mode))

;; Tree-sitter auto-install
(use-package treesit-auto

  :custom
  (treesit-auto-install t)
  :config
  (global-treesit-auto-mode))

(use-package markdown-mode)

(use-package yaml-mode)

(use-package json-mode)

(use-package toml-mode)

;; Language servers
(with-eval-after-load 'eglot
  (setq eglot-server-programs
        (append eglot-server-programs
                '((c-mode . ("clangd"))
                  (c++-mode . ("clangd"))
                  (c-ts-mode . ("clangd"))
                  (c++-ts-mode . ("clangd"))
                  (python-mode . ("pyright-langserver" "--stdio"))
                  (python-ts-mode . ("pyright-langserver" "--stdio"))
                  (zig-mode . ("zls"))
                  (bash-ts-mode . ("bash-language-server" "start"))
                  (sh-mode . ("bash-language-server" "start"))
                  (typescript-ts-mode . ("typescript-language-server" "--stdio"))
                  (tsx-ts-mode . ("typescript-language-server" "--stdio"))
                  (js-ts-mode . ("typescript-language-server" "--stdio"))
                  (web-mode . ("vscode-html-language-server" "--stdio"))
                  (css-mode . ("vscode-css-language-server" "--stdio"))))))

;; Prefer tree-sitter modes
(setq major-mode-remap-alist
      '((c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (python-mode . python-ts-mode)
        (js-mode . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (sh-mode . bash-ts-mode)))

;; Format on save
(use-package apheleia
  :config
  (setf (alist-get 'prettier apheleia-formatters)
        '("prettier" "--stdin-filepath" filepath))
  (setf (alist-get 'prettier apheleia-mode-alist)
        '(js-mode js-ts-mode jsx-mode tsx-ts-mode typescript-mode typescript-ts-mode))
  (setf (alist-get 'clang-format apheleia-formatters)
        '("clang-format"))
  (setf (alist-get 'clang-format apheleia-mode-alist)
        '(c-mode c-ts-mode c++-mode c++-ts-mode))
  (setf (alist-get 'black apheleia-formatters)
        '("black" "-"))
  (setf (alist-get 'black apheleia-mode-alist)
        '(python-mode python-ts-mode))
  (setf (alist-get 'shfmt apheleia-formatters)
        '("shfmt" "-"))
  (setf (alist-get 'shfmt apheleia-mode-alist)
        '(sh-mode bash-ts-mode))
  (add-hook 'prog-mode-hook #'apheleia-mode))

;; Flymake: Shellcheck integration
(use-package flymake-shellcheck
  :hook ((sh-mode bash-ts-mode) . flymake-shellcheck-load)
  :custom (flymake-shellcheck-checker 'sh-shellcheck))
