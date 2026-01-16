;;; -*- lexical-binding: t -*-

;; Project management (built-in)
(project-mode 1)
(setq project-mode-line t)

;; Dired + extensions
(require 'dired-x)
(setq dired-listing-switches "-lh")
(setq dired-omit-files "^\\.?#\\|^\\..*$")
(setq dired-omit-mode t)
(add-hook 'dired-mode-hook #'dired-hide-details-mode)
