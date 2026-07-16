;;; me-claude-ide.el --- Claude Code /ide bridge for Emacs -*- lexical-binding: t; -*-

;; Author: donneyluck@gmail.com

;;; Commentary:
;; Impersonates a VS Code-style IDE so the Claude Code CLI `/ide` command
;; auto-discovers this Emacs session and auto-injects the current selection.

;;; Code:

(require 'cl-lib)
(require 'json)

(defgroup claude-ide nil
  "Claude Code /ide bridge."
  :group 'tools)

(defcustom claude-ide-bridge-enable t
  "Non-nil enables the bridge on `me-ai' load."
  :type 'boolean)

(defvar +claude-ide--port nil
  "Port the WS server listens on.")

(defvar +claude-ide--auth-token nil
  "Auth token written into the lock file (not verified on connect).")

(defvar +claude-ide--lock-dir nil
  "Directory holding the lock file. Bound per session.")

(defun +claude-ide--config-dir ()
  "Return the Claude config directory."
  (let ((env (getenv "CLAUDE_CONFIG_DIR")))
    (if (and env (not (string-empty-p env)))
        (expand-file-name env)
      (expand-file-name "~/.claude"))))

(defun +claude-ide--lock-path ()
  "Return the lock file path for the current port."
  (and +claude-ide--lock-dir +claude-ide--port
       (expand-file-name (format "%d.lock" +claude-ide--port)
                         +claude-ide--lock-dir)))

(defun +claude-ide--gen-token ()
  "Return a 32-char hex token."
  (let ((bytes (lambda () (random 256))))
    ;; random is seeded by Emacs at startup; fine for a local nonce.
    (mapconcat (lambda (_)
                 (let ((b (funcall bytes)))
                   (format "%02x" b)))
               (make-list 16 0) "")))

(defun +claude-ide--pick-port ()
  "Return a free port in 10000-65535."
  ;; Open a transient listening socket to grab a free ephemeral port, then close.
  (let (server port)
    (unwind-protect
        (progn
          (setq server (make-network-process :name "claude-ide-portprobe"
                                            :server t
                                            :host "127.0.0.1"
                                            :service t
                                            :family 'ipv4))
          (setq port (cadr (process-contact server :local)))
          (when (or (not port) (< port 10000))
            (setq port (+ 10000 (random 55536))))
          port)
      (when server (delete-process server)))))

(defun +claude-ide--workspace-folders ()
  "Return a list of workspace root absolute paths."
  (let ((root (condition-case nil
                  (vc-root-dir)
                (error nil))))
    (list (or (and root (expand-file-name root))
              (expand-file-name default-directory)))))

(defun +claude-ide--write-lock-file ()
  "Write the lock file for the current port/token."
  (let ((path (+claude-ide--lock-path))
        (data `((pid . ,(emacs-pid))
                (workspaceFolders . ,(+claude-ide--workspace-folders))
                (ideName . "Emacs")
                (transport . "ws")
                (authToken . ,+claude-ide--auth-token))))
    (when path
      (make-directory +claude-ide--lock-dir t)
      (with-temp-file path
        (insert (json-encode data)))
      (set-file-modes path #o600))))

(defun +claude-ide--delete-lock-file ()
  "Remove the lock file for the current port, if present."
  (let ((path (+claude-ide--lock-path)))
    (when (and path (file-exists-p path))
      (delete-file path))))

(provide 'me-claude-ide)
;;; me-claude-ide.el ends here
