;;; -*- lexical-binding: t -*-

;; Project management (built-in)
(setq project-mode-line t)

(use-package ibuffer-vc
  :hook (ibuffer . ibuffer-vc-set-filter-groups-by-vc-root))

(use-package project
  :ensure nil
  :bind-keymap ("C-x p" . project-prefix-map))

(use-package consult-project-extra
  :after consult)

;; Dired + extensions
(require 'dired-x)
(setq dired-listing-switches "-lh")
(setq dired-omit-files "^\\.?#\\|^\\..*$")
(setq dired-omit-mode t)
(add-hook 'dired-mode-hook #'dired-hide-details-mode)

(global-set-key (kbd "C-x C-b") #'ibuffer)
