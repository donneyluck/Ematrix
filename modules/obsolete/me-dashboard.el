;;; me-dashboard.el --- Dashboard for Emacs -*- lexical-binding: t; -*-

;;; Copyright (C) 2022-2024  Machine Sudio

;;; Author: donneyluck@gmail.com

;;; ___________               __         .__
;;; \_   _____/ _____ _____ _/  |________|__|__  ___
;;;  |    __)_ /     \\__  \\   __\_  __ \  \  \/  /
;;;  |        \  Y Y  \/ __ \|  |  |  | \/  |>    <
;;; /_______  /__|_|  (____  /__|  |__|  |__/__/\_ \
;;;         \/      \/     \/                     \/
;;;
;;;  EMATRIX & LIGHTWEIGHT EMACS CONFIGURATION FRAMEWORK
;;;                        donneyluck.github.io/ematrix

;;; Commentary:

;;; Code:


(use-package dashboard
  :straight t
  :after evil evil-collection
  :demand
  :unless (bound-and-true-p +dashboard-disable)
  :init
  (+map! "oD" #'dashboard-open)
  :custom
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-center-content t)
  (dashboard-banner-ascii "Ematrix")
  (dashboard-banner-logo-title "Welcome to Ematrix!")
  (dashboard-items '((recents . 5) (projects . 5) (bookmarks . 5)))
  (dashboard-image-banner-max-width 600)
  (dashboard-projects-backend 'project-el)
  (dashboard-startup-banner (concat ematrix-assets-dir "images/ematrix.png"))
  :config
  ;; Ensure setting the keybindings before opening the dashboard
  (with-eval-after-load 'evil (evil-collection-dashboard-setup))

  ;; Avoid opening the dashboard when Emacs starts with an open file.
  (unless (cl-some #'buffer-file-name (buffer-list))
    (dashboard-open)))


(provide 'me-dashboard)
;;; me-dashboard.el ends here
