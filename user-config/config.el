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

;; 搜索/找文件时隐藏 Unity 的 .meta(被 git 追踪,git ls-files 会列出,
;; 加到 grep 忽略表后 project-find-file / consult-grep 不再显示)
(add-to-list 'grep-find-ignored-files "*.meta")

;; consult-ripgrep 不吃 grep-find-ignored-files,给它加 -g '!*.meta'
(with-eval-after-load 'consult
  (setq consult-ripgrep-args
        (string-trim
         (concat consult-ripgrep-args " -g '!*.meta'"))))

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

