(setq gc-cons-threshold (* 50 1000 1000))

(org-babel-load-file
 (expand-file-name
  "config.org"
  user-emacs-directory))

(setq gc-cons-threshold (* 2 1000 1000))
