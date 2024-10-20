;;; me-ui.el --- UI stuff -*- lexical-binding: t; -*-

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

(use-package nerd-icons
  :straight t
  :hook (minemacs-build-functions . nerd-icons-install-fonts)
  :config
  ;; Show .m files as Matlab/Octave files (integral icon)
  (setcdr (assoc "m" nerd-icons-extension-icon-alist) '(nerd-icons-mdicon "nf-md-math_integral_box" :face nerd-icons-orange)))

(use-package doom-themes
  :straight t
  :config
  (with-eval-after-load 'org
    (doom-themes-org-config))
  ;; Enable blinking modeline on errors (`visible-bell')
  (+with-delayed-1! (doom-themes-visual-bell-config)))

(use-package doom-modeline
  :straight t
  :hook (minemacs-lazy . doom-modeline-mode)
  :custom
  (doom-modeline-bar-width 1)
  (doom-modeline-time-icon nil)
  (doom-modeline-buffer-encoding 'nondefault)
  (doom-modeline-unicode-fallback t)
  (doom-modeline-total-line-number t)
  (doom-modeline-enable-word-count t)
  (doom-modeline-continuous-word-count-modes '(markdown-mode markdown-ts-mode gfm-mode org-mode rst-mode latex-mode tex-mode))
  :custom-face
  ;; Hide the modeline bar
  (doom-modeline-bar ((t (:inherit mode-line :background unspecified))))
  (doom-modeline-bar-inactive ((t (:inherit mode-line :background unspecified)))))

;; NOT USE
;; (use-package enlight
;;   :straight (:host github :repo "ichernyshovvv/enlight")
;;   :when (>= emacs-major-version 29) ; TEMP+BUG: There is an issue with Emacs 28
;;   :custom
;;   (enlight-content
;;    (enlight-menu
;;     '(("Org Mode"
;;        ("Org-Agenda (today)" (org-agenda nil "a") "a"))
;;       ("Projects"
;;        ("Switch to project" project-switch-project "p")))))
;;   :init
;;   (if minemacs-started-with-extra-args-p
;;       (enlight-open)
;;     (setq initial-buffer-choice #'enlight)))

;; (use-package lacarte
;;   :straight t
;;   :bind ([f10] . lacarte-execute-menu-command))

(use-package svg-lib
  :straight t
  :custom
  (svg-lib-icons-dir (concat minemacs-cache-dir "svg-lib/icons/")))

(use-package mixed-pitch
  :straight t
  :custom
  (mixed-pitch-variable-pitch-cursor nil)
  :config
  (setq
   mixed-pitch-fixed-pitch-faces
   (delete-dups
    (append
     mixed-pitch-fixed-pitch-faces
     '(font-lock-comment-delimiter-face font-lock-comment-face org-block
       org-block-begin-line org-block-end-line org-cite org-cite-key
       org-document-info-keyword org-done org-drawer org-footnote org-formula
       org-inline-src-block org-latex-and-related org-link org-code org-column
       org-column-title org-date org-macro org-meta-line org-property-value
       org-quote org-ref-cite-face org-sexp-date org-special-keyword org-src
       org-table org-tag org-tag-group org-todo org-verbatim org-verse)))))

(use-package page-break-lines
  :straight t
  :hook ((prog-mode text-mode special-mode) . page-break-lines-mode))

(use-package focus
  :straight t)

(use-package olivetti
  :straight t)

(use-package nerd-icons-ibuffer
  :straight t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

;; NOT USE
;; (use-package casual-lib
;;   :straight (:host github :repo "kickingvegas/casual-lib"))

;; (use-package casual-isearch
;;   :straight (:host github :repo "kickingvegas/casual-isearch")
;;   :bind (:package isearch :map isearch-mode-map ([f2] . casual-isearch-tmenu)))


(provide 'me-ui)

;;; me-ui.el ends here
