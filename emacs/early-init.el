;;; -*- lexical-binding: t -*-

(setq initial-frame-alist '((width . 100) (height . 40))
      default-frame-alist '((width . 100) (height . 40)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Startup speed: boost GC threshold
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Disable slow file handlers during startup
(defvar my-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; Restore after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 100 1024 1024)
                  gc-cons-percentage 0.1
                  file-name-handler-alist my-file-name-handler-alist)))

;; Misc
(setq native-comp-async-report-warnings-errors 'silent)
(setq package-quickstart t)
