;; ematrix-lazy.el -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2024  Abdelhak Bougouffa

;; Author: Abdelhak Bougouffa (rot13 "nobhtbhssn@srqbencebwrpg.bet")

;;; Commentary:

;; Feature loaded when Emacs is idle after `ematrix-loaded', it is used to
;; lazily load other stuff after loading Emacs.

;; The hooks in `ematrix-lazy-hook' are loaded incrementally when Emacs goes
;; idle, but when `ematrix-not-lazy-p' is set to t, they will be all loaded at
;; once.

;;; Code:

;; Run hooks
(when ematrix-lazy-hook
  (if ematrix-not-lazy-p
      (progn ; If `ematrix-not-lazy-p' is true, force loading lazy hooks immediately
        (+log! "Loading %d lazy packages immediately." (length ematrix-lazy-hook))
        (run-hooks 'ematrix-lazy-hook)
        (provide 'ematrix-lazy))
    (+log! "Loading %d lazy packages incrementally." (length ematrix-lazy-hook))
    (cl-callf append ematrix--lazy-high-priority-forms
      (mapcar #'ensure-list ematrix-lazy-hook)
      '((provide 'ematrix-lazy))))) ;; Provide `ematrix-lazy' at the end

(defvar ematrix--lazy-high-priority-timer
  (run-with-timer
   0.1 0.001
   (lambda ()
     (if ematrix--lazy-high-priority-forms
         (let ((inhibit-message (not ematrix-verbose-p)))
           (eval (pop ematrix--lazy-high-priority-forms)))
       (progn
         (cancel-timer ematrix--lazy-high-priority-timer))))))

(defvar ematrix--lazy-low-priority-timer
  (run-with-timer
   0.3 0.001
   (lambda ()
     (if ematrix--lazy-low-priority-forms
         (let ((inhibit-message (not ematrix-verbose-p)))
           (eval (pop ematrix--lazy-low-priority-forms)))
       (progn
         (cancel-timer ematrix--lazy-low-priority-timer))))))

;;; ematrix-lazy.el ends here
