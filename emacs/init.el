;;; -*- lexical-binding: t -*-

;; Package setup
(require 'package)
(setq package-archives '(("gnu"   . "https://elpa.gnu.org/packages/")
                       ("nongnu" . "https://elpa.nongnu.org/packages/")
                       ("melpa" . "https://melpa.org/packages/")))

(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" user-emacs-directory))

(add-hook 'after-init-hook
          (lambda ()
            (load-theme 'ashen t)))

(unless package-archive-contents
  (package-refresh-contents))


;; Load modules
(let ((module-dir (expand-file-name "modules" user-emacs-directory)))
  (dolist (file (directory-files module-dir t "^[0-9].*\\.el$"))
    (load file)))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
