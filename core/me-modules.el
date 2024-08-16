;;; me-modules.el -*- lexical-binding: t; -*-

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

(defcustom minemacs-core-modules '()
  "Ematrix enabled core modules."
  :group 'minemacs-core
  :type '(repeat symbol))

(defcustom minemacs-modules
  '(;; me-ai
    ;; me-biblio
    ;; me-calendar
    ;; me-checkers
    ;; me-clojure
    ;; me-common-lisp
    me-completion
    ;; me-daemon
    me-data
    me-debug
    me-docs
    me-editor
    me-emacs-lisp
    ;; me-email
    ;; me-embedded
    me-evil
    me-extra
    me-files
    ;; me-fun
    me-god
    ;; me-gtd
    me-keybindings
    me-latex
    ;; me-lifestyle
    ;; me-math
    ;; me-media
    ;; me-modeling
    ;; me-meow
    me-multi-cursors
    ;; me-nano
    me-natural-langs
    me-notes
    me-org
    me-prog
    me-project
    me-dashboard
    ;; me-robot
    ;; me-rss
    ;; me-scheme
    ;; me-services
    ;; me-tags
    me-tools
    me-tty
    me-ui
    me-undo
    me-vc
    me-window
    me-workspaces)
  "MinEmacs enabled modules."
  :group 'minemacs-core
  :type '(repeat symbol))

;;; me-modules.el ends here
