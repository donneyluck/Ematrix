;;; me-files.el --- File management -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2024  Abdelhak Bougouffa

;; Author: Abdelhak Bougouffa (rot13 "nobhtbhssn@srqbencebwrpg.bet")

;;; Commentary:

;;; Code:

(use-package dirvish
  :straight t
  :after dired
  :demand
  :custom
  (dirvish-attributes '(subtree-state nerd-icons file-size))
  (dirvish-mode-line-format '(:left (sort file-time symlink) :right (omit yank index)))
  (dirvish-side-width 30)
  (dirvish-fd-default-dir "~/")
  (dirvish-use-header-line t) ; 'global make header line span all panes
  (dirvish-use-mode-line t)
  (dirvish-subtree-state-style 'nerd)
  :config
  ;; Cscope generate *.po files which that makes dirvish preview freeze
  (push "po" dirvish-preview-disabled-exts)
  ;; Use `nerd-icons' for path separators (from https://github.com/rainstormstudio/nerd-icons.el)
  (with-eval-after-load 'nerd-icons
    (setq dirvish-path-separators (list (format "  %s " (nerd-icons-codicon "nf-cod-home"))
                                        (format "  %s " (nerd-icons-codicon "nf-cod-root_folder"))
                                        (format " %s " (nerd-icons-faicon "nf-fa-angle_right")))))
  (dirvish-override-dired-mode 1))

(use-package sr-speedbar
  :straight t)

(use-package vlf-setup
  :straight (vlf :source gnu-elpa-mirror)
  :demand
  :config
  (with-eval-after-load 'so-long
    (add-to-list 'so-long-mode-preserved-variables 'vlf-mode)))

(use-package sudo-edit
  :straight t
  :hook (minemacs-first-file . sudo-edit-indicator-mode))

(use-package dired-rsync
  :straight (:files ("dired-rsync.el" "dired-rsync-transient.el"))
  :bind (:map
         dired-mode-map
         ("C-c C-r" . dired-rsync)
         ("C-c C-x" . dired-rsync-transient)))

(use-package ztree
  :straight (:source gnu-elpa-mirror))


(provide 'me-files)

;;; me-files.el ends here
