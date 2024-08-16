;;; me-extra.el --- Some extra functionalities -*- lexical-binding: t; -*-

;;; ___________               __         .__
;;; \_   _____/ _____ _____ _/  |________|__|__  ___
;;;  |    __)_ /     \\__  \\   __\_  __ \  \  \/  /
;;;  |        \  Y Y  \/ __ \|  |  |  | \/  |>    <
;;; /_______  /__|_|  (____  /__|  |__|  |__/__/\_ \
;;;         \/      \/     \/                     \/
;;;
;;;  EMATRIX & LIGHTWEIGHT EMACS CONFIGURATION FRAMEWORK
;;;                        donneyluck.github.io/ematrix
;;;
;;; Author: donneyluck@gmail.com
;;; Copyright (C) 2022-2024  Machine Sudio

;;; Commentary:

;;; Code:

(use-package better-jumper
  :straight t
  :hook (minemacs-lazy . better-jumper-mode)
  ;; Map extra mouse buttons to jump forward/backward
  :bind (("<mouse-8>" . better-jumper-jump-backward)
         ("<mouse-9>" . better-jumper-jump-forward)))

(use-package crux
  :straight t
  :bind (("C-c o o" . crux-open-with)
         ("C-k" . crux-smart-kill-line)
         ("C-<return>" . crux-smart-open-line)
         ("C-S-<return>" . crux-smart-open-line-above)
         ("C-c n" . crux-cleanup-buffer-or-region)
         ("C-c u" . crux-view-url)
         ("C-c 4 t" . crux-transpose-windows)))


(provide 'me-extra)

;;; me-extra.el ends here
