;;; early-config.el --- Early configuration file -*- coding: utf-8-unix; lexical-binding: t; -*-

;; Copyright (C) 2022-2024 Abdelhak Bougouffa

;; This file will be loaded at the end of `early-init.el', it can be used to set
;; some early initialization stuff, or to set some Ematrix variables, specially
;; these used in macros.

;; Set log level to `info' rather than `error'
(unless ematrix-verbose-p
  (setq ematrix-msg-level 2))

;; Setup proxies
;; (setq ematrix-proxies
;;       '(("no" . "localhost,127.0.0.1,.local,.mylocaltld")
;;         ("ftp" . "http://myproxy.local:8080/")
;;         ("http" . "http://myproxy.local:8080/")
;;         ("https" . "http://myproxy.local:8080/")))

;; Enable full screen at startup
;; (if-let ((fullscreen (assq 'fullscreen default-frame-alist)))
;;     (setcdr fullscreen 'fullboth)
;;   (push '(fullscreen . fullboth) default-frame-alist))

;; Force loading lazy packages immediately, not in idle time
;; (setq ematrix-not-lazy-p t)

;; Setup a `debug-on-message' to catch a wired message!
;; (setq debug-on-message "Package cl is deprecated")

;; Compute statistics to use with `use-package-report'
;; (setq use-package-compute-statistics t)
