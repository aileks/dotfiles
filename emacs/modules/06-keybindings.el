;;; -*- lexical-binding: t -*-

;; which-key: shows available bindings after delay
(use-package which-key
  :defer 5
  :custom (which-key-idle-delay 0.8)
  :config (which-key-mode))

(use-package mood-line
  :config (mood-line-mode))

;; undo-fu: better undo/redo
(use-package undo-fu
  :bind (("C-/" . undo-fu-only-undo)
         ("C-?" . undo-fu-only-redo)))

;; yasnippet: code snippets
(use-package yasnippet
  :config (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package ws-butler
  :hook (prog-mode . ws-butler-mode))

(use-package dape
  :bind ("C-c d" . dape))

;; Comment line
(global-set-key (kbd "C-;") 'comment-line)

;; Terminal
(use-package eat
  :bind ("C-c t" . eat))

;; Search prefix
(global-set-key (kbd "C-c s l") #'consult-line)
(global-set-key (kbd "C-c s r") #'consult-ripgrep)
(global-set-key (kbd "C-c s f") #'consult-find)
(global-set-key (kbd "C-c s m") #'consult-imenu)

;; Project search
(global-set-key (kbd "C-c p f") #'consult-project-extra-find)
(global-set-key (kbd "C-c p r") #'consult-project-extra-ripgrep)

;; Git extras
(global-set-key (kbd "C-c g t") #'magit-todos-list)
(global-set-key (kbd "C-c g b") #'magit-blame-addition)
(global-set-key (kbd "C-c g y") #'browse-at-remote)
