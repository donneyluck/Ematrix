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

;; ── JSON-RPC: offset conversion ────────────────────────────────

(defun +claude-ide--point->pos (pos)
  "Convert Emacs position POS to a (LINE . CHARACTER) cons, both 0-based."
  (save-excursion
    (goto-char pos)
    (cons (1- (line-number-at-pos pos)) (current-column))))

;; ── JSON-RPC: response builders ────────────────────────────────

(defun +claude-ide--make-response (id result)
  "Build a JSON-RPC success response string for ID with RESULT alist."
  (json-encode `((jsonrpc . "2.0") (id . ,id) (result . ,result))))

(defun +claude-ide--make-error (id code message)
  "Build a JSON-RPC error response string."
  (json-encode
   `((jsonrpc . "2.0") (id . ,id)
     (error . ((code . ,code) (message . ,message))))))

;; ── Tool schemas ───────────────────────────────────────────────

(defun +claude-ide--tools ()
  "Return the list of tool schema alists."
  (let ((names-descs
         '(("getCurrentSelection" . "Return the active editor selection, or empty if none.")
           ("getLatestSelection" . "Return the most recently recorded selection.")
           ("getOpenEditors" . "Return open file-backed buffers.")
           ("getWorkspaceFolders" . "Return workspace root paths.")
           ("getDiagnostics" . "Return flymake diagnostics for the active buffer."))))
    (mapcar (lambda (nd)
              `((name . ,(car nd))
                (description . ,(cdr nd))
                (inputSchema . ((type . "object") (properties . nil) (required . nil)))))
            names-descs)))

;; ── Shared state ───────────────────────────────────────────────

(defvar +claude-ide--latest-selection nil
  "Last pushed selection alist, for pull.")

;; ── Tool implementations ───────────────────────────────────────

(defun +claude-ide--current-selection ()
  "Return an alist describing the current region (or empty)."
  (if (region-active-p)
      (let* ((beg (region-beginning))
             (end (region-end))
             (buf (current-buffer))
             (file (buffer-file-name buf)))
        `((success . t)
          (text . ,(buffer-substring-no-properties beg end))
          (filePath . ,(and file (expand-file-name file)))
          (selection . ((start . ,(append (+claude-ide--point->pos beg) nil))
                        (end . ,(append (+claude-ide--point->pos end) nil))
                        (isEmpty . :json-false)))))
    '((success . :json-false))))

(defun +claude-ide--open-editors ()
  "Return open file-backed buffers as a tabs alist."
  (let (tabs)
    (dolist (buf (buffer-list))
      (let ((file (buffer-file-name buf)))
        (when file
          (push `((uri . ,(concat "file://" (expand-file-name file)))
                  (isActive . ,(eq buf (current-buffer)))
                  (label . ,(file-name-nondirectory file))
                  (languageId . ,(symbol-name (buffer-local-value 'major-mode buf)))
                  (isDirty . ,(buffer-modified-p buf)))
                tabs))))
    `((tabs . ,(vconcat tabs)))))

(defun +claude-ide--workspace-folders-result ()
  "Return workspace folders result alist."
  (let ((root (car (+claude-ide--workspace-folders))))
    `((success . t)
      (rootPath . ,root)
      (folders . [((name . ,(file-name-nondirectory (directory-file-name root)))
                   (uri . ,(concat "file://" root))
                   (path . ,root))]))))

(defun +claude-ide--diagnostics ()
  "Return flymake diagnostics for the current buffer as an alist."
  (require 'flymake nil t)
  (let ((file (buffer-file-name))
        (diags (condition-case nil (flymake-diagnostics) (error nil))))
    `[(,(if file (concat "file://" (expand-file-name file)) "")
       .
       ,(vconcat
         (mapcar (lambda (d)
                   `((message . ,(flymake--diag-text d))
                     (severity . ,(symbol-name (or (flymake--diag-type d) 'warning)))
                     (range . ((start . ,(append (+claude-ide--point->pos
                                                  (flymake--diag-beg d)) nil))
                               (end . ,(append (+claude-ide--point->pos
                                                (flymake--diag-end d)) nil))))))
                 (or diags nil))))]))

;; ── JSON-RPC dispatch ──────────────────────────────────────────

(defun +claude-ide--handle-message (json-str)
  "Dispatch a JSON-RPC message JSON-STR. Return a response JSON string or nil."
  (let* ((msg (condition-case nil (json-read-from-string json-str)
                (error nil))))
    (when msg
      (let ((method (alist-get 'method msg))
            (id (alist-get 'id msg)))
        (cond
         ((equal method "initialize")
          (+claude-ide--make-response
           id `((protocolVersion . "2025-03-26")
                (capabilities . ((tools . nil)))
                (serverInfo . ((name . "Emacs") (version . "0.1"))))))
         ((equal method "initialized") nil) ; notification, no response
         ((equal method "tools/list")
          (+claude-ide--make-response
           id `((tools . ,(+claude-ide--tools)))))
         ((equal method "tools/call")
          (let ((name (alist-get 'name (alist-get 'params msg))))
            (cond
             ((equal name "getCurrentSelection")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode (+claude-ide--current-selection))))]))))
             ((equal name "getLatestSelection")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode
                                           (or +claude-ide--latest-selection
                                               '((success . :json-false))))))]))))
             ((equal name "getOpenEditors")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode (+claude-ide--open-editors))))]))))
             ((equal name "getWorkspaceFolders")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode (+claude-ide--workspace-folders-result))))]))))
             ((equal name "getDiagnostics")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode (+claude-ide--diagnostics))))]))))
             (t (when id (+claude-ide--make-error id -32601 (format "Unknown tool: %s" name)))))))
         (t (when id (+claude-ide--make-error id -32601 (format "Unknown method: %s" method)))))))))

(provide 'me-claude-ide)
;;; me-claude-ide.el ends here
