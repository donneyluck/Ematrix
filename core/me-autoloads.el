;;; me-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:



;;; Generated autoloads from ../elisp/binary.el

(autoload '+binary-objdump-buffer-p "../elisp/binary" "\
Can the BUFFER be viewed as a disassembled code with objdump.

(fn &optional BUFFER)")
(autoload '+binary-hexl-buffer-p "../elisp/binary")
(autoload 'objdump-disassemble-mode "../elisp/binary" "\
Major mode for viewing executable files disassembled using objdump.

(fn)" t)
(autoload '+binary-hexl-mode-maybe "../elisp/binary" "\
If `hexl-mode' is not already active, and the current buffer
is binary, activate `hexl-mode'." t)
(autoload '+binary-setup-modes "../elisp/binary")
(register-definition-prefixes "../elisp/binary" '("+binary-"))


;;; Generated autoloads from ../elisp/ecryptfs.el

(autoload 'ecryptfs-mount-private "../elisp/ecryptfs" "\
Mount eCryptfs' private directory." t)
(autoload 'ecryptfs-umount-private "../elisp/ecryptfs" "\
Unmount eCryptfs' private directory." t)
(register-definition-prefixes "../elisp/ecryptfs" '("ecryptfs-"))


;;; Generated autoloads from me-core.el

(autoload '+log! "me-core" "\
Log MSG and VARS using `message' when `minemacs-verbose' is non-nil.

(fn MSG &rest VARS)" nil t)
(autoload '+info! "me-core" "\
Log info MSG and VARS using `message'.

(fn MSG &rest VARS)" nil t)
(autoload '+error! "me-core" "\
Log error MSG and VARS using `message'.

(fn MSG &rest VARS)" nil t)
(autoload '+reset-sym "me-core" "\
Reset SYM to its standard value.

(fn SYM)")
(autoload '+shutup! "me-core" "\
Suppress new messages temporarily in the echo area and the `*Messages*' buffer while BODY is evaluated.

(fn &rest BODY)" nil t)
(autoload '+reset-var! "me-core" "\
Reset VAR to its standard value.

(fn VAR)" nil t)
(autoload '+cmdfy! "me-core" "\
Convert BODY to an interactive command.

(fn &rest BODY)" nil t)
(autoload '+set-fonts "me-core" nil t)
(autoload '+plist-keys "me-core" "\
Return the keys of PLIST.

(fn PLIST)")
(autoload '+plist-push! "me-core" "\
Push KEY-VALS to PLIST.

(fn PLIST &rest KEY-VALS)" nil t)
(autoload '+serialize-sym "me-core" "\
Serialize SYM to DIR.
If FILENAME-FORMAT is non-nil, use it to format the file name (ex. \"file-%s.el\").
Return the written file name, or nil if SYM is not bound.

(fn SYM DIR &optional FILENAME-FORMAT)")
(autoload '+deserialize-sym "me-core" "\
Deserialize SYM from DIR, if MUTATE is non-nil, assign the object to SYM.
If FILENAME-FORMAT is non-nil, use it to format the file name (ex. \"file-%s.el\").
Return the deserialized object, or nil if the SYM.el file dont exist.

(fn SYM DIR &optional MUTATE FILENAME-FORMAT)")
(autoload '+add-dependencies "me-core" "\


(fn &rest DEPS)")
(autoload '+check-dependencies "me-core" "\
Check for MinEmacs dependencies." t)
(autoload '+eval-when-idle "me-core" "\
Queue FNS to be processed when Emacs becomes idle.

(fn &rest FNS)")
(autoload '+eval-when-idle! "me-core" "\
Evaluate BODY when Emacs becomes idle.

(fn &rest BODY)" nil t)
(autoload '+compile-functs "me-core" "\
Queue FNS to be byte/natively-compiled after a brief delay.

(fn &rest FNS)")
(autoload '+env-save "me-core" nil t)
(autoload '+env-load "me-core" nil t)
(autoload 'minemacs-update "me-core" nil t)
(register-definition-prefixes "me-core" '("+eval-when-idle--task-num"))


;;; Generated autoloads from me-core-ui.el

(register-definition-prefixes "me-core-ui" '("+theme-tweaks"))


;;; Generated autoloads from ../modules/me-daemon.el

(register-definition-prefixes "../modules/me-daemon" '("+daemon--setup-background-apps"))


;;; Generated autoloads from me-defaults.el

(register-definition-prefixes "me-defaults" '("yes-or-no-p"))


;;; Generated autoloads from ../modules/extras/me-elisp-extras.el

(register-definition-prefixes "../modules/extras/me-elisp-extras" '("+elisp-" "+emacs-lisp--"))


;;; Generated autoloads from me-emacs.el

(autoload '+dir-locals-reload-for-this-buffer "me-emacs" "\
reload dir locals for the current buffer" t)
(autoload '+dir-locals-reload-for-all-buffers-in-this-directory "me-emacs" "\
For every buffer with the same `default-directory` as the
current buffer's, reload dir-locals." t)
(autoload '+dir-locals-enable-autoreload "me-emacs")
(autoload '+dir-locals-open-or-create "me-emacs" "\
Open or create the dir-locals.el for the current project." t)


;;; Generated autoloads from ../modules/me-email.el

(register-definition-prefixes "../modules/me-email" '("MU4E-"))


;;; Generated autoloads from me-io.el

(autoload '+file-mime-type "me-io" "\
Get MIME type for FILE based on magic codes provided by the 'file' command.
Return a symbol of the MIME type, ex: `text/x-lisp', `text/plain',
`application/x-object', `application/octet-stream', etc.

(fn FILE)")
(autoload '+file-name-incremental "me-io" "\
Return an unique file name for FILENAME.
If \"file.ext\" exists, returns \"file-0.ext\".

(fn FILENAME)")
(autoload '+file-read-to-string "me-io" "\
Return a string with the contents of FILENAME.

(fn FILENAME)")
(autoload '+delete-this-file "me-io" "\
Delete PATH.

If PATH is not specified, default to the current buffer's file.

If FORCE-P, delete without confirmation.

(fn &optional PATH FORCE-P)" t)
(autoload '+move-this-file "me-io" "\
Move current buffer's file to NEW-PATH.

If FORCE-P, overwrite the destination file if it exists, without confirmation.

(fn NEW-PATH &optional FORCE-P)" t)
(autoload '+sudo-find-file "me-io" "\
Open FILE as root.

(fn FILE)" t)
(autoload '+sudo-this-file "me-io" "\
Open the current file as root." t)
(autoload '+sudo-save-buffer "me-io" "\
Save this file as root." t)
(autoload '+yank-this-file-name "me-io" "\
Yank the file name of this buffer." t)
(autoload '+clean-file-name "me-io" "\
Clean file name.

(fn FILENAME &optional CONV-DOWNCASE)")
(register-definition-prefixes "me-io" '("+sudo-file-path"))


;;; Generated autoloads from ../modules/me-math.el

(register-definition-prefixes "../modules/me-math" '("MAXIMA-P"))


;;; Generated autoloads from ../modules/me-media.el

(register-definition-prefixes "../modules/me-media" '("MPV-P"))


;;; Generated autoloads from me-messages.el

(autoload '+messages--auto-tail-a "me-messages" "\
Make *Messages* buffer auto-scroll to the end after each message.

(fn &rest ARG)")
(autoload '+messages-auto-tail-toggle "me-messages" "\
Auto tail the '*Messages*' buffer." t)


;;; Generated autoloads from ../modules/extras/me-mu4e-extras.el

(autoload '+mu4e-extras-setup "../modules/extras/me-mu4e-extras")
(register-definition-prefixes "../modules/extras/me-mu4e-extras" '("+mu4e-" "+org-msg-make-signature"))


;;; Generated autoloads from ../modules/extras/me-mu4e-gmail.el

(register-definition-prefixes "../modules/extras/me-mu4e-gmail" '("+mu4e-"))


;;; Generated autoloads from ../modules/extras/me-mu4e-ui.el

(register-definition-prefixes "../modules/extras/me-mu4e-ui" '("+mu4e-"))


;;; Generated autoloads from ../modules/me-natural-langs.el

(register-definition-prefixes "../modules/me-natural-langs" '("ASPELL-P"))


;;; Generated autoloads from ../modules/extras/me-org-export-async-init.el

(register-definition-prefixes "../modules/extras/me-org-export-async-init" '("minemacs-"))


;;; Generated autoloads from ../modules/extras/me-org-extras.el

(register-definition-prefixes "../modules/extras/me-org-extras" '("+org-"))


;;; Generated autoloads from me-primitives.el

(autoload '+bool "me-primitives" "\


(fn VAL)")
(autoload '+foldr "me-primitives" "\


(fn FUN ACC SEQ)")
(autoload '+foldl "me-primitives" "\


(fn FUN ACC SEQ)")
(autoload '+all "me-primitives" "\


(fn SEQ)")
(autoload '+some "me-primitives" "\


(fn SEQ)")
(autoload '+zip "me-primitives" "\


(fn &rest SEQS)")
(autoload '+str-replace "me-primitives" "\
Replaces OLD with NEW in S.

(fn OLD NEW S)")
(autoload '+str-replace-all "me-primitives" "\
REPLACEMENTS is a list of cons-cells. Each `car` is replaced with `cdr` in S.

(fn REPLACEMENTS S)")


;;; Generated autoloads from ../modules/extras/me-spell-fu.el

(autoload '+spell-fu-correct "../modules/extras/me-spell-fu" "\
Correct spelling of word at point." t)
(register-definition-prefixes "../modules/extras/me-spell-fu" '("+spell-fu--correct"))


;;; Generated autoloads from me-splash.el

(register-definition-prefixes "me-splash" '("minemacs-splash-"))


;;; Generated autoloads from me-systemd.el

(autoload '+systemd-running-p "me-systemd" "\
Check if the systemd SERVICE is running.

(fn SERVICE)")
(autoload '+systemd-command "me-systemd" "\
Call systemd with COMMAND and SERVICE.

(fn SERVICE COMMAND &optional PRE-FN POST-FN)" t)
(autoload '+systemd-start "me-systemd" "\
Start systemd SERVICE.

(fn SERVICE &optional PRE-FN POST-FN)" t)
(autoload '+systemd-stop "me-systemd" "\
Stops the systemd SERVICE.

(fn SERVICE &optional PRE-FN POST-FN)" t)


;;; Generated autoloads from me-vars.el

(register-definition-prefixes "me-vars" '("+env-save-vars" "minemacs-" "os/"))


;;; Generated autoloads from ../elisp/netextender.el

(autoload 'netextender-start "../elisp/netextender" "\
Launch a NetExtender VPN session." t)
(autoload 'netextender-toggle "../elisp/netextender" "\
Toggle connection to NetExtender." t)
(register-definition-prefixes "../elisp/netextender" '("netextender-"))


;;; Generated autoloads from ../elisp/valgrind.el

(autoload 'valgrind "../elisp/valgrind" "\
Run valgrind.
Runs COMMAND, a shell command, in a separate process asynchronously
with output going to the buffer `*valgrind*'.
You can then use the command \\[next-error] to find the next error message
and move to the source code that caused it.

(fn COMMAND)" t)
(register-definition-prefixes "../elisp/valgrind" '("valgrind-"))

;;; End of scraped data

(provide 'me-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; me-autoloads.el ends here
