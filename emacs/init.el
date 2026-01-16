;;; -*- lexical-binding: t -*-

;; Package setup
(require 'package)
(setq package-archives '(("gnu"   . "https://elpa.gnu.org/packages/")
                       ("nongnu" . "https://elpa.nongnu.org/packages/")
                       ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; Speed up packages
(setq package-quickstart t)

;; Load modules
(let ((module-dir (expand-file-name "modules" user-emacs-directory)))
  (dolist (file (directory-files module-dir t "^[0-9].*\\.el$"))
    (load file)))
