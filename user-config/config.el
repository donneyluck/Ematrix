;;; config.el -*- lexical-binding: t; -*-

;; Font: matches Ghostty (font-family = Fira Code, font-size = 13).
;; :height 130 = 13pt. Plain "Fira Code" (not the Nerd Font variant);
;; nerd-icons glyphs render via the Symbols Nerd Font fallback below.
(plist-put ematrix-fonts-plist
           :default
           '((:family "Fira Code" :height 120)))

;; Icons: nerd-icons defaults to "Symbols Nerd Font Mono", but only
;; "Symbols Nerd Font" is installed on this system -> icons render as tofu.
(with-eval-after-load 'nerd-icons
  (setq nerd-icons-font-family "Symbols Nerd Font"))

;; project-find-file 等命令对 git 项目走 git ls-files(不是 rg/grep),
;; 用 project-vc-ignores 传 exclude pathspec 给 git,排除 Unity .meta
(setq project-vc-ignores '("*.meta"))

;; consult-ripgrep 不吃 project-vc-ignores,给它加 -g !*.meta
;; 注意:consult 不走 shell,直接拆 argv,所以 ! 不用引号保护
;; (单引号会被 split-string-and-unquote 当字面字符,导致 rg glob 非法报错)
(with-eval-after-load 'consult
  (setq consult-ripgrep-args
        (concat consult-ripgrep-args " -g !*.meta")))

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

