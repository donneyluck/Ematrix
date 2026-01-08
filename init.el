;; init.el --- Ematrix core initialization file -*- lexical-binding: t; -*-

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

;; # Ematrix - a minimalist & lightweight Emacs configuration framework

;; Load and hooks order:
;; - `~/.emacs.d/early-init.el`
;; - `$EMATRIXDIR/early-config.el` (unless disabled in `$EMATRIX_IGNORE_USER_CONFIG`)
;; - `$EMATRIXDIR/local/early-config.el` (unless disabled)
;; - `~/.emacs.d/init.el`
;;   * `before-init-hook'
;;   * `~/.emacs.d/core/me-vars.el`
;;   * `~/.emacs.d/core/backports/*.el` (when Emacs < 29)
;;   * `~/.emacs.d/core/me-loaddefs.el`
;;   * `$EMATRIXDIR/init-tweaks.el` (unless disabled)
;;   * `$EMATRIXDIR/local/init-tweaks.el` (unless disabled)
;;   * `$EMATRIXDIR/modules.el` (unless disabled)
;;   * `$EMATRIXDIR/local/modules.el` (unless disabled)
;;   * `~/.emacs.d/core/<module>.el`
;;   * `~/.emacs.d/modules/<module>.el` (for module in `ematrix-modules')
;;   * `ematrix-after-loading-modules-hook'
;;   * `$EMATRIXDIR/custom-vars.el`
;;   * `$EMATRIXDIR/config.el` (unless disabled)
;;   * `$EMATRIXDIR/local/config.el` (unless disabled)
;;   * `after-init-hook'
;;   * `emacs-startup-hook'
;;   * `ematrix-after-startup-hook'
;;     + `ematrix-lazy-hook' (delayed)

;; Special hooks defined with `+make-first-file-hook!'
;; - `ematrix-first-file-hook'
;; - `ematrix-first-elisp-file-hook'
;; - `ematrix-first-python-file-hook'
;; - `ematrix-first-org-file-hook'
;; - `ematrix-first-c/c++-file-hook'

;;; Code:

;; Run a profiling session if `$EMATRIX_BENCHMARK' is defined.
(when (getenv "EMATRIX_BENCHMARK")
  (let ((dir (concat (file-name-directory load-file-name) "elisp/benchmark-init/")))
    (if (not (file-exists-p (concat dir "benchmark-init.el")))
        (error "[Ematrix:Error] `benchmark-init' is not available, make sure you've run \"git submodule update --init\" inside Ematrix' directory")
      (add-to-list 'load-path dir)
      (require 'benchmark-init)
      (benchmark-init/activate)

      (defun +benchmark-init--desactivate-and-show-h ()
        (benchmark-init/deactivate)
        (require 'benchmark-init-modes)
        (benchmark-init/show-durations-tree))

      (with-eval-after-load 'me-vars
        (add-hook 'ematrix-lazy-hook #'+benchmark-init--desactivate-and-show-h 99)))))

;; Check if Emacs version is supported.
(let ((min-ver 28))
  (when (< emacs-major-version min-ver)
    (error "Emacs v%s is not supported, Ematrix requires v%s or higher" emacs-version min-ver)))

;; PERF: Setting `file-name-handler-alist' to nil should boost startup time.
;; reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start
;; Store the current value so we can reset it after Emacs startup.
(put 'file-name-handler-alist 'original-value (default-toplevel-value 'file-name-handler-alist))
;; Make sure the new value survives any current let-binding.
(set-default-toplevel-value 'file-name-handler-alist nil)
;; After Emacs startup, we restore `file-name-handler-alist' while conserving
;; the potential new elements made during startup.
(defun +mineamcs--restore-file-name-handler-alist-h ()
  (setq file-name-handler-alist (delete-dups (append file-name-handler-alist (get 'file-name-handler-alist 'original-value)))))
(add-hook 'emacs-startup-hook '+mineamcs--restore-file-name-handler-alist-h 99)

;; HACK: At this point, Ematrix variables defined in `me-vars' should be
;; already loaded (in "early-init.el"). However, we double-check here and load
;; them if necessary in case Emacs has been loaded directly from "init.el"
;; without passing by "early-init.el". This can happen when we are running in a
;; `me-org-export-async-init' context, or if we use some bootstrapping mechanism
;; like Chemacs2.
(unless (featurep 'me-vars)
  (load (expand-file-name "core/me-vars.el" (file-name-directory (file-truename load-file-name))) nil t))

;; Add some of Ematrix' directories to `load-path'.
(setq load-path (append (list ematrix-core-dir ematrix-elisp-dir ematrix-extras-dir ematrix-modules-dir) load-path))

;; Load Ematrix' library
(require 'me-lib)

;; HACK: Most Emacs' builtin and third-party packages depends on the
;; `user-emacs-directory' variable to store cache information, generated
;; configuration files and downloaded utilities. However, this will mess with
;; Ematrix' directory (which defaults to `user-emacs-directory'). To keep the
;; "~/.emacs.d/" directory clean, we overwrite the `user-emacs-directory' at
;; early stage with `ematrix-local-dir' so all generated files gets stored in
;; "~/.emacs.d/local/".
;; NOTE: It is important to set this here and not in `me-vars' nor in
;; "early-init.el", otherwise, it won't work with Chemacs2-based installations.
(setq user-emacs-directory ematrix-local-dir)

;; HACK: Load Emacs 29 back ports for earlier Emacs versions. Note that I do
;; only back port a very small number of the functions/variables that I use at
;; early stage from Emacs29+ to be compatible with Emacs 28.2. For any Emacs
;; version less than 29, Ematrix will enable the `me-compat' module and load it
;; just after `me-bootstrap'. This module loads the `compat' package which
;; provide several forward compatibility functions, it is loaded at an early
;; stage to provide its functionality to the rest of the modules so we can use
;; some new features when configuring them.
(when (< emacs-major-version 29)
  (let ((backports-dir (concat ematrix-core-dir "backports/")))
    (mapc (apply-partially #'+load backports-dir) (directory-files backports-dir nil "\\.el\\'"))))

(setq
 ;; Enable debugging on error when Emacs is launched with the `--debug-init`
 ;; option or when the environment variable `$EMATRIX_DEBUG` is defined (see
 ;; `me-vars').
 debug-on-error ematrix-debug-p
 ;; Decrease the warning type to `:error', unless we are running in verbose mode
 warning-minimum-level (if ematrix-verbose-p :warning :error)
 warning-minimum-log-level warning-minimum-level
 ;; Make byte compilation less noisy
 byte-compile-warnings ematrix-verbose-p
 byte-compile-verbose ematrix-verbose-p)

;; Native compilation settings
(when (featurep 'native-compile)
  (setq
   ;; Silence compiler warnings as they can be pretty disruptive, unless we are
   ;; running in `ematrix-verbose-p' mode.
   native-comp-async-report-warnings-errors (when ematrix-verbose-p 'silent)
   native-comp-verbose (if ematrix-verbose-p 1 0) ; do not be too verbose
   native-comp-debug (if ematrix-debug-p 1 0)
   ;; Make native compilation happens asynchronously.
   native-comp-jit-compilation t)

  ;; Set the right directory to store the native compilation cache to avoid
  ;; messing with "~/.emacs.d/".
  (startup-redirect-eln-cache (concat ematrix-cache-dir "eln/")))

(defun ematrix-generate-loaddefs ()
  "Generate Ematrix' loaddefs file."
  (interactive)
  (when (file-exists-p ematrix-loaddefs-file) (delete-file ematrix-loaddefs-file))
  (apply (if (fboundp 'loaddefs-generate) #'loaddefs-generate #'make-directory-autoloads)
         (list (list ematrix-core-dir ematrix-elisp-dir ematrix-extras-dir) ematrix-loaddefs-file)))

;; Some of Ematrix commands and libraries are defined to be auto-loaded. In
;; particular, these in the `ematrix-core-dir', `ematrix-elisp-dir', and
;; `ematrix-extras-dir' directories. The generated loaddefs file will be stored
;; in `ematrix-loaddefs-file'. We first regenerate the loaddefs file if it
;; doesn't exist.
(unless (file-exists-p ematrix-loaddefs-file) (ematrix-generate-loaddefs))

;; Then we load the loaddefs file
(+load ematrix-loaddefs-file)

;; Load user init tweaks when available
(+load-user-configs 'init-tweaks 'local/init-tweaks)

;; When `ematrix-proxies' is set in "early-init.el" or in "init-tweaks.el",
;; `ematrix-enable-proxy' will set the environment variables accordingly.
(unless ematrix-no-proxies-p (ematrix-enable-proxy ematrix-proxies))

;; HACK: Load the environment variables saved from shell using `+env-save' to
;; `+env-file'. `+env-save' saves all environment variables except these matched
;; by `+env-deny-vars'.
(+env-load) ; Load environment variables when available.

(defun +ematrix--loaded-h ()
  "This is Ematrix' synchronization point.

To achieve fast Emacs startup, we try to defer loading most of
the packages until this hook is executed. This is managed by the
`ematrix-loaded' and `ematrix-lazy' features.

After loading Emacs, the `emacs-startup-hook' gets executed, we
use this hook to profile the startup time, and load the theme.
Lastly we require the `ematrix-loaded' synchronization module,
which runs the `ematrix-after-startup-hook' hooks and provide
`ematrix-loaded' so the packages loaded with `:after
ematrix-loaded' can be loaded.

The `ematrix-loaded' will require `ematrix-lazy', which
incrementally run the hooks in `ematrix-lazy-hook' after
startup, and at the end, provide the `ematrix-lazy' feature so
the packages loaded with `:after ematrix-lazy' can be loaded."
  (+info! "Loaded Emacs%s in %s, including %.3fs for %d GCs." (if (daemonp) " (in daemon mode)" "") (emacs-init-time) gc-elapsed gcs-done)
  (unless (featurep 'me-org-export-async-init) (+load-theme))
  (require 'ematrix-loaded))

;; Add it to the very beginning of `emacs-startup-hook'
(add-hook 'emacs-startup-hook #'+ematrix--loaded-h -91)

;; ========= Make some special hooks =========
(+make-first-file-hook! 'org "\\.org$")
(+make-first-file-hook! 'elisp "\\.elc?$")
(+make-first-file-hook! 'python (rx "." (or "py" "pyw" "pyx" "pyz" "pyzw") eol))
(+make-first-file-hook! 'c/c++ (rx "." (or "c" "cpp" "cxx" "cc" "c++" "h" "hpp" "hxx" "hh" "h++" "ixx" "cppm" "cxxm" "c++m" "ccm") eol))
(+make-first-file-hook! nil ".")

;; ========= Load Ematrix packages and user customization =========
;; When running in an async Org export context, the used modules are set in
;; modules/extras/me-org-export-async-init.el, so we must not override them with
;; the user's enabled modules.
(if (featurep 'me-org-export-async-init)
    (progn (message "Loading \"init.el\" in an org-export-async context.")
           (setq ematrix-not-lazy-p t))
  ;; Load the default list of enabled modules `ematrix-modules'
  (+load ematrix-core-dir "me-modules.el")
  (+load-user-configs 'modules 'local/modules))

;; When the EMATRIX_LOAD_ALL_MODULES environment variable is set, we force
;; loading all modules.
(when ematrix-load-all-modules-p
  (setq ematrix-modules (ematrix-modules)))

(when (bound-and-true-p ematrix-core-modules)
  (message "[Ematrix:Warn] The `me-completion', `me-keybindings' and `me-evil' modules have been moved to `ematrix-modules'. The `ematrix-core-modules' variable is now obsolete."))

;; Ematrix 7.0.0 uses only `ematrix-modules'. The `ematrix-core-modules' is left for now just to ensure compatibility.
(setq ematrix-modules (cl-delete-if (+apply-partially-right #'memq '(me-splash me-bootstrap me-builtin me-compat me-gc))
                                     (delete-dups (append (bound-and-true-p ematrix-core-modules) ematrix-modules))))

;; Load modules
(mapc #'+load (mapcar (apply-partially #'format "%s%s.el" ematrix-core-dir) '(me-bootstrap me-compat me-builtin me-gc)))
(mapc #'+load (mapcar (apply-partially #'format "%s%s.el" ematrix-modules-dir) ematrix-modules))

;; Run hooks
(run-hooks 'ematrix-after-loading-modules-hook)

;; Write user custom variables to separate file instead of "init.el"
(setq custom-file (concat ematrix-config-dir "custom-vars.el"))

;; Load the custom variables file if it exists
(when (file-exists-p custom-file) (+load custom-file))

;; Load user configuration
(+load-user-configs 'config 'local/config)


(+log! "Loaded init.el")

;;; init.el ends here
(put 'dired-find-alternate-file 'disabled nil)
