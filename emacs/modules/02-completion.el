;;; -*- lexical-binding: t -*-

;; Vertico: vertical minibuffer completion
(use-package vertico
  :init (vertico-mode))

;; Corfu: in-buffer completion popup
(use-package corfu
  :init (global-corfu-mode))

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
