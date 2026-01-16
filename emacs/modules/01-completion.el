;;; -*- lexical-binding: t -*-

;; Vertico: vertical minibuffer completion
(use-package vertico
  :demand t
  :config (vertico-mode 1))

;; Corfu: in-buffer completion popup
(use-package corfu
  :demand t
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-preselect 'first)
  (corfu-preview-current nil)
  (corfu-popupinfo-delay '(0.2 . 0.5))
  :config
  (global-corfu-mode)
  (require 'corfu-popupinfo)
  (corfu-popupinfo-mode 1))

(use-package nerd-icons)

(use-package nerd-icons-completion
  :after (marginalia nerd-icons)
  :config
  (nerd-icons-completion-mode)
  (nerd-icons-completion-marginalia-setup))

(use-package kind-icon
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default)
  (kind-icon-use-icons t)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))


;; Orderless: fuzzy matching
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t))

;; Marginalia: annotations in minibuffer
(use-package marginalia
  :bind (:map minibuffer-local-map ("M-A" . marginalia-cycle))
  :init (marginalia-mode))

;; Savehist: remember completion history
(use-package savehist
  :init (savehist-mode))

;; Consult: search + navigation
(use-package consult
  :bind (("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("C-x b" . consult-buffer)))

(use-package consult-dir
  :after consult
  :bind ("C-x C-d" . consult-dir))

;; Embark: contextual actions
(use-package embark
  :bind (("C-." . embark-act))
  :custom (prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult))

;; Cape: completion at point extensions
(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

;; Avy: jump to visible text
(use-package avy
  :bind ("M-j" . avy-goto-char-timer))

;; Helpful: better help buffers
(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)
         ("C-h F" . helpful-function)))
