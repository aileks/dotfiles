;;; -*- lexical-binding: t -*-

;; which-key: shows available bindings after delay
(use-package which-key
  :ensure t
  :defer 5
  :config (which-key-mode))

;; undo-fu: better undo/redo
(use-package undo-fu
  :ensure t
  :bind (("C-/" . undo-fu-only-undo)
         ("C-?" . undo-fu-only-redo)))

;; yasnippet: code snippets
(use-package yasnippet
  :ensure t
  :config (yas-global-mode 1))

;; Comment line
(global-set-key (kbd "C-;") 'comment-line)
