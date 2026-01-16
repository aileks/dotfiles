;;; -*- lexical-binding: t -*-

;; Purist: no backup clutter
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; UTF-8 everywhere
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; Better defaults
(electric-pair-mode 1)
(show-paren-mode 1)
(delete-selection-mode 1)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(recentf-mode 1)

;; Scrolling
(setq scroll-margin 5
      scroll-conservatively 10000
      scroll-step 1)

;; Indentation
(setq-default indent-tabs-mode nil
              tab-width 4)
