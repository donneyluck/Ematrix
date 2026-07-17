;; me-vars.el --- Ematrix -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2024  Abdelhak Bougouffa

;; Author: Abdelhak Bougouffa (rot13 "nobhtbhssn@srqbencebwrpg.bet")

;;; Commentary:

;;; Code:

;;; Ematrix groups

(defgroup ematrix nil "Ematrix specific functionalities." :group 'emacs)
(defgroup ematrix-apps nil "Ematrix applications." :group 'ematrix)
(defgroup ematrix-binary nil "Ematrix binary files." :group 'ematrix)
(defgroup ematrix-buffer nil "Ematrix buffer stuff." :group 'ematrix)
(defgroup ematrix-completion nil "Completion related stuff." :group 'ematrix)
(defgroup ematrix-core nil "Ematrix core tweaks." :group 'ematrix)
(defgroup ematrix-edit nil "Ematrix editor tweaks." :group 'ematrix)
(defgroup ematrix-keybinding nil "Ematrix keybinding." :group 'ematrix)
(defgroup ematrix-org nil "Ematrix org-mode tweaks." :group 'ematrix)
(defgroup ematrix-prog nil "Ematrix programming stuff." :group 'ematrix)
(defgroup ematrix-project nil "Ematrix project stuff." :group 'ematrix)
(defgroup ematrix-ui nil "Ematrix UI tweaks." :group 'ematrix)
(defgroup ematrix-utils nil "Ematrix utility functions." :group 'ematrix)
(defgroup ematrix-blog nil "Ematrix blog stuff" :group 'ematrix)

;;; Ematrix directories

(defconst ematrix-ignore-user-config
  (let* ((ignores (getenv "EMATRIX_IGNORE_USER_CONFIG"))
         (ignores (and ignores (downcase ignores))))
    (when ignores
      (if (string= ignores "all")
          '(early-config init-tweaks modules config local/early-config local/init-tweaks local/modules local/config)
        (mapcar #'intern (split-string ignores)))))
  "Ignore loading these user configuration files.
Accepted values are: early-config, init-tweaks, modules, config,
local/early-config, local/init-tweaks, local/modules and local/config.
This list is automatically constructed from the space-separated values in the
environment variable \"$EMATRIX_IGNORE_USER_CONFIG\".")

(defconst ematrix-debug-p
  (and (or (getenv "EMATRIX_DEBUG") init-file-debug) t)
  "Ematrix is started in debug mode.")

(defconst ematrix-verbose-p
  (and (or (getenv "EMATRIX_VERBOSE") ematrix-debug-p) t)
  "Ematrix is started in verbose mode.")

(defconst ematrix-always-demand-p
  (and (getenv "EMATRIX_ALWAYS_DEMAND") t)
  "Load all packages immediately, do not defer any package.")

(defconst ematrix-not-lazy-p
  (or ematrix-always-demand-p (daemonp) (and (getenv "EMATRIX_NOT_LAZY") t))
  "Load lazy packages (ematrix-lazy-hook) immediately.")

(defconst ematrix-load-all-modules-p
  (and (getenv "EMATRIX_LOAD_ALL_MODULES") t)
  "Force loading all Ematrix modules.")

(defconst ematrix-no-proxies-p
  (and (getenv "EMATRIX_NO_PROXIES") t)
  "Disable proxies in `ematrix-proxies'.")

(defcustom ematrix-msg-level
  (let ((level (string-to-number (or (getenv "EMATRIX_MSG_LEVEL") ""))))
    (cond (ematrix-verbose-p 4)
          ((> level 0) level)
          (t 1)))
  "Level of printed messages.
1 - `+error!'
2 - `+info!'
3 - `+log!'
4 - `+debug!'"
  :group 'ematrix-core
  :type '(choice
          (const :tag "Error" 1)
          (const :tag "Info" 2)
          (const :tag "Log" 3)
          (const :tag "Debug" 4)))

;; Derive the root directory from this file path
(defconst ematrix-root-dir (abbreviate-file-name (file-name-directory (directory-file-name (file-name-directory (file-truename load-file-name))))))
(defconst ematrix-core-dir (concat ematrix-root-dir "core/"))
(defconst ematrix-assets-dir (concat ematrix-root-dir "assets/"))
(defconst ematrix-elisp-dir (concat ematrix-root-dir "elisp/"))
(defconst ematrix-modules-dir (concat ematrix-root-dir "modules/"))
(defconst ematrix-obsolete-modules-dir (concat ematrix-modules-dir "obsolete/"))
(defconst ematrix-extras-dir (concat ematrix-modules-dir "extras/"))
(defconst ematrix-local-dir (concat ematrix-root-dir "local/"))
(defconst ematrix-cache-dir (concat ematrix-local-dir "cache/"))
(defconst ematrix-loaddefs-file (concat ematrix-core-dir "me-loaddefs.el"))
(defconst ematrix-extra-packages-dir (concat ematrix-local-dir "extra-packages/"))
;; ponytail: 配置就放仓库里,不读 env、不读 ~/.ematrix.d —— 自用,不分发。
(defconst ematrix-config-dir (concat ematrix-root-dir "user-config/")
  "Ematrix user customization directory (lives inside the repo).")
(defconst ematrix-blog-dir (concat ematrix-root-dir "blog/"))

(defconst ematrix-started-with-extra-args-p (and (cdr command-line-args) t) "Has Emacs been started with extras arguments? like a file name or so.")
(defconst os/linux (eq system-type 'gnu/linux) "Non-nil on GNU/Linux systems.")
(defconst os/bsd (and (memq system-type '(berkeley-unix gnu/kfreebsd)) t) "Non-nil on BSD systems.")
(defconst os/win (and (memq system-type '(cygwin windows-nt ms-dos)) t) "Non-nil on Windows systems.")
(defconst os/mac (eq system-type 'darwin) "Non-nil on MacOS systems.")

(defconst sys/arch (intern (car (split-string system-configuration "-")))
  "The system's architecture read from `system-configuration'.
It return a symbol like `x86_64', `aarch64', `armhf', ...")

(defconst emacs/features
  (mapcar #'intern
          (mapcar (apply-partially #'string-replace "_" "-")
                  (mapcar #'downcase (split-string system-configuration-features))))
  "List of symbols representing Emacs' enabled features.
Compiled from the `system-configuration-features'.")

(defcustom ematrix-leader-key "SPC"
  "Ematrix leader key."
  :group 'ematrix-keybinding
  :type 'string)

(defcustom ematrix-localleader-key "SPC m"
  "Ematrix local leader (a.k.a. mode specific) key sequence."
  :group 'ematrix-keybinding
  :type 'string)

(defcustom ematrix-global-leader-prefix "C-SPC"
  "Ematrix general leader key."
  :group 'ematrix-keybinding
  :type 'string)

(defcustom ematrix-global-mode-prefix "C-SPC m"
  "Ematrix general local leader (a.k.a. mode specific) key sequence."
  :group 'ematrix-keybinding
  :type 'string)

(defcustom ematrix-theme 'doom-one
  "The theme of Ematrix."
  :group 'ematrix-ui
  :type 'symbol)

(defcustom ematrix-disabled-packages nil
  "List of packages to be disabled when loading Ematrix modules.
This can be useful if you want to enable a module but you don't want a package
of being enabled."
  :group 'ematrix-core
  :type '(list symbol))

(defvar ematrix-configured-packages nil
  "List of packages installed and configured by Ematrix during startup.")

(defcustom ematrix-after-loading-modules-hook nil
  "This hook will be run after loading Ematrix modules.
It is used internally to remove the `+use-package--check-if-disabled:around-a'
advice we set on `use-package' in `me-bootstrap'."
  :group 'ematrix-core
  :type 'hook)

(defcustom ematrix-after-setup-fonts-hook nil
  "Runs after setting Ematrix fonts, runs at the end of `+setup-fonts'."
  :group 'ematrix-ui
  :type 'hook)

(defcustom ematrix-after-load-theme-hook nil
  "Runs after loading Ematrix theme, runs at the end of `+load-theme'."
  :group 'ematrix-ui
  :type 'hook)

(defcustom ematrix-after-startup-hook nil
  "This hook will be run after loading Emacs.

Ematrix hooks will be run in this order:
1. `ematrix-after-startup-hook'
2. `ematrix-lazy-hook'"
  :group 'ematrix-core
  :type 'hook)

(defcustom ematrix-lazy-hook nil
  "This hook will be run after loading Emacs, with laziness.

Ematrix hooks will be run in this order:
1. `ematrix-after-startup-hook'
2. `ematrix-lazy-hook'"
  :group 'ematrix-core
  :type 'hook)

(defcustom ematrix-proxies nil
  "Ematrix proxies.

Example, set it to:

\\='((\"no\" . \"localhost,127.0.0.1,.local,.mylocaltld\")
  (\"ftp\" . \"http://myproxy.local:8080/\")
  (\"http\" . \"http://myproxy.local:8080/\")
  (\"https\" . \"http://myproxy.local:8080/\")))

These will set the environment variables \"no_proxy\", \"ftp_proxy\", ...

When set in \"early-config.el\" or in \"init-tweaks.el\", Ematrix will enable
it automatically."
  :group 'ematrix-core
  :type '(repeat (cons string string)))

(defvaralias 'ematrix-build-functions-hook 'ematrix-build-functions)
(defvar ematrix-build-functions nil
  "Special hook for build functions that are run after completing package updates.")

(defcustom +env-file (concat ematrix-local-dir "system-env.el")
  "The file in which the environment variables will be saved."
  :group 'ematrix-core
  :type 'file)

;; Inspired by Doom Emacs
(defcustom +env-deny-vars
  '(;; Unix/shell state that shouldn't be persisted
    "^HOME$" "^\\(OLD\\)?PWD$" "^SHLVL$" "^PS1$" "^R?PROMPT$" "^TERM\\(CAP\\)?$"
    "^USER$" "^GIT_CONFIG" "^INSIDE_EMACS$" "^SESSION_MANAGER$" "^_$"
    "^JOURNAL_STREAM$" "^INVOCATION_ID$" "^MANAGERPID$" "^SYSTEMD_EXEC_PID$"
    "^DESKTOP_STARTUP_ID$" "^LS_?COLORS$" "^$"
    ;; Python virtual environment
    "^VIRTUAL_ENV$"
    ;; KDE session
    "^KDE_\\(FULL_SESSION\\|APPLICATIONS_.*\\|SESSION_\\(UID\\|VERSION\\)\\)$"
    ;; X server, Wayland, or services' env that shouldn't be persisted
    "^DISPLAY$" "^WAYLAND_DISPLAY" "^DBUS_SESSION_BUS_ADDRESS$" "^XAUTHORITY$"
    "^WINDOWID$" "^GIO_LAUNCHED_DESKTOP_FILE_PID$"
    ;; Windows+WSL envvars that shouldn't be persisted
    "^WSL_INTEROP$"
    ;; XDG variables that are best not persisted.
    "^XDG_CURRENT_DESKTOP$" "^XDG_RUNTIME_DIR$"
    "^XDG_\\(VTNR\\|SEAT\\|SESSION_\\(TYPE\\|CLASS\\|ID\\|PATH\\|DESKTOP\\)\\)"
    ;; Socket envvars, like I3SOCK, GREETD_SOCK, SEATD_SOCK, SWAYSOCK, etc.
    "SOCK$"
    ;; SSH and GPG variables that could quickly become stale if persisted.
    "^SSH_\\(AUTH_SOCK\\|AGENT_PID\\)$" "^\\(SSH\\|GPG\\)_TTY$" "^GPG_AGENT_INFO$"
    ;; Tmux session
    "^TMUX$"
    ;; Ematrix envvars
    "^EMATRIX_")
  "Environment variables to omit.
Each string is a regexp, matched against variable names to omit from
`+env-file' when saving evnironment variables in `+env-save'."
  :group 'ematrix-core
  :type '(repeat regexp))

;; Functions
(defun +load-user-configs (&rest configs)
  "Load user configurations CONFIGS."
  (dolist (conf configs)
    (unless (memq conf ematrix-ignore-user-config)
      (let ((conf-path (format "%s%s.el" ematrix-config-dir conf)))
        (when (file-exists-p conf-path) (+load conf-path))))))

(defun +load (&rest filename-parts)
  "Load a file, the FILENAME-PARTS are concatenated to form the file name."
  (let ((filename (file-truename (apply #'file-name-concat filename-parts))))
    (if (file-exists-p filename)
        (with-demoted-errors "[Ematrix:LoadError] %s"
          (load filename nil (not ematrix-verbose-p)))
      (message "[Ematrix:Error] Cannot load \"%s\", the file doesn't exists." filename))))


(provide 'me-vars)

;;; me-vars.el ends here
