(setq doom-font (font-spec :family "MartianMono Nerd Font" :size 16)
      doom-variable-pitch-font (font-spec :family "Ubuntu" :size 16))
(setq doom-theme 'catppuccin)
(setq display-line-numbers-type 'relative)
(setq org-directory "~/Documents/Org/")

(set-frame-parameter (selected-frame) 'alpha '(95 95))
(add-to-list 'default-frame-alist '(alpha 95 95))
(add-to-list 'default-frame-alist '(undecorated . t))

(require 'elcord)
(setq elcord-editor-icon "emacs_icon")
(setq elcord-use-major-mode-as-main-icon t)
(elcord-mode)

(setq circe-network-options
      '(("colonq"
         :tls t
         :host "colonq.computer"
         :port 26697
         :nick "liyah"
         :pass "liyah:mBiD29tH"
         :channels ("#cyberspace")
         )))

(setq lsp-solargraph-completion t)
(setq lsp-solargraph-definitions t)
(setq lsp-solargraph-diagnostics t)
(setq lsp-solargraph-formatting t)
(setq lsp-solargraph-hover t)
(setq lsp-solargraph-references t)
(setq lsp-solargraph-rename t)
(setq lsp-solargraph-symbols t)
