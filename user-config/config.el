;;; config.el -*- lexical-binding: t; -*-

;; Font: matches Ghostty (font-family = Fira Code, font-size = 13).
;; :height 130 = 13pt. Plain "Fira Code" (not the Nerd Font variant);
;; nerd-icons glyphs render via the Symbols Nerd Font fallback below.
(plist-put ematrix-fonts-plist
           :default
           '((:family "Fira Code" :height 130)))

;; Icons: nerd-icons defaults to "Symbols Nerd Font Mono", but only
;; "Symbols Nerd Font" is installed on this system -> icons render as tofu.
(with-eval-after-load 'nerd-icons
  (setq nerd-icons-font-family "Symbols Nerd Font"))

;; WebSocket for IDE integration (emacs-websocket)
(use-package websocket
  :straight (:host github :repo "ahyatt/emacs-websocket")
  :demand)

;; Catppuccin (Mocha) theme — matches Ghostty
(use-package catppuccin-theme
  :load-path "~/.emacs.d/local/straight/repos/catppuccin-emacs"
  :demand
  :config
  (setq catppuccin-flavor 'mocha)
  (catppuccin-load-flavor 'mocha)
  (catppuccin-reload)
  (setq ematrix-theme 'catppuccin))

