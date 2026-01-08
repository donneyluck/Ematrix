;; ematrix-loaded.el -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2024  Abdelhak Bougouffa

;; Author: Abdelhak Bougouffa (rot13 "nobhtbhssn@srqbencebwrpg.bet")

;;; Commentary:

;; This feature is loaded at end of init.el (after loading custom-vars.el), it
;; is used to synchronize loading some other stuff after loading Emacs

;;; Code:

;; Run hooks
(when ematrix-after-startup-hook
  (setq ematrix-after-startup-hook (reverse ematrix-after-startup-hook))
  (+log! "Running %d `ematrix-after-startup-hook' hooks."
         (length ematrix-after-startup-hook))
  (run-hooks 'ematrix-after-startup-hook))

(+load ematrix-core-dir "ematrix-lazy.el")

(+log! "Providing `ematrix-loaded'.")


(provide 'ematrix-loaded)

;;; ematrix-loaded.el ends here
