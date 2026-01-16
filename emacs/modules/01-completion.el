;;; -*- lexical-binding: t -*-

;; Vertico: vertical minibuffer completion
(use-package vertico
  :ensure t
  :init (vertico-mode))

;; Corfu: in-buffer completion popup
(use-package corfu
  :ensure t
  :config (global-corfu-mode))

;; Orderless: fuzzy matching
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t))

;; Marginalia: annotations in minibuffer
(use-package marginalia
  :ensure t
  :bind (:map minibuffer-local-map ("M-A" . marginalia-cycle))
  :init (marginalia-mode))

;; Savehist: remember completion history
(use-package savehist
  :ensure t
  :init (savehist-mode))
