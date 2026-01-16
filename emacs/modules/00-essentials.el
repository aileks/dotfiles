;;; -*- lexical-binding: t -*-

;; Purist: no backup clutter
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      ring-bell-function 'ignore
      visible-bell nil
      require-final-newline t)

;; Confirm exit
(setq confirm-kill-emacs 'y-or-n-p)

;; UTF-8 everywhere
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8)

;; Better defaults
(electric-pair-mode 1)
(show-paren-mode 1)
(delete-selection-mode 1)
(column-number-mode 1)
(recentf-mode 1)

;; Line numbers only in code
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Prefer y/n
(fset 'yes-or-no-p 'y-or-n-p)

;; Scrolling
(setq scroll-margin 5
      scroll-conservatively 10000
      scroll-step 1
      scroll-preserve-screen-position t)

;; Indentation
(setq-default indent-tabs-mode nil
              tab-width 4)

;; No dialog prompts
(setq use-dialog-box nil)

;; Keep scratch clean
(setq initial-scratch-message nil)

;; Avoid cursor blink
(blink-cursor-mode 0)

;; Save place in files
(save-place-mode 1)

