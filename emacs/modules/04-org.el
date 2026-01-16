;;; -*- lexical-binding: t -*-

;; Org-mode
(use-package org
  :ensure nil
  :config
  (setq org-directory "~/org/")
  (setq org-default-notes-file (concat org-directory "inbox.org"))
  (add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode)))

;; Org global keybindings
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)
(global-set-key (kbd "C-c l") 'org-store-link)

;; Org tempo (templates)
(require 'org-tempo)
